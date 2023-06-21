#include "GPU_headers.h"
#include <cuda_runtime.h>
using namespace std;


__global__ void ComXf_Com_ComSignalGroupA_k(uint8* buffer, uint32* bufferLength, SignalGroup_A_Type* dataElement, uint32* offsets1) {
    uint8* buff = buffer;
    uint32 x = blockIdx.x * blockDim.x + threadIdx.x;
    SignalGroup_A_Type* dataElement_ptr = dataElement;
    if (x < NUM_BYTES) {
        uint32 idx = x;
        if (idx >= offsets1[0] && idx < offsets1[1]) {
            buff[idx] = *(((uint8*)&dataElement_ptr->signal1) + (idx - offsets1[0]));
        }
        if (idx >= offsets1[2] && idx < offsets1[3]) {
            buff[idx] = *(((uint8*)&dataElement_ptr->signal2) + (idx - offsets1[2]));
        }
        if (idx >= offsets1[4] && idx < offsets1[5]) {
            buff[idx] = *(((uint8*)&dataElement_ptr->signal3) + (idx - offsets1[4]));
        }
    }
    
    
}

void ComXf_Com_ComSignalGroupA(uint8* buffer, uint32* bufferLength, SignalGroup_A_Type dataElement) {

    uint32 block_size = 1024;
    uint32 grid_size = (NUM_BYTES + block_size - 1) / block_size;

    uint32* bufferlength = bufferLength;

    SignalGroup_A_Type* ptr_s = &dataElement;
    SignalGroup_A_Type* dev_ptr_s = 0;


    
    // Allocate device memory
    cudaError_t cudaStatus = cudaMalloc((void**)&dev_ptr_s, sizeof(SignalGroup_A_Type));
    if (cudaStatus != cudaSuccess) {
        printf("cudaMalloc failed: %s\n", cudaGetErrorString(cudaStatus));
    }

    // Transfer data from host to device
    cudaStatus = cudaMemcpy(dev_ptr_s, ptr_s, sizeof(SignalGroup_A_Type), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        printf("cudaMemcpy failed (HostToDevice): %s\n", cudaGetErrorString(cudaStatus));
        cudaFree(dev_ptr_s);  // Free the allocated device memory
    }


    //Start & End offsets of Signals 2 - 10
    const uint32 offsets_size_k1 = 6;
    uint32 offsets_k1[offsets_size_k1];
    uint32* d_offsets_k1;

    uint32 start = 0, end = sizeof(dev_ptr_s->signal1);
    offsets_k1[0] = start;
    offsets_k1[1] = end;

    start = end;
    end = start + sizeof(dev_ptr_s->signal2);
    offsets_k1[2] = start;
    offsets_k1[3] = end;

    start = end;
    end = start + sizeof(dev_ptr_s->signal3);
    offsets_k1[4] = start;
    offsets_k1[5] = end;

    






    printf("Total Number of Bytes: %d\n", end);

    cudaMalloc((void**)&d_offsets_k1, offsets_size_k1 * sizeof(int));
    cudaMemcpy(d_offsets_k1, offsets_k1, offsets_size_k1 * sizeof(int), cudaMemcpyHostToDevice);

    //Serialization Sandwich
    //I'm here

    ComXf_Com_ComSignalGroupA_k<< <grid_size, block_size >> > ((uint8*)buffer, bufferlength, dev_ptr_s, d_offsets_k1);

    cudaDeviceSynchronize();
    

    
    
    //Serialization Sandwich





    cudaFree(dev_ptr_s);
    cudaFree(d_offsets_k1);


}


