#include <cassert>
#include <cuda_runtime.h>
#include "transpose_device.cuh"

/*
 * TODO for all kernels (including naive):
 * Leave a comment above all non-coalesced memory accesses and bank conflicts.
 * Make it clear if the suboptimal access is a read or write. If an access is
 * non-coalesced, specify how many cache lines it touches, and if an access
 * causes bank conflicts, say if its a 2-way bank conflict, 4-way bank
 * conflict, etc.
 *
 * Comment all of your kernels.
 */


/*
 * Each block of the naive transpose handles a 64x64 block of the input matrix,
 * with each thread of the block handling a 1x4 section and each warp handling
 * a 32x4 section.
 *
 * If we split the 64x64 matrix into 32 blocks of shape (32, 4), then we have
 * a block matrix of shape (2 blocks, 16 blocks).
 * Warp 0 handles block (0, 0), warp 1 handles (1, 0), warp 2 handles (0, 1),
 * warp n handles (n % 2, n / 2).
 *
 * This kernel is launched with block shape (64, 16) and grid shape
 * (n / 64, n / 64) where n is the size of the square matrix.
 *
 * You may notice that we suggested in lecture that threads should be able to
 * handle an arbitrary number of elements and that this kernel handles exactly
 * 4 elements per thread. This is OK here because to overwhelm this kernel
 * it would take a 4194304 x 4194304    matrix, which would take ~17.6TB of
 * memory (well beyond what I expect GPUs to have in the next few years).
 */
__global__
void naiveTransposeKernel(const float *input, float *output, int n) {
    // TODO: do not modify code, just comment on suboptimal accesses

    const int i = threadIdx.x + 64 * blockIdx.x;
    int j = 4 * threadIdx.y + 64 * blockIdx.y;
    const int end_j = j + 4;
    
    // Can be unrolled by setting j constant and adding an iterator e.g. +0, +1, , +2, +3,
    for (; j < end_j; j++)
        output[j + n * i] = input[i + n * j];//access to input can be changed to shared memory
}

__global__
void shmemTransposeKernel(const float *input, float *output, int n) {
    // TODO: Modify transpose kernel to use shared memory. All global memory
    // reads and writes should be coalesced. Minimize the number of shared
    // memory bank conflicts (0 bank conflicts should be possible using
    // padding). Again, comment on all sub-optimal accesses.

    // __shared__ float data[???];
    __shared__ float s_input[64*65]; // the number of thread's per block
    __shared__ float s_output[64*65];

    const int i = threadIdx.x + 64 * blockIdx.x;
    const int j = 4 * threadIdx.y + 64 * blockIdx.y;
    //copy from input
    for (int k = 0; k < 4; k++)
        s_input[64*threadIdx.y + threadIdx.x + 1024*k] = input[i + n * (j+k)];
    __syncthreads();

    //transpose
    for (int k = 0; k < 4; k++)
        s_output[64*threadIdx.x+threadIdx.y + 16*k] = s_input[64*threadIdx.y + threadIdx.x + 1024*k];
    __syncthreads();

    //copy to output
    for (int k = 0; k < 4; k++)
        output[j+k + n * i] = s_output[64*threadIdx.y + threadIdx.x + 1024*k];
}

__global__
void optimalTransposeKernel(const float *input, float *output, int n) {
    // TODO: This should be based off of your shmemTransposeKernel.
    // Use any optimization tricks discussed so far to improve performance.
    // Consider ILP and loop unrolling.

    __shared__ float s_input[64*65]; // the number of thread's per block
    __shared__ float s_output[64*65];

    const int i = threadIdx.x + 64 * blockIdx.x;
    const int j = 4 * threadIdx.y + 64 * blockIdx.y;
    //copy from input
    #pragma unroll
    for (int k = 0; k < 4; k++)
        s_input[64*threadIdx.x+threadIdx.y + 16*k] = input[i + n * (j+k)];
    __syncthreads();

    //transpose
    #pragma unroll
    for (int k = 0; k < 4; k++)
        s_output[64*threadIdx.y + threadIdx.x + 1024*k] = s_input[64*threadIdx.x+threadIdx.y + 16*k];
    __syncthreads();

    //copy to output
    #pragma unroll
    for (int k = 0; k < 4; k++)
        output[j+k + n * i] = s_output[64*threadIdx.y + threadIdx.x + 1024*k];
}

void cudaTranspose(
    const float *d_input,
    float *d_output,
    int n,
    TransposeImplementation type)
{
    if (type == NAIVE) {
        dim3 blockSize(64, 16);
        dim3 gridSize(n / 64, n / 64);
        naiveTransposeKernel<<<gridSize, blockSize>>>(d_input, d_output, n);
    }
    else if (type == SHMEM) {
        dim3 blockSize(64, 16);
        dim3 gridSize(n / 64, n / 64);
        shmemTransposeKernel<<<gridSize, blockSize>>>(d_input, d_output, n);
    }
    else if (type == OPTIMAL) {
        dim3 blockSize(64, 16);
        dim3 gridSize(n / 64, n / 64);
        optimalTransposeKernel<<<gridSize, blockSize>>>(d_input, d_output, n);
    }
    // Unknown type
    else
        assert(false);
}
