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

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;

/**
 * A shim that sits between {@link java.lang.ProcessBuilder} and
 * {@link java.lang.Process} that will start processes on the sandbox host using
 * the Flatpak shim if the client tries to execute programs that reside on the
 * sandbox host mount point.
 */
class ProcessImplFactory {

    /**
     * For use only by {@link ProcessBuilder#start()}.
     */
    static Process start(String[] cmdarray, Map<String, String> environment, String dir,
            ProcessBuilder.Redirect[] redirects, boolean redirectErrStream) throws IOException {

        Path exe = Paths.get(cmdarray[0]);
        if (exe.startsWith(Paths.get("/var/run/host"))) {
            // If the desired executable program lives in /var/run/host (where the sandbox
            // host is mounted) then execute it on the sandbox host
            cmdarray[0] = Paths.get("/").resolve(exe.subpath(3, exe.getNameCount())).toString();
            return runOnHost(cmdarray, environment, dir, redirects, redirectErrStream);
        }
        // 1) Invoking "which" directly, the command we really want to test for is the
        // next argument
        String testexe = cmdarray[0];
        boolean which = false;
        if (exe.endsWith(Paths.get("which"))) {
            testexe = cmdarray[1];
            which = true;
        }

        // 2) Invoking "which" through a shell, the command we really want to test for
        // is the second word of the final argument when "-c" is passed to the shell
        if (exe.endsWith(Paths.get("sh")) || exe.endsWith(Paths.get("bash")) || exe.endsWith(Paths.get("dash"))) {
            boolean executingShellCommand = false;
            for (String s : cmdarray) {
                if (s.equals("-c")) {
                    executingShellCommand = true;
                    break;
                }
            }
            if (executingShellCommand) {
                String shellCommand = cmdarray[cmdarray.length - 1];
                String[] shellCommandParts = shellCommand.split("\\s");
                if (shellCommandParts.length > 1 && Paths.get(shellCommandParts[0]).endsWith("which")) {
                    testexe = shellCommandParts[1];
                    which = true;
                }
            }
        }

        // If the desired executable program exists in the sandbox, then run normally
        boolean inSandbox = detectExecutablePresence(true, testexe, environment, dir);
        if (inSandbox) {
            return runInSandbox(cmdarray, environment, dir, redirects, redirectErrStream);
        }
        // If the desired executable program does not exist in the sandbox, then execute
        // it on the sandbox host
        boolean onHost = detectExecutablePresence(false, testexe, environment, dir);
        if (onHost || which) {
            return runOnHost(cmdarray, environment, dir, redirects, redirectErrStream);
        }
        throw new IOException("No such file or directory");
    }

    private static boolean detectExecutablePresence(boolean sandbox, String exe, Map<String, String> environment,
            String dir) throws IOException {
        String[] whichCommand = new String[] { "sh", "-c", "-l", "which " + exe };
        ProcessBuilder.Redirect[] redirects = new ProcessBuilder.Redirect[] { ProcessBuilder.Redirect.PIPE,
                ProcessBuilder.Redirect.PIPE, ProcessBuilder.Redirect.PIPE };
        Process which;
        if (Boolean.getBoolean("flatpak.hostcommandrunner.debug")) {
            System.err.println("Checking for presence of '" + exe + (sandbox ? "' in sandbox" : "' on sandbox host"));
        }
        if (sandbox) {
            which = runInSandbox(whichCommand, environment, dir, redirects, false);
        } else {
            which = runOnHost(whichCommand, environment, dir, redirects, false);
        }
        try {
            int exit = which.waitFor();
            if (exit == 0) {
                return true;
            }
            return false;
        } catch (InterruptedException e) {
            throw new IOException("Unable to determine location of executable");
        }
    }

    private static Process runInSandbox(String[] cmdarray, Map<String, String> environment, String dir,
            ProcessBuilder.Redirect[] redirects, boolean redirectErrStream) throws IOException {
        if (Boolean.getBoolean("flatpak.hostcommandrunner.debug")) {
            StringBuilder sb = new StringBuilder("Running in sandbox:");
            for (String arg : cmdarray) {
                sb.append(" " + arg);
            }
            System.err.println(sb.toString());
        }
        return ProcessImpl.start(cmdarray, environment, dir, redirects, redirectErrStream);
    }

    private static Process runOnHost(String[] cmdarray, Map<String, String> environment, String dir,
            ProcessBuilder.Redirect[] redirects, boolean redirectErrStream) throws IOException {
        if (Boolean.getBoolean("flatpak.hostcommandrunner.debug")) {
            StringBuilder sb = new StringBuilder("Running on sandbox host:");
            for (String arg : cmdarray) {
                sb.append(" " + arg);
            }
            System.err.println(sb.toString());
        }
        return FlatpakProcessImpl.start(cmdarray, environment, dir, redirects, redirectErrStream);
    }
}
