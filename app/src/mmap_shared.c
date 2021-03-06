#include <stdio.h>
#include <unistd.h>
#include <sys/mman.h>

int time = 3;

void test_mmap (int active) {
    printf("Shared Active: %d\n", active);
    int BUF_SIZE = 100;

    int* k;
    if (active) {
        k = mmap(NULL, BUF_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    } else {
        k = mmap(NULL, BUF_SIZE, PROT_READ | PROT_WRITE, MAP_ANONYMOUS, -1, 0);
    }
    *k = 0;

    int pid = fork();
    printf("fork: %d\n", pid);
    if (pid == 0) {
        // child
        printf("Child K: %d\n", *k);
        sleep(time);
        sleep(time);
        printf("Child K: %d\n", *k);
        *k = 2;
        printf("ChildChange K: %d\n", *k);
    } else {
        //parent
        sleep(time);
        *k = 1;
        printf("Parent Change K: %d\n", *k);
        sleep(time);
        sleep(time);
        printf("Parent K: %d\n", *k);
    }
}

int main(void) {
    printf("I am %d.\n", getpid());

    //test_mmap(0);
    test_mmap(1);
    
    printf("Succeed!\n");
    return 0;
}