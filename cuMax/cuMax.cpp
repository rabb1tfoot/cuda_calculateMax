#include "cuMax.h"

CImgLoader::CImgLoader(const std::string _path)
	: m_bSize_X(2048)
	, m_bSize_Y(2048)
{
	FILE* f;
	f = fopen(_path.c_str(), "rb");
	unsigned char byte[8] = {};
	//header
	BITMAPFILEHEADER hf;
	BITMAPINFOHEADER hInfo;
	fread(&hf, sizeof(BITMAPFILEHEADER), 1, f);
	//chk bmp
	if (hf.bfType == 0x4D42)
	{

		fread(&hInfo, sizeof(BITMAPINFOHEADER), 1, f);
	
		// BMP Pallete
		RGBQUAD hRGB[256];
		fread(hRGB, sizeof(RGBQUAD), 256, f);

		// Memory y상하가 뒤집혀서 저장되어있다.
		long otherSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + sizeof(RGBQUAD) * 256;
		long pixelSize = hf.bfSize - otherSize;
		unsigned char *lpImg = new unsigned char[pixelSize];
		m_buffer = new unsigned char[pixelSize];
		fread(lpImg, sizeof(char), pixelSize, f);

		for (int i = 0; i < m_bSize_Y; ++i)
		{
			for (int j = 0; j < m_bSize_X; ++j)
			{
				long idx = ((m_bSize_Y - i  - 1) * m_bSize_X) + j;
				m_buffer[i * m_bSize_X + j] = lpImg[idx];
			}
		}
		fclose(f);
		delete(lpImg);
	}

	//Mat img = imread(_path, 0);
	//
	//if (img.empty())
	//{
	//	std::cout << "!!! Failed imread(): image not found" << std::endl;
	//}
	//
	//m_bSize = img.channels() * img.cols * img.rows;
	//m_buffer = new unsigned char[m_bSize];
	//
	//
	//memcpy(m_buffer, img.data, m_bSize);
}

CImgLoader::~CImgLoader()
{
	delete(m_buffer);
}
