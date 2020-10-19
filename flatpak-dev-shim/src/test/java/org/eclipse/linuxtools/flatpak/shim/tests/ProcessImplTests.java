/*********************************************************************
 * Copyright (c) 2018, 2019 Red Hat, Inc. and others.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 **********************************************************************/
package org.eclipse.linuxtools.flatpak.shim.tests;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;

@TestInstance(Lifecycle.PER_METHOD)
public class ProcessImplTests {

    private List<String> outLines = new ArrayList<>();
    private List<String> errLines = new ArrayList<>();

    @Test
    public void runInSandbox() throws IOException, InterruptedException {
        int rc1 = readThenWait(false, "ls", "-l", "/");
        Assertions.assertEquals(0, rc1);
        int rc2 = readThenWait(false, "/usr/bin/ls", "-l", "/");
        Assertions.assertEquals(0, rc2);
    }

    @Test
    public void runOnHost() throws IOException, InterruptedException {
        int rc = readThenWait(false, "/var/run/host/usr/bin/ls", "-l", "/");
        Assertions.assertEquals(0, rc);
    }

    @Test
    public void runOnHostDueToNotFoundInSandbox() throws InterruptedException {
        try {
            readThenWait(false, "no_such_exe");
            Assertions.fail("An IOException was expected");
        } catch (IOException e) {
            System.out.println("Exception: " + e.getMessage());
            Assertions.assertTrue(e.getMessage().contains("No such file or directory"));
        }
    }

    @Test
    public void runOnHostWithoutErrRedirection() throws IOException, InterruptedException {
        int rc = readThenWait(false, "/var/run/host/bin/sh", "-c",
                "echo 'starting...' && sleep 1 && echo 'oh no' 1>&2 && sleep 1 && echo done && exit 42");
        Assertions.assertEquals(42, rc);
        List<String> expected = new ArrayList<>();
        expected.add("starting...");
        expected.add("done");
        Assertions.assertLinesMatch(expected, outLines);
        List<String> expected2 = new ArrayList<>();
        expected2.add("oh no");
        Assertions.assertLinesMatch(expected2, errLines);
    }

    @Test
    public void runOnHostWithErrRedirection() throws IOException, InterruptedException {
        int rc = readThenWait(true, "/var/run/host/bin/sh", "-c",
                "echo 'starting...' && sleep 1 && echo 'oh no' 1>&2 && sleep 1 && echo done && exit 42");
        Assertions.assertEquals(42, rc);
        List<String> expected = new ArrayList<>();
        expected.add("starting...");
        expected.add("oh no");
        expected.add("done");
        Assertions.assertLinesMatch(expected, outLines);
    }

    @Test
    public void passEnvVariable() throws IOException, InterruptedException {
        Map<String, String> env = new HashMap<>();
        env.put("BEANS", "cheese");

        readThenWait(true, null, env, "/var/run/host/usr/bin/env");
        boolean found = false;
        for (String line : outLines) {
            if (line.equals("BEANS=cheese")) {
                found = true;
            }
        }
        Assertions.assertTrue(found);
    }

    @Test
    public void changeWorkingDir() throws IOException, InterruptedException {
        readThenWait(true, new File("/tmp"), null, "/var/run/host/usr/bin/sh", "-c", "pwd");
        List<String> expected = new ArrayList<>();
        expected.add("/tmp");
        Assertions.assertLinesMatch(expected, outLines);
    }

    @Test
    public void avoidDoubleInvokationOfWhichInvalid() throws IOException, InterruptedException {
        avoidDoubleInvokationOfWhich("no_such_exe", 1, "which: no no_such_exe in");
    }

    @Test
    public void avoidDoubleInvokationOfWhichValid() throws IOException, InterruptedException {
        avoidDoubleInvokationOfWhich("test", 0, "/usr/bin/test");
    }

    private void avoidDoubleInvokationOfWhich(String exe, int retcode, String message)
            throws IOException, InterruptedException {
        int rc1 = readThenWait(true, "which", exe);
        Assertions.assertEquals(retcode, rc1);
        Assertions.assertTrue(outLines.get(0).contains(message));
        outLines.clear();
        int rc2 = readThenWait(true, "/usr/bin/which", exe);
        Assertions.assertEquals(retcode, rc2);
        Assertions.assertTrue(outLines.get(0).contains(message));
        outLines.clear();
        int rc3 = readThenWait(true, "/usr/bin/sh", "-c", "-l", "which " + exe);
        Assertions.assertEquals(retcode, rc3);
        Assertions.assertTrue(outLines.get(0).contains(message));
        outLines.clear();
        int rc4 = readThenWait(true, "/usr/bin/sh", "-c", "-l", "/usr/bin/which " + exe);
        Assertions.assertEquals(retcode, rc4);
        Assertions.assertTrue(outLines.get(0).contains(message));
        outLines.clear();
    }

    private int readThenWait(boolean redirectErr, String... args) throws IOException, InterruptedException {
        return readThenWait(redirectErr, null, null, args);
    }

    private int readThenWait(boolean redirectErr, File working, Map<String, String> env, String... args)
            throws IOException, InterruptedException {
        ProcessBuilder pb = new ProcessBuilder(args);
        pb.redirectErrorStream(redirectErr);
        if (env != null && !env.isEmpty()) {
            Map<String, String> environment = pb.environment();
            for (String key : env.keySet()) {
                environment.put(key, env.get(key));
            }
        }
        if (working != null) {
            pb.directory(working);
        }
        Process p = pb.start();
        try (BufferedReader outReader = new BufferedReader(new InputStreamReader(p.getInputStream()));
                BufferedReader errReader = new BufferedReader(new InputStreamReader(p.getErrorStream()))) {
            String line = null;
            while ((line = outReader.readLine()) != null) {
                System.out.println("Read from process stdout: \"" + line + "\"");
                outLines.add(line);
            }
            while ((line = errReader.readLine()) != null) {
                System.err.println("Read from process stderr: \"" + line + "\"");
                errLines.add(line);
            }
        }
        int exit = p.waitFor();
        System.out.println("Process exited with " + exit);
        System.out.println();
        return exit;
    }
}
