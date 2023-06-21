#include "GPU_headers.h"
#include "stdio.h"
#include "stdlib.h"
#include "iostream"


void fill_struct_with_data(SignalGroup_A_Type* s_ptr) {
    for (int i = 0; i < signal1_size; i++) {
        s_ptr->signal1[i] = 'a' + (i % 26);
    }
    for (int i = 0; i < signal2_size; i++) {
        s_ptr->signal2[i] = 'a' + (i % 26);
    }
    for (int i = 0; i < signal3_size; i++) {
        s_ptr->signal3[i] = 'a' + (i % 26);
    }


}



void fill_struct_with_zeros(SignalGroup_A_Type* s_ptr) {
    for (int i = 0; i < signal1_size; i++) {
        s_ptr->signal1[i] = 0;
    }
    for (int i = 0; i < signal2_size; i++) {
        s_ptr->signal2[i] = 0;
    }
    for (int i = 0; i < signal3_size; i++) {
        s_ptr->signal3[i] = 0;
    }


}




void serialization_time(float64 duration_s) {
    FILE* serialize;
    char serialize_filename[] = "Time of serialization.txt";

    serialize = fopen(serialize_filename, "w");
    fprintf(serialize, "%f", duration_s * 1e-3);
}
void deserialization_time(float64 duration_s_d) {
    FILE* deserialize;
    char deserialize_filename[] = "Time of deserialization.txt";

    deserialize = fopen(deserialize_filename, "w");


    fprintf(deserialize, "%f", duration_s_d * 1e-3);

}



 





void buffer_data_after_serialization_file_creation(uint8* buffer) {
    FILE* serialize_data;
    char serialize_data_filename[] = "Buffer after serialization";
    //fprintf(serialize_data, "%s", "Buffer data after serialization:\n");
    serialize_data = fopen(serialize_data_filename, "w");
    for (uint32 i = 0; i < buffer_length; i++) {

        fprintf(serialize_data, "%c", buffer[i]);
        fprintf(serialize_data, "%s", "\n");

    }
}

void struct_data_after_deserialization_file_creaation(SignalGroup_A_Type* d_ptr) {
    FILE* deserialize_data;
    char deserialize_data_filename[] = "Struct after deserialization";
    deserialize_data = fopen(deserialize_data_filename, "w");
    for (int i = 0; i < signal1_size; i++) {

        fprintf(deserialize_data, "%c", *((uint8*)(&(d_ptr->signal1)) + i));
        fprintf(deserialize_data, "%s", "\n");

    }
    fprintf(deserialize_data, "%s", "End of signal 1--------------------------------------\n");
    for (int i = 0; i < signal2_size; i++) {

        fprintf(deserialize_data, "%c", *((uint8*)(&(d_ptr->signal2)) + i));
        fprintf(deserialize_data, "%s", "\n");

    }
    fprintf(deserialize_data, "%s", "End of signal 2--------------------------------------\n");
    for (int i = 0; i < signal3_size; i++) {

        fprintf(deserialize_data, "%c", *((uint8*)(&(d_ptr->signal3)) + i));
        fprintf(deserialize_data, "%s", "\n");

    }
    fprintf(deserialize_data, "%s", "End of signal 3--------------------------------------\n");

}





int main()
{
    //Struct is Allocated Using CUDAMemCpy
    SignalGroup_A_Type s;
    SignalGroup_A_Type d;
    SignalGroup_A_Type* d_ptr = &d;
    SignalGroup_A_Type* s_ptr = &s;

    
    fill_struct_with_data(s_ptr);


    //Buffer is in Unified Memory Allocation

    uint32 bufflength = buffer_length;
    uint32* bufflength_ptr = &bufflength;
    uint8* buffer = nullptr;
    cudaError_t cudaStatus;

    cudaFree(0);
    cudaStatus = cudaMallocManaged(&buffer, *(bufflength_ptr));
    if (buffer == nullptr) {
        printf("Failed to allocate memory for buffer.\n");
    }
    if (cudaStatus != cudaSuccess) { 
        fprintf(stderr, "cudaMallocManaged failed: %s\n", cudaGetErrorString(cudaStatus));
    }

   





    // API CALL
    auto start_time = std::chrono::high_resolution_clock::now();
    ComXf_Com_ComSignalGroupA(buffer, bufflength_ptr, s);
    auto finish_time = std::chrono::high_resolution_clock::now();

    auto duration_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(finish_time - start_time);  //Time in NANOSEC
    double duration_s = duration_ns.count();
    printf("\nTime Of Serialization In Micro Seconds: %f\n", duration_s * 1e-3);  //Time in MICROSEC



    fill_struct_with_zeros(d_ptr);

    


    auto start_time_d = std::chrono::high_resolution_clock::now();
    ComXf_Inv_Com_ComSignalGroupA(buffer, bufflength, d_ptr);
    auto finish_time_d = std::chrono::high_resolution_clock::now();

    auto duration_ns_d = std::chrono::duration_cast<std::chrono::nanoseconds>(finish_time_d - start_time_d);  //Time in NANOSEC
    float64 duration_s_d = duration_ns_d.count();
    printf("\nTime Of Deserialization In Micro Seconds: %f\n", duration_s_d * 1e-3);  //Time in MICROSEC






    serialization_time(duration_s);
   
    deserialization_time(duration_s_d);

    buffer_data_after_serialization_file_creation(buffer);

    struct_data_after_deserialization_file_creaation(d_ptr);

    





    
    // Prefetch to the host (CPU)
    cudaStatus = cudaFree(buffer);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaFree failed: %s\n", cudaGetErrorString(cudaStatus));
        return 1;
    }
    return(0);
}
