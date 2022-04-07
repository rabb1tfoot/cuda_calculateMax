#pragma once

#include "windows.h"
#include "wingdi.h"
#pragma warning(disable: 4996) 
#include <iostream>


class CImgLoader {

public:
	unsigned char * m_buffer;
	int m_bSize_X;
	int m_bSize_Y;
	CImgLoader(std::string _path);

	~CImgLoader();

private:
	CImgLoader() {};
};