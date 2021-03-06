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
        //access to input can be changed to shared memory
        //access to global memory can be coalesced
        output[j + n * i] = input[i + n * j];
}

__global__
void shmemTransposeKernel(const float *input, float *output, int n) {
    // TODO: Modify transpose kernel to use shared memory. All global memory
    // reads and writes should be coalesced. Minimize the number of shared
    // memory bank conflicts (0 bank conflicts should be possible using
    // padding). Again, comment on all sub-optimal accesses.

    // __shared__ float data[???];
    
    __shared__ float data[64*65]; //add padding to remove bank conflict
    
    int i = blockIdx.x * 64 + threadIdx.x;
    int j = blockIdx.y * 64 + threadIdx.y;
  
    for (int k = 0; k < 64; k += 16) //can be unrolled
        data[64*(threadIdx.y+k)+threadIdx.x] = input[(j+k)*n + i]; 
  
    __syncthreads();
  
    //may have a way to use ILP
    i = blockIdx.y * 64 + threadIdx.x;  
    j = blockIdx.x * 64 + threadIdx.y;
  
    for (int k = 0; k < 64; k += 16) //can be unrolled
       output[(j+k)*n + i] = data[64*threadIdx.x+threadIdx.y + k]; //bank conflict will occur
    
}

__global__
void optimalTransposeKernel(const float *input, float *output, int n) {
    // TODO: This should be based off of your shmemTransposeKernel.
    // Use any optimization tricks discussed so far to improve performance.
    // Consider ILP and loop unrolling.
    
    __shared__ float data[64][64+1];
    
    int i = blockIdx.x * 64 + threadIdx.x;
    int j = blockIdx.y * 64 + threadIdx.y;
  
    //Suprisingly changing the read to 2d 
    data[threadIdx.y][threadIdx.x] = input[(j)*n + i];
    data[threadIdx.y+16][threadIdx.x] = input[(j+16)*n + i];
    data[threadIdx.y+32][threadIdx.x] = input[(j+32)*n + i];
    data[threadIdx.y+48][threadIdx.x] = input[(j+48)*n + i];
  
    __syncthreads();
  
    i = blockIdx.y * 64 + threadIdx.x;  // transpose block offset
    j = blockIdx.x * 64 + threadIdx.y;
  
    output[(j)*n + i] = data[threadIdx.x][threadIdx.y];
    output[(j+16)*n + i] = data[threadIdx.x][threadIdx.y + 16];
    output[(j+32)*n + i] = data[threadIdx.x][threadIdx.y + 32];
    output[(j+48)*n + i] = data[threadIdx.x][threadIdx.y + 48];
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
