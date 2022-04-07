

#include <cuda_runtime.h>
#ifndef __CUDACC__  
#define __CUDACC__
#endif
#include <device_functions.h>
#include <device_launch_parameters.h>


#include <iostream>

#include "cuMax.h"
#include <ctime>

cudaError_t MaxAlgo(float *in, int sizeX, int sizeY);
void ToDouble(unsigned char* input, double* output, int size);
void ToFloat(unsigned char* input, float* output, int size);

__device__ void atomicMax(float* address, float value)
{
	if (*address >= value)
	{
		return;
	}

	int* const addressAsI = (int*)address;
	int old = *addressAsI, assumed;

	do
	{
		assumed = old;
		if (__int_as_float(assumed) >= value)
		{
			break;
		}

		old = atomicCAS(addressAsI, assumed, __float_as_int(value));
	} while (assumed != old);
}

__global__ void MaxKernel(float* __restrict__ input, const int* size, float* maxOut, int* maxIdxOut)
{
	float localMax = 0.f;
	int localMaxIdx = 0;

	for (int i = threadIdx.x; i < (*size); i += blockDim.x)
	{
		float val = input[i];

		if (localMax < abs(val))
		{
			localMax = abs(val);
			localMaxIdx = i;
		}
	}

	atomicMax(maxOut, localMax);

	__syncthreads();

	if (*maxOut == localMax)
	{
		*maxIdxOut = localMaxIdx;
	}
}

int main()
{
	std::string filePath = "D:\\Projects\\cuMax\\x64\\Debug\\test1.bmp";

	CImgLoader* manager = new CImgLoader(filePath);
	float* buffer = new float[manager->m_bSize_X * manager->m_bSize_Y];

	ToFloat(manager->m_buffer, buffer, manager->m_bSize_X * manager->m_bSize_Y);



	cudaError_t cudaStatus = MaxAlgo(buffer, manager->m_bSize_X, manager->m_bSize_Y);

	// cudaDeviceReset must be called before exiting in order for profiling and
	// tracing tools such as Nsight and Visual Profiler to show complete traces.
	cudaStatus = cudaDeviceReset();

	delete(manager);
	delete(buffer);
	return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t MaxAlgo(float *in, int size_X, int size_Y)
{
	float *dev_in;
	float *dev_out;
	int *dev_index;
	int *dev_size;

	int* outIndex = new int();
	*outIndex = 0;

	int *size = new int();
	*size = size_X * size_Y;

	cudaError_t cudaStatus;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);

	// Allocate GPU inputs  .
	cudaStatus = cudaMalloc((void**)&dev_in, (*size) * sizeof(float));
	cudaStatus = cudaMalloc((void**)&dev_out, (*size) * sizeof(float));
	cudaStatus = cudaMalloc((void**)&dev_size, sizeof(int));
	cudaStatus = cudaMalloc((void**)&dev_index, sizeof(int));

	// Copy inputs from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_in, in, (*size) * sizeof(float), cudaMemcpyHostToDevice);
	cudaStatus = cudaMemcpy(dev_size, size, sizeof(int), cudaMemcpyHostToDevice);

	LARGE_INTEGER        tFreq, tStart, tEnd;
	float                           tElapsedTime;
	QueryPerformanceFrequency(&tFreq);        // 주파수 측정
	QueryPerformanceCounter(&tStart);
	// Launch a kernel on the GPU with one thread for each element.
	MaxKernel<<<1, 1024 >>>(dev_in, dev_size, dev_out, dev_index);
	QueryPerformanceCounter(&tEnd);
	tElapsedTime = ((tEnd.QuadPart - tStart.QuadPart) / (float)tFreq.QuadPart) * 1000; //ms단위

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(outIndex, dev_index, sizeof(int), cudaMemcpyDeviceToHost);

	std::cout << "gpu 연산결과 인덱스 : " << *outIndex << "\n";
	std::cout << "gpu 수행시간 : " << tElapsedTime << " ms\n";

	cudaFree(dev_in);
	cudaFree(dev_size);
	cudaFree(dev_out);
	cudaFree(dev_index);

	delete(outIndex);
	delete(size);

	return cudaStatus;
}

void ToDouble(unsigned char* input, double* output, int size)
{
	output = new double[size];
	int maxIdx = 0;
	double maxvalue = 0;

	for (int i = 0; i < size; ++i)
	{
		output[i] = static_cast<double>(input[i]);
		double comp = output[i];
		if (comp > maxvalue)
		{
			maxvalue = comp;
			maxIdx = i;
		}
	}

	int aa = 0;
}

void ToFloat(unsigned char * input, float * output, int size)
{
	int maxIdx = 0;
	float maxvalue = 0;

	for (int i = 0; i < size; ++i)
	{
		output[i] = static_cast<float>(input[i]);
		float comp = output[i];
		if (comp > maxvalue)
		{
			maxvalue = comp;
			maxIdx = i;
		}
	}

	int ab = 0;

	std::cout << "cpu 연산결과 인덱스 : " << maxIdx << "\n";
}
