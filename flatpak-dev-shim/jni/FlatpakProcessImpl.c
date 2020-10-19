/* The fact that we are running this implies we are on Linux, so may as well use GNU extensions */
#define _GNU_SOURCE

#include <assert.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

#include <jni.h>

#include "java_lang_FlatpakProcessImpl.h"

typedef struct ProcessData {
    int in[2];
    int out[2];
    int err[2];
    int fds[3];
    const char **argv;
    const char **envv;
    unsigned char redirectErrStream;
} ProcessData;

/**
 * Child process entry point, called after a successful vfork(2) and will call exec(3) to replace the process image
 * with the HostCommandRunner executable instead of returning to the caller.
 */
static void start_process(ProcessData *p) {

    /* Close the parent side of the pipes */
    if (p->in[1] != -1) {
        close(p->in[1]);
    }
    if (p->out[0] != -1) {
        close(p->out[0]);
    }
    if (p->err[0] != -1) {
        close(p->err[0]);
    }

    /* Setup the file descriptor pipes for the host command process runner */
    if (p->in[0] != -1) {
        dup2(p->in[0], STDIN_FILENO);
        close(p->in[0]);
    } else {
        dup2(p->fds[0], STDIN_FILENO);
        close(p->fds[0]);
    }
    if (p->out[1] != -1) {
        dup2(p->out[1], STDOUT_FILENO);
        close(p->out[1]);
    } else {
        dup2(p->fds[1], STDOUT_FILENO);
        close(p->fds[1]);
    }
    if (p->redirectErrStream) {
        if (p->err[1] != -1) {
            close(p->err[1]);
        }
        dup2(STDOUT_FILENO, STDERR_FILENO);
    } else {
        if (p->err[1] != -1) {
            dup2(p->err[1], STDERR_FILENO);
            close(p->err[1]);
        } else {
            dup2(p->fds[1], STDERR_FILENO);
            close(p->fds[1]);
        }
    }

    execvpe(p->argv[0], (char * const *) p->argv, (char * const *) p->envv);
}

/**
 * Convert a contiguous block of bytes that contains null-terminated strings into a vector of such strings. Returned
 * is a pointer to a null-terminated vector of null-terminated strings. This memory must be free'd by the caller.
 */
static const char **initialise_vector(const char *bytes, int count) {
    /*
     * The returned vector must have a null final entry, so we allocate one more than count and the contract of
     * calloc(3) ensures that it will be initialised to zero
     */
    const char **v = calloc(count + 1, sizeof(char*));
    const char *p = bytes;
    for (int i = 0; i < count; i++) {
        /*
         * Increment pointer p until we encounter a null that marks the end of a string, this makes p always point to
         * the start of a string the next time through the loop
         */
        v[i] = p;
        while (*(p++))
            ;
    }
    return v;
}

JNIEXPORT jint JNICALL Java_java_lang_FlatpakProcessImpl_forkAndExecHostCommand(JNIEnv *env, jobject process,
        jbyteArray argv, jint argc, jbyteArray envv, jint envc, jintArray fds, jboolean redirectErrStream) {

    ProcessData *p = calloc(1, sizeof(ProcessData));

    /* Initialise the command and argument list, this is never null */
    const char *argBytes = (const char*) (*env)->GetByteArrayElements(env, argv, NULL);
    p->argv = initialise_vector(argBytes, argc);

    /* Initialise the environment list of key/values, this is never null, but might be empty */
    const char *envBytes = (const char*) (*env)->GetByteArrayElements(env, envv, NULL);
    p->envv = initialise_vector(envBytes, envc);

    /* Set up file descriptors and/or pipes to child process */
    jint *std_fds = (*env)->GetIntArrayElements(env, fds, NULL);
    p->fds[0] = std_fds[0];
    if (p->fds[0] == -1) {
        assert(pipe(p->in) != -1);
    } else {
        p->in[0] = p->in[1] = -1;
    }
    p->fds[1] = std_fds[1];
    if (p->fds[1] == -1) {
        assert(pipe(p->out) != -1);
    } else {
        p->out[0] = p->out[1] = -1;
    }
    p->fds[2] = std_fds[2];
    if (p->fds[2] == -1) {
        assert(pipe(p->err) != -1);
    } else {
        p->err[0] = p->err[1] = -1;
    }

    /* Whether the child process should merge together its stderr into the stdout stream */
    p->redirectErrStream = redirectErrStream;

    /*
     * Fork the process here -- we are using vfork(2) instead of fork(2) because we will be replacing the child
     * process image with a call to exec(3) straight away. The child process will disappear into start_process()
     * and never return while the parent process will continue on from here.
     */
    int child_pid = vfork();
    if (child_pid == 0) {
        start_process(p);
    }

    /* Close the child side of the pipes */
    if (p->in[0] != -1) {
        close(p->in[0]);
    }
    if (p->out[1] != -1) {
        close(p->out[1]);
    }
    if (p->err[1] != -1) {
        close(p->err[1]);
    }

    /* Copy file descriptors for passing back to Java */
    std_fds[0] = p->in[1];
    std_fds[1] = p->out[0];
    std_fds[2] = p->err[0];
    (*env)->ReleaseIntArrayElements(env, fds, std_fds, 0);

    /* Clean up everything else */
    (*env)->ReleaseByteArrayElements(env, argv, (jbyte*) argBytes, JNI_ABORT);
    (*env)->ReleaseByteArrayElements(env, envv, (jbyte*) envBytes, JNI_ABORT);
    free(p->argv);
    free(p->envv);
    free(p);

    return child_pid;
}
