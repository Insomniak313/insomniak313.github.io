#pragma once

#include "common.h"

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
typedef SOCKET net_socket_t;
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <unistd.h>
typedef int net_socket_t;
#endif

struct NetAddr
{
	sockaddr_storage storage;
	socklen_t len;

	NetAddr() : len(0) { memset(&storage, 0, sizeof(storage)); }
};

class CUdpSocket
{
public:
	CUdpSocket();
	~CUdpSocket();

	bool Open(uint16 bindPort);
	void Close();
	bool IsOpen() const;

	bool SendTo(const NetAddr &to, const void *data, int32 size) const;
	int32 RecvFrom(NetAddr &from, void *outData, int32 outCapacity) const;

	static bool ParseIPv4(const char *ip, uint16 port, NetAddr &outAddr);

private:
	net_socket_t m_socket;
	bool m_isOpen;

	static bool s_systemInited;
	static void EnsureSystemInit();
	static void SetNonBlocking(net_socket_t s);
};

