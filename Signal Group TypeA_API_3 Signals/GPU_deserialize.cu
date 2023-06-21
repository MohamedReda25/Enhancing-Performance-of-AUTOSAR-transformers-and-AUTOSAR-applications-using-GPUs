#include "GPU_headers.h"
#include <cuda_runtime.h>
using namespace std;


__global__ void ComXf_Inv_Com_ComSignalGroupA_k(uint8* buffer, uint32 bufferLength, SignalGroup_A_Type* dataElement, uint32* offsets1) {

    uint32 x = blockIdx.x * blockDim.x + threadIdx.x;
    uint8* Buffer_ptr = buffer;
    SignalGroup_A_Type* Data_ptr = dataElement;

    if (x < NUM_BYTES) {
        uint32 idx = x;

        if (idx >= offsets1[0] && idx < offsets1[1]) {
            *((uint8*)(&(Data_ptr->signal1)) + (idx - offsets1[0])) = *(Buffer_ptr + idx);
        }
        if (idx >= offsets1[2] && idx < offsets1[3]) {
            *((uint8*)(&(Data_ptr->signal2)) + (idx - offsets1[2])) = *(Buffer_ptr + idx);
        }
        if (idx >= offsets1[4] && idx < offsets1[5]) {
            *((uint8*)(&(Data_ptr->signal3)) + (idx - offsets1[4])) = *(Buffer_ptr + idx);
        }
    }
    





}

uint8 ComXf_Inv_Com_ComSignalGroupA(uint8* buffer, uint32 bufferLength, SignalGroup_A_Type* dataElement) {

    uint32 block_size = 1024;
    uint32 grid_size = (NUM_BYTES + block_size - 1) / block_size;
    uint32 bufferlength = bufferLength;

    SignalGroup_A_Type* ptr_s = dataElement;
    SignalGroup_A_Type* dev_ptr_s = 0;



    /*auto start_time = std::chrono::high_resolution_clock::now();*/
    cudaError_t cudaStatus = cudaMalloc((void**)&dev_ptr_s, sizeof(SignalGroup_A_Type));
    if (cudaStatus != cudaSuccess) {
        printf("cudaMalloc failed: %s\n", cudaGetErrorString(cudaStatus));
    }


     //Transfer data from host to device
    //cudaStatus = cudaMemcpy(dev_ptr_s, ptr_s, sizeof(SignalGroup_A_Type), cudaMemcpyHostToDevice);
    //if (cudaStatus != cudaSuccess) {
    //    printf("cudaMemcpy failed (HostToDevice): %s\n", cudaGetErrorString(cudaStatus));
    //    cudaFree(dev_ptr_s);  // Free the allocated device memory
    //}

    const uint32 offsets_size = 6;
    uint32 offsets_k1[offsets_size];
    uint32* d_offsets;

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


   




    cudaMalloc((void**)&d_offsets, offsets_size * sizeof(int));
    cudaMemcpy(d_offsets, offsets_k1, offsets_size * sizeof(int), cudaMemcpyHostToDevice);

    //auto start_time = std::chrono::high_resolution_clock::now();

    ComXf_Inv_Com_ComSignalGroupA_k << <grid_size, block_size >> > ((uint8*)buffer, bufferlength, dev_ptr_s, d_offsets);

    cudaDeviceSynchronize();

    
    cudaMemcpy(dataElement, dev_ptr_s, bufferlength, cudaMemcpyDeviceToHost); //Transfer struct to host memory
  

 


    cudaFree(dev_ptr_s);
    cudaFree(d_offsets);

 

    return E_OK;

    

}
