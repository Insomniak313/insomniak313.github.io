#pragma once

#include "common.h"

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#endif

static inline uint32 NetHtonU32(uint32 v)
{
	return htonl(v);
}

static inline uint32 NetNtohU32(uint32 v)
{
	return ntohl(v);
}

static inline uint16 NetHtonU16(uint16 v)
{
	return htons(v);
}

static inline uint16 NetNtohU16(uint16 v)
{
	return ntohs(v);
}

static inline uint32 NetHtonF32(float v)
{
	uint32 u;
	static_assert(sizeof(uint32) == sizeof(float), "float must be 32-bit");
	memcpy(&u, &v, sizeof(u));
	return NetHtonU32(u);
}

static inline float NetNtohF32(uint32 v)
{
	uint32 u = NetNtohU32(v);
	float f;
	memcpy(&f, &u, sizeof(f));
	return f;
}

