# Task 1 IF4010

Deadline: 17 February 2021, 23:59 WIB

Fork the repo into your own namespace. Set it to private to prevent others from "snooping" your work. Once you are ready to submit your work, `git tag v1.0` your commit and don't forget to give access to @satrio.

For programming questions, edit the corresponding source code file in the `./src/` directory. For non-programming questions, write down the answers directly in this `README.md` file in the space indicated by each question.

## Q1: Common Errors

This class will make heavy use of low-level C constructs and concepts, especially pointers and memory management. 

As a "warm-up", there are a few quick samples of code and their intended specifications in the file `./src/q1.c`. Each such piece of code is incorrect. Identify what is wrong with the code and fix it.

(Many of these problems allude to common errors encountered while writing both GPU and CPU code.)

## Q2: Parallelization

Given an input signal `x[n]`, suppose we have two output signals `y_1[n]` and `y_2[n]`, given by the difference equations: 

```c
y_1[n] = x[n - 1] + x[n] + x[n + 1]
y_2[n] = y_2[n - 2] + y_2[n - 1] + x[n]
```

Which calculation do you expect will have an easier and faster implementation on the GPU, and why?

**Answer:** [write your answer here]


## Q3: CUDA memory

### 3.1. Thread Divergence

Let the block shape be `(32, 32, 1)`.

(a) Does this code diverge? Why or why not?

```c++
int idx = threadIdx.y + blockSize.y * threadIdx.x;
if (idx % 32 < 16)
    foo();
else
    bar();
```

**Answer:** [write your answer here]


(b) Does this code diverge? Why or why not? (This is a bit of a trick question, either "yes" or "no can be a correct answer with appropriate explanation.)

```c++
const float pi = 3.14;
float result = 1.0;
for (int i = 0; i < threadIdx.x; i++)
    result *= pi;
```

**Answer:** [write your answer here]


### 3.2. Coalesced Memory Access

Let the block shape be `(32, 32, 1)`. Let `data` be a `(float *)` pointing to global memory and let `data` be 128 byte aligned (so `data % 128 == 0`).

Consider each of the following access patterns.

(a) Is this write coalesced? How many 128 byte cache lines does this write to?

```c++
data[threadIdx.x + blockSize.x * threadIdx.y] = 1.0;
```

**Answer:** [write your answer here]

(b) Is this write coalesced? How many 128 byte cache lines does this write to?

```c++
data[threadIdx.y + blockSize.y * threadIdx.x] = 1.0;
```

**Answer:** [write your answer here]


(c) Is this write coalesced? How many 128 byte cache lines does this write to?

```c++
data[1 + threadIdx.x + blockSize.x * threadIdx.y] = 1.0;
```

**Answer:** [write your answer here]

## Q4: Matrix transpose optimization (65 points)

Optimize the CUDA matrix transpose implementations in transpose_device.cu. Read ALL of the TODO comments. Matrix transpose is a common exercise in GPU optimization, so do not search for existing GPU matrix transpose code on the Internet.

Your transpose code only need to be able to transpose square matrices where the side length is a multiple of 64.

The initial implementation has each block of 1024 threads handle a 64x64 block of the matrix, but you can change anything about the kernel if it helps obtain better performance.

The main method of `transpose_host.cpp` already checks for correctness for all transpose results, so there should be an assertion failure if your kernel produces incorrect output.

The purpose of the `shmemTransposeKernel` is to demonstrate proper usage of global and shared memory. The `optimalTransposeKernel` should be built on top of `shmemTransposeKernel` and should incorporate any "tricks" such as ILP, loop unrolling, etc that have been discussed in class.

You can compile and run the code by running

```console
$ make transpose
$ ./transpose
```

If this does not work on your machine, make sure you have CUDA binary and library folders in your `$PATH`.

On OS X, you may have to run or add to your `.bash_profile` the command

```console
$ export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/usr/local/cuda/lib/
```

in order to get dynamic library linkage to work correctly.

The transpose program takes 2 optional arguments: input size and method. Input size must be one of `-1`, `512`, `1024`, `2048`, `4096`, and method must be one of `all`, `cpu`, `gpu_memcpy`, `naive`, `shmem`, `optimal`. Input size is the first argument and defaults to `-1`. Method is the second argument and defaults to `all`. You can pass input size without passing method, but you cannot pass method without passing an input size.

Examples:

```console
$ ./transpose
$ ./transpose 512
$ ./transpose 4096 naive
$ ./transpose -1 optimal
```

Copy paste the output of `./transpose` below once you are done. Describe the strategies used for performance in block comments over the kernel (as done for `naiveTransposeKernel`).

**Output:**
[paste output here]
