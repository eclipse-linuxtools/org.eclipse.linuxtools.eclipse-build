/*********************************************************************
 * Copyright (c) 2018, 2019 Red Hat, Inc. and others.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 **********************************************************************/
package java.lang;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayInputStream;
import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

import jdk.internal.misc.JavaIOFileDescriptorAccess;
import jdk.internal.misc.SharedSecrets;

/**
 * A java.lang.Process implementation to break out of the Flatpak sandbox and
 * start processes in the host environment. It does this by communicating with
 * the "Development" interface of the org.freedesktop.Flatpak DBus API.
 */
final class FlatpakProcessImpl extends Process {

    static {
        System.loadLibrary("flatpakdevshim");
    }

    private static final JavaIOFileDescriptorAccess fdAccess = SharedSecrets.getJavaIOFileDescriptorAccess();

    private final int pid;
    private final OutputStream stdin;
    private final InputStream stdout;
    private final InputStream stderr;
    private final ProcessHandleImpl processHandle;

    private int exitcode;
    private boolean hasExited;

    private FlatpakProcessImpl(byte[] argv, int argc, byte[] envv, int envc, int[] fds, boolean redirectErrStream)
            throws IOException {
        pid = forkAndExecHostCommand(argv, argc, envv, envc, fds, redirectErrStream);
        processHandle = ProcessHandleImpl.getInternal(pid);

        // Initialise streams for the process's standard file descriptors
        if (fds[0] == -1) {
            stdin = ProcessBuilder.NullOutputStream.INSTANCE;
        } else {
            stdin = new ProcessPipeOutputStream(fds[0]);
        }
        if (fds[1] == -1) {
            stdout = ProcessBuilder.NullInputStream.INSTANCE;
        } else {
            stdout = new ProcessPipeInputStream(fds[1]);
        }
        if (fds[2] == -1) {
            stderr = ProcessBuilder.NullInputStream.INSTANCE;
        } else {
            stderr = new ProcessPipeInputStream(fds[2]);
        }
        ProcessHandleImpl.completion(pid, true).handle((exitcode, throwable) -> {
            synchronized (this) {
                if (exitcode == null) {
                    this.exitcode = -1;
                } else {
                    this.exitcode = exitcode.intValue();
                }
                this.hasExited = true;
                this.notifyAll();
            }

            if (stdout instanceof ProcessPipeInputStream) {
                ((ProcessPipeInputStream) stdout).processExited();
            }
            if (stderr instanceof ProcessPipeInputStream) {
                ((ProcessPipeInputStream) stderr).processExited();
            }
            if (stdin instanceof ProcessPipeOutputStream) {
                ((ProcessPipeOutputStream) stdin).processExited();
            }
            return null;
        });
    }

    private native int forkAndExecHostCommand(byte[] argv, int argc, byte[] envv, int envc, int[] fds,
            boolean redirectErrStream) throws IOException;

    /**
     * For use only by {@link ProcessBuilder#start()}.
     */
    @SuppressWarnings("resource")
    static Process start(String[] cmdarray, Map<String, String> environment, String dir,
            ProcessBuilder.Redirect[] redirects, boolean redirectErrStream) throws IOException {

        // Try to honour ProcessBuilder contract by using user.dir if none is specified
        String workdir = System.getProperty("user.dir");
        if (dir != null && !dir.isEmpty()) {
            workdir = dir;
        }

        // Generate argument block, which must be prefixed with the name of the helper
        // executable that will launch the process on the process host and working
        // directory that should be used on the sandbox host
        List<String> argarray = new ArrayList<>();
        argarray.add("flatpak-spawn");
        argarray.add("--host");
        // TODO Add working dir support to flatpak-spawn
        // argarray.add(workdir);
        argarray.addAll(Arrays.asList(cmdarray));
        byte[] argv = toCStrings(argarray.toArray(new String[0]));

        // Generate the environment block, to which we must add the $DISPLAY variable
        // and the $DBUS_SESSION_BUS_ADDRESS variable if it exists because it must be
        // defined in the child process environment in order for auto-launching to work
        List<String> envarray = new ArrayList<>();
        envarray.add("DISPLAY=" + System.getenv("DISPLAY"));
        if (System.getenv("DBUS_SESSION_BUS_ADDRESS") != null) {
            envarray.add("DBUS_SESSION_BUS_ADDRESS=" + System.getenv("DBUS_SESSION_BUS_ADDRESS"));
        }
        if (environment != null) {
            for (Map.Entry<String, String> entry : environment.entrySet()) {
                envarray.add(entry.getKey() + "=" + entry.getValue());
            }
        }
        byte[] envv = toCStrings(envarray.toArray(new String[0]));

        FileInputStream f0 = null;
        FileOutputStream f1 = null;
        FileOutputStream f2 = null;

        try {
            // Setup standard file descriptors for process
            int[] fds = { -1, -1, -1 };
            if (redirects != null) {
                // stdin
                if (redirects[0] == ProcessBuilder.Redirect.PIPE) {
                    fds[0] = -1;
                } else if (redirects[0] == ProcessBuilder.Redirect.INHERIT) {
                    fds[0] = 0;
                } else {
                    f0 = new FileInputStream(redirects[0].file());
                    fds[0] = fdAccess.get(f0.getFD());
                }

                // stdout
                if (redirects[1] == ProcessBuilder.Redirect.PIPE) {
                    fds[1] = -1;
                } else if (redirects[1] == ProcessBuilder.Redirect.INHERIT) {
                    fds[1] = 1;
                } else {
                    f1 = new FileOutputStream(redirects[1].file(), redirects[1].append());
                    fds[1] = fdAccess.get(f1.getFD());
                }

                // stderr
                if (redirects[2] == ProcessBuilder.Redirect.PIPE) {
                    fds[2] = -1;
                } else if (redirects[2] == ProcessBuilder.Redirect.INHERIT) {
                    fds[2] = 2;
                } else {
                    f2 = new FileOutputStream(redirects[2].file(), redirects[2].append());
                    fds[2] = fdAccess.get(f2.getFD());
                }
            }

            return new FlatpakProcessImpl(argv, argarray.size(), envv, envarray.size(), fds, redirectErrStream);
        } finally {
            if (f0 != null) {
                f0.close();
            }
            if (f1 != null) {
                f1.close();
            }
            if (f2 != null) {
                f2.close();
            }
        }
    }

    @Override
    public CompletableFuture<Process> onExit() {
        return ProcessHandleImpl.completion(pid, false).handleAsync((unusedExitStatus, unusedThrowable) -> {
            boolean interrupted = false;
            while (true) {
                // Ensure that the concurrent task setting the exit status has completed
                try {
                    waitFor();
                    break;
                } catch (InterruptedException ie) {
                    interrupted = true;
                }
            }
            if (interrupted) {
                Thread.currentThread().interrupt();
            }
            return this;
        });
    }

    @Override
    public ProcessHandle toHandle() {
        return processHandle;
    }

    @Override
    public boolean supportsNormalTermination() {
        return true;
    }

    @Override
    public void destroy() {
        destroy(false);
    }

    @Override
    public Process destroyForcibly() {
        destroy(true);
        return this;
    }

    private void destroy(boolean force) {
        synchronized (this) {
            if (!hasExited)
                processHandle.destroyProcess(force);
        }
        try {
            stdin.close();
        } catch (IOException ignored) {
        }
        try {
            stdout.close();
        } catch (IOException ignored) {
        }
        try {
            stderr.close();
        } catch (IOException ignored) {
        }
    }

    @Override
    public synchronized int waitFor() throws InterruptedException {
        while (!hasExited) {
            wait();
        }
        return exitcode;
    }

    @Override
    public synchronized int exitValue() {
        if (!hasExited) {
            throw new IllegalThreadStateException("process hasn't exited");
        }
        return exitcode;
    }

    @Override
    public InputStream getErrorStream() {
        return stderr;
    }

    @Override
    public InputStream getInputStream() {
        return stdout;
    }

    @Override
    public OutputStream getOutputStream() {
        return stdin;
    }

    /**
     * Return a string consisting of the native process ID and exit value of the
     * process.
     *
     * @return a string representation of the object.
     */
    @Override
    public String toString() {
        return new StringBuilder("Process[pid=").append(pid).append(", exitValue=")
                .append(hasExited ? exitcode : "\"not exited\"").append("]").toString();
    }

    /**
     * Convert java strings into a single contiguous block of C-style null
     * terminated byte arrays. This makes arrays of arrays easier to deal with on
     * the native side.
     */
    private static byte[] toCStrings(String... values) {
        int size = 0;
        for (String value : values) {
            size += value.getBytes().length + 1;
        }
        byte[] result = new byte[size];
        int pos = 0;
        for (String value : values) {
            byte[] bytes = value.getBytes();
            System.arraycopy(bytes, 0, result, pos, bytes.length);
            pos += bytes.length;
            result[pos++] = (byte) 0;
        }
        return result;
    }

    /**
     * Creates a new descriptor for the given ID.
     */
    private static FileDescriptor newFileDescriptor(int fd) {
        FileDescriptor descriptor = new FileDescriptor();
        fdAccess.set(descriptor, fd);
        return descriptor;
    }

    /**
     * A buffered input stream for a subprocess pipe file descriptor that allows the
     * underlying file descriptor to be reclaimed when the process exits, via the
     * processExited hook.
     *
     * This is tricky because we do not want the user-level InputStream to be closed
     * until the user invokes close(), and we need to continue to be able to read
     * any buffered data lingering in the OS pipe buffer.
     * 
     * This class is taken more or less as-is from the JDK 9 implementation.
     */
    private static class ProcessPipeInputStream extends BufferedInputStream {
        private final Object closeLock = new Object();

        ProcessPipeInputStream(int fd) {
            super(new PipeInputStream(newFileDescriptor(fd)));
        }

        private static byte[] drainInputStream(InputStream in) throws IOException {
            int n = 0;
            int j;
            byte[] a = null;
            while ((j = in.available()) > 0) {
                a = (a == null) ? new byte[j] : Arrays.copyOf(a, n + j);
                n += in.read(a, n, j);
            }
            return (a == null || n == a.length) ? a : Arrays.copyOf(a, n);
        }

        /** Called by the process reaper thread when the process exits. */
        synchronized void processExited() {
            synchronized (closeLock) {
                try {
                    InputStream in = this.in;
                    // this stream is closed if and only if: in == null
                    if (in != null) {
                        byte[] stragglers = drainInputStream(in);
                        in.close();
                        if (stragglers == null) {
                            this.in = ProcessBuilder.NullInputStream.INSTANCE;
                        } else {
                            this.in = new ByteArrayInputStream(stragglers);
                        }
                    }
                } catch (IOException ignored) {
                }
            }
        }

        @Override
        public void close() throws IOException {
            // BufferedInputStream#close() is not synchronized unlike most other
            // methods. Synchronizing helps avoid race with processExited().
            synchronized (closeLock) {
                super.close();
            }
        }
    }

    /**
     * A buffered output stream for a subprocess pipe file descriptor that allows
     * the underlying file descriptor to be reclaimed when the process exits, via
     * the processExited hook.
     * 
     * This class is taken more or less as-is from the JDK 9 implementation.
     */
    private static class ProcessPipeOutputStream extends BufferedOutputStream {
        ProcessPipeOutputStream(int fd) {
            super(new FileOutputStream(newFileDescriptor(fd)));
        }

        /** Called by the process reaper thread when the process exits. */
        synchronized void processExited() {
            if (this.out != null) {
                try {
                    this.out.close();
                } catch (IOException ignored) {
                }
                this.out = ProcessBuilder.NullOutputStream.INSTANCE;
            }
        }
    }
}
