#include "common.h"

#include "UdpSocket.h"

#ifdef _WIN32
#pragma comment(lib, "ws2_32.lib")
#else
#include <errno.h>
#endif

bool CUdpSocket::s_systemInited = false;

CUdpSocket::CUdpSocket()
{
#ifdef _WIN32
	m_socket = INVALID_SOCKET;
#else
	m_socket = -1;
#endif
	m_isOpen = false;
}

CUdpSocket::~CUdpSocket()
{
	Close();
}

void
CUdpSocket::EnsureSystemInit()
{
	if (s_systemInited)
		return;

#ifdef _WIN32
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
		// Can't do much more here.
		return;
	}
#endif
	s_systemInited = true;
}

void
CUdpSocket::SetNonBlocking(net_socket_t s)
{
#ifdef _WIN32
	u_long mode = 1;
	ioctlsocket(s, FIONBIO, &mode);
#else
	int flags = fcntl(s, F_GETFL, 0);
	if (flags < 0)
		flags = 0;
	fcntl(s, F_SETFL, flags | O_NONBLOCK);
#endif
}

bool
CUdpSocket::Open(uint16 bindPort)
{
	Close();
	EnsureSystemInit();
	if (!s_systemInited)
		return false;

	net_socket_t s = (net_socket_t)socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
#ifdef _WIN32
	if (s == INVALID_SOCKET)
		return false;
#else
	if (s < 0)
		return false;
#endif

	int one = 1;
	setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char *)&one, sizeof(one));

	sockaddr_in addr;
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	addr.sin_port = htons(bindPort);

	if (bind(s, (sockaddr *)&addr, sizeof(addr)) != 0) {
#ifdef _WIN32
		closesocket(s);
#else
		close(s);
#endif
		return false;
	}

	SetNonBlocking(s);
	m_socket = s;
	m_isOpen = true;
	return true;
}

void
CUdpSocket::Close()
{
	if (!m_isOpen)
		return;

#ifdef _WIN32
	if (m_socket != INVALID_SOCKET)
		closesocket(m_socket);
	m_socket = INVALID_SOCKET;
#else
	if (m_socket >= 0)
		close(m_socket);
	m_socket = -1;
#endif
	m_isOpen = false;
}

bool
CUdpSocket::IsOpen() const
{
	return m_isOpen;
}

bool
CUdpSocket::SendTo(const NetAddr &to, const void *data, int32 size) const
{
	if (!m_isOpen || size <= 0)
		return false;

	int sent = sendto(m_socket, (const char *)data, size, 0, (const sockaddr *)&to.storage, to.len);
#ifdef _WIN32
	return sent == size;
#else
	return sent == size;
#endif
}

int32
CUdpSocket::RecvFrom(NetAddr &from, void *outData, int32 outCapacity) const
{
	if (!m_isOpen || outCapacity <= 0)
		return -1;

	from.len = (socklen_t)sizeof(from.storage);
	int received = recvfrom(m_socket, (char *)outData, outCapacity, 0, (sockaddr *)&from.storage, &from.len);

	if (received <= 0) {
#ifdef _WIN32
		int err = WSAGetLastError();
		if (err == WSAEWOULDBLOCK)
			return 0;
#else
		if (errno == EWOULDBLOCK || errno == EAGAIN)
			return 0;
#endif
		return -1;
	}

	return received;
}

bool
CUdpSocket::ParseIPv4(const char *ip, uint16 port, NetAddr &outAddr)
{
	if (ip == nil || ip[0] == '\0')
		return false;

	sockaddr_in addr;
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = htons(port);

#ifdef _WIN32
	addr.sin_addr.s_addr = inet_addr(ip);
	if (addr.sin_addr.s_addr == INADDR_NONE)
		return false;
#else
	if (inet_pton(AF_INET, ip, &addr.sin_addr) != 1)
		return false;
#endif

	memset(&outAddr.storage, 0, sizeof(outAddr.storage));
	memcpy(&outAddr.storage, &addr, sizeof(addr));
	outAddr.len = sizeof(addr);
	return true;
}

