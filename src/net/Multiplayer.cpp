#include "common.h"

#include "Multiplayer.h"
#include "NetEndian.h"
#include "UdpSocket.h"

#include "Timer.h"
#include "World.h"
#include "Ped.h"
#include "Streaming.h"
#include "ModelIndices.h"
#include "General.h"

MultiplayerConfig gMultiplayerConfig;

static const uint32 NET_MAGIC = 0x4D505643; // 'MPVC'
static const uint8 NET_VERSION = 1;

enum eNetMsgType
{
	NETMSG_HELLO = 1,
	NETMSG_WELCOME = 2,
	NETMSG_STATE = 3,
	NETMSG_SNAPSHOT = 4,
};

static uint32
ReadU32(const uint8 *&p, const uint8 *end)
{
	if (p + 4 > end)
		return 0;
	uint32 v;
	memcpy(&v, p, 4);
	p += 4;
	return NetNtohU32(v);
}

static float
ReadF32(const uint8 *&p, const uint8 *end)
{
	if (p + 4 > end)
		return 0.0f;
	uint32 v;
	memcpy(&v, p, 4);
	p += 4;
	return NetNtohF32(v);
}

static void
WriteU32(uint8 *&p, uint32 v)
{
	uint32 n = NetHtonU32(v);
	memcpy(p, &n, 4);
	p += 4;
}

static void
WriteU16(uint8 *&p, uint16 v)
{
	uint16 n = NetHtonU16(v);
	memcpy(p, &n, 2);
	p += 2;
}

static void
WriteU8(uint8 *&p, uint8 v)
{
	*p++ = v;
}

static void
WriteF32(uint8 *&p, float v)
{
	uint32 n = NetHtonF32(v);
	memcpy(p, &n, 4);
	p += 4;
}

struct RemotePlayer
{
	uint32 id;
	CPed *ped;
	uint32 lastSeenMs;
};

static const int32 MAX_REMOTE_PLAYERS = 16;
static RemotePlayer gRemotePlayers[MAX_REMOTE_PLAYERS];

static int32
FindRemoteIndex(uint32 id)
{
	for (int32 i = 0; i < MAX_REMOTE_PLAYERS; i++) {
		if (gRemotePlayers[i].ped && gRemotePlayers[i].id == id)
			return i;
	}
	return -1;
}

static int32
AllocRemoteSlot(uint32 id)
{
	for (int32 i = 0; i < MAX_REMOTE_PLAYERS; i++) {
		if (!gRemotePlayers[i].ped) {
			gRemotePlayers[i].id = id;
			gRemotePlayers[i].ped = nil;
			gRemotePlayers[i].lastSeenMs = 0;
			return i;
		}
	}
	return -1;
}

static CPed*
EnsureRemotePed(uint32 id, const CVector &pos, float heading)
{
	int32 idx = FindRemoteIndex(id);
	if (idx < 0)
		idx = AllocRemoteSlot(id);
	if (idx < 0)
		return nil;

	if (gRemotePlayers[idx].ped)
		return gRemotePlayers[idx].ped;

	const int remoteModel = MI_MALE01;
	CStreaming::RequestModel(remoteModel, STREAMFLAGS_DONT_REMOVE);
	if (!CStreaming::HasModelLoaded(remoteModel))
		return nil;

	CPed *p = new CPed(PEDTYPE_CIVMALE);
	p->SetModelIndex(remoteModel);
	p->SetStatus(STATUS_PLAYER_REMOTE);
	p->bStreamingDontDelete = true;
	p->bUsesCollision = false;
	p->SetIsStatic(true);
	p->bKindaStayInSamePlace = true;
	p->SetPosition(pos);
	p->SetHeading(heading);
	p->GetMatrix().UpdateRW();
	p->UpdateRwFrame();
	CWorld::Add(p);

	gRemotePlayers[idx].ped = p;
	return p;
}

static void
UpdateRemotePed(uint32 id, const CVector &pos, float heading, uint32 nowMs)
{
	CPed *p = EnsureRemotePed(id, pos, heading);
	int32 idx = FindRemoteIndex(id);
	if (idx >= 0)
		gRemotePlayers[idx].lastSeenMs = nowMs;
	if (!p)
		return;

	p->SetPosition(pos);
	p->SetHeading(heading);
	p->GetMatrix().UpdateRW();
	p->UpdateRwFrame();
}

struct ClientSlot
{
	bool active;
	uint32 id;
	uint32 token;
	NetAddr addr;
	uint32 lastHeardMs;
	CVector pos;
	float heading;
};

static const int32 MAX_CLIENTS = 8;
static ClientSlot gClients[MAX_CLIENTS];

static CUdpSocket gSocket;
static bool gStarted;
static bool gIsHost;
static uint32 gLocalId;
static uint32 gClientToken;
static NetAddr gServerAddr;
static uint32 gSeq;
static uint32 gNextHelloMs;
static uint32 gNextStateMs;
static uint32 gNextSnapshotMs;
static uint32 gNextClientId;
static bool gAwaitPortValue;
static bool gAwaitConnectValue;

static void
ResetMultiplayerRuntime()
{
	gSocket.Close();
	gStarted = false;
	gIsHost = false;
	gLocalId = 0;
	gClientToken = 0;
	memset(&gServerAddr, 0, sizeof(gServerAddr));
	gSeq = 1;
	gNextHelloMs = 0;
	gNextStateMs = 0;
	gNextSnapshotMs = 0;
	gNextClientId = 1;

	memset(gClients, 0, sizeof(gClients));
	for (int32 i = 0; i < MAX_REMOTE_PLAYERS; i++) {
		gRemotePlayers[i].id = 0;
		gRemotePlayers[i].ped = nil;
		gRemotePlayers[i].lastSeenMs = 0;
	}
}

static void
WriteHeader(uint8 *&p, uint8 type, uint16 size, uint32 senderId)
{
	WriteU32(p, NET_MAGIC);
	WriteU16(p, size);
	WriteU8(p, NET_VERSION);
	WriteU8(p, type);
	WriteU32(p, gSeq++);
	WriteU32(p, senderId);
}

static bool
ParseHeader(const uint8 *data, int32 size, uint8 &outType, uint32 &outSenderId, const uint8 *&outPayload, const uint8 *&outEnd)
{
	if (size < 16)
		return false;

	const uint8 *p = data;
	const uint8 *end = data + size;

	uint32 magic = ReadU32(p, end);
	if (p + 2 > end)
		return false;
	uint16 rawSize;
	memcpy(&rawSize, p, 2);
	p += 2;
	uint16 msgSize = NetNtohU16(rawSize);

	if (magic != NET_MAGIC)
		return false;
	if (msgSize < 16)
		return false;
	if (msgSize > (uint16)size)
		return false;
	if (p + 2 > end)
		return false;

	uint8 version = *p++;
	uint8 type = *p++;
	if (version != NET_VERSION)
		return false;

	// seq
	(void)ReadU32(p, end);
	outSenderId = ReadU32(p, end);

	outType = type;
	outPayload = p;
	outEnd = data + msgSize;
	return true;
}

static void
SendHello(uint32 nowMs)
{
	uint8 buf[64];
	uint8 *p = buf;
	uint16 size = 16 + 4;
	WriteHeader(p, NETMSG_HELLO, size, 0);
	WriteU32(p, gClientToken);
	gSocket.SendTo(gServerAddr, buf, size);
	gNextHelloMs = nowMs + 500;
}

static void
SendWelcome(const NetAddr &to, uint32 token, uint32 assignedId)
{
	uint8 buf[64];
	uint8 *p = buf;
	uint16 size = 16 + 8;
	WriteHeader(p, NETMSG_WELCOME, size, 0);
	WriteU32(p, token);
	WriteU32(p, assignedId);
	gSocket.SendTo(to, buf, size);
}

static void
SendStateToHost(uint32 nowMs, const CVector &pos, float heading)
{
	uint8 buf[80];
	uint8 *p = buf;
	uint16 size = 16 + 4 + 16;
	WriteHeader(p, NETMSG_STATE, size, gLocalId);
	WriteU32(p, gClientToken);
	WriteF32(p, pos.x);
	WriteF32(p, pos.y);
	WriteF32(p, pos.z);
	WriteF32(p, heading);
	gSocket.SendTo(gServerAddr, buf, size);
	gNextStateMs = nowMs + 50;
}

static void
BroadcastSnapshot(uint32 nowMs, const CVector &hostPos, float hostHeading)
{
	uint8 buf[1024];
	uint8 *p = buf;

	// header + count + entries
	uint8 *headerStart = p;
	p += 16; // will fill later

	uint32 count = 1; // host
	for (int32 i = 0; i < MAX_CLIENTS; i++) {
		if (gClients[i].active)
			count++;
	}

	WriteU32(p, count);

	// host entry (id 0)
	WriteU32(p, 0);
	WriteF32(p, hostPos.x);
	WriteF32(p, hostPos.y);
	WriteF32(p, hostPos.z);
	WriteF32(p, hostHeading);

	for (int32 i = 0; i < MAX_CLIENTS; i++) {
		if (!gClients[i].active)
			continue;
		WriteU32(p, gClients[i].id);
		WriteF32(p, gClients[i].pos.x);
		WriteF32(p, gClients[i].pos.y);
		WriteF32(p, gClients[i].pos.z);
		WriteF32(p, gClients[i].heading);
	}

	uint16 size = (uint16)(p - buf);
	uint8 *hp = headerStart;
	WriteHeader(hp, NETMSG_SNAPSHOT, size, 0);

	for (int32 i = 0; i < MAX_CLIENTS; i++) {
		if (gClients[i].active)
			gSocket.SendTo(gClients[i].addr, buf, size);
	}

	gNextSnapshotMs = nowMs + 50;
}

static int32
FindClientByAddr(const NetAddr &addr)
{
	for (int32 i = 0; i < MAX_CLIENTS; i++) {
		if (!gClients[i].active)
			continue;
		if (gClients[i].addr.len != addr.len)
			continue;
		if (!memcmp(&gClients[i].addr.storage, &addr.storage, addr.len))
			return i;
	}
	return -1;
}

static int32
FindClientById(uint32 id)
{
	for (int32 i = 0; i < MAX_CLIENTS; i++) {
		if (gClients[i].active && gClients[i].id == id)
			return i;
	}
	return -1;
}

static int32
AllocClientSlot()
{
	for (int32 i = 0; i < MAX_CLIENTS; i++) {
		if (!gClients[i].active)
			return i;
	}
	return -1;
}

static void
HostHandleHello(const NetAddr &from, uint32 token, uint32 nowMs)
{
	int32 idx = FindClientByAddr(from);
	if (idx < 0)
		idx = AllocClientSlot();
	if (idx < 0)
		return;

	if (!gClients[idx].active) {
		gClients[idx].active = true;
		gClients[idx].id = gNextClientId++;
		gClients[idx].token = token;
		gClients[idx].addr = from;
		gClients[idx].pos = FindPlayerCoors();
		gClients[idx].heading = 0.0f;
	}

	gClients[idx].lastHeardMs = nowMs;
	SendWelcome(from, token, gClients[idx].id);
}

static void
HostHandleState(uint32 senderId, uint32 token, const CVector &pos, float heading, uint32 nowMs)
{
	int32 idx = FindClientById(senderId);
	if (idx < 0)
		return;
	if (!gClients[idx].active)
		return;
	if (gClients[idx].token != token)
		return;

	gClients[idx].pos = pos;
	gClients[idx].heading = heading;
	gClients[idx].lastHeardMs = nowMs;

	// Host can also visualize clients.
	UpdateRemotePed(senderId, pos, heading, nowMs);
}

static void
ClientHandleWelcome(uint32 token, uint32 assignedId)
{
	if (gLocalId != 0)
		return;
	if (token != gClientToken)
		return;
	gLocalId = assignedId;
}

static void
HandleSnapshot(const uint8 *payload, const uint8 *end, uint32 nowMs)
{
	uint32 count = ReadU32(payload, end);
	for (uint32 i = 0; i < count; i++) {
		uint32 id = ReadU32(payload, end);
		float x = ReadF32(payload, end);
		float y = ReadF32(payload, end);
		float z = ReadF32(payload, end);
		float heading = ReadF32(payload, end);

		if (id == gLocalId)
			continue;
		UpdateRemotePed(id, CVector(x, y, z), heading, nowMs);
	}
}

static void
PumpNetwork(uint32 nowMs)
{
	uint8 buf[1200];
	for (;;) {
		NetAddr from;
		int32 received = gSocket.RecvFrom(from, buf, sizeof(buf));
		if (received <= 0)
			break;

		uint8 type;
		uint32 senderId;
		const uint8 *payload;
		const uint8 *end;
		if (!ParseHeader(buf, received, type, senderId, payload, end))
			continue;

		if (gIsHost) {
			if (type == NETMSG_HELLO) {
				uint32 token = ReadU32(payload, end);
				HostHandleHello(from, token, nowMs);
			} else if (type == NETMSG_STATE) {
				uint32 token = ReadU32(payload, end);
				float x = ReadF32(payload, end);
				float y = ReadF32(payload, end);
				float z = ReadF32(payload, end);
				float heading = ReadF32(payload, end);
				HostHandleState(senderId, token, CVector(x, y, z), heading, nowMs);
			}
		} else {
			if (type == NETMSG_WELCOME) {
				uint32 token = ReadU32(payload, end);
				uint32 assignedId = ReadU32(payload, end);
				ClientHandleWelcome(token, assignedId);
			} else if (type == NETMSG_SNAPSHOT) {
				HandleSnapshot(payload, end, nowMs);
			}
		}
	}
}

static void
EnsureStartedIfNeeded()
{
	if (gStarted)
		return;
	if (gMultiplayerConfig.mode == MP_MODE_NONE)
		return;

	// Only start once we have a player ped.
	if (FindPlayerPed() == nil)
		return;

	ResetMultiplayerRuntime();

	if (gMultiplayerConfig.mode == MP_MODE_HOST) {
		if (!gSocket.Open(gMultiplayerConfig.port))
			return;
		gIsHost = true;
		gLocalId = 0;
		gStarted = true;
		return;
	}

	if (gMultiplayerConfig.mode == MP_MODE_CLIENT) {
		if (gMultiplayerConfig.connectIp[0] == '\0')
			return;
		if (!CUdpSocket::ParseIPv4(gMultiplayerConfig.connectIp, gMultiplayerConfig.port, gServerAddr))
			return;
		if (!gSocket.Open(0))
			return;
		gIsHost = false;
		gLocalId = 0;
		gClientToken = (uint32)CGeneral::GetRandomNumber();
		if (gClientToken == 0)
			gClientToken = 1;
		gNextHelloMs = 0;
		gStarted = true;
		return;
	}
}

bool
MultiplayerHandlePreInitCommandLine(const char *arg)
{
	if (arg == nil)
		return false;

	if (gAwaitPortValue) {
		gAwaitPortValue = false;
		int p = atoi(arg);
		if (p > 0 && p < 65536)
			gMultiplayerConfig.port = (uint16)p;
		return true;
	}

	if (gAwaitConnectValue) {
		gAwaitConnectValue = false;
		strncpy(gMultiplayerConfig.connectIp, arg, sizeof(gMultiplayerConfig.connectIp) - 1);
		gMultiplayerConfig.connectIp[sizeof(gMultiplayerConfig.connectIp) - 1] = '\0';
		gMultiplayerConfig.mode = MP_MODE_CLIENT;
		return true;
	}

	if (!strcmp(arg, "--host")) {
		gMultiplayerConfig.mode = MP_MODE_HOST;
		return true;
	}

	if (!strcmp(arg, "--connect") || !strcmp(arg, "--client")) {
		gAwaitConnectValue = true;
		gMultiplayerConfig.mode = MP_MODE_CLIENT;
		return true;
	}

	if (!strncmp(arg, "--connect=", 10)) {
		strncpy(gMultiplayerConfig.connectIp, arg + 10, sizeof(gMultiplayerConfig.connectIp) - 1);
		gMultiplayerConfig.connectIp[sizeof(gMultiplayerConfig.connectIp) - 1] = '\0';
		gMultiplayerConfig.mode = MP_MODE_CLIENT;
		return true;
	}

	if (!strcmp(arg, "--port")) {
		gAwaitPortValue = true;
		return true;
	}

	if (!strncmp(arg, "--port=", 7)) {
		int p = atoi(arg + 7);
		if (p > 0 && p < 65536)
			gMultiplayerConfig.port = (uint16)p;
		return true;
	}

	return false;
}

void
MultiplayerUpdate()
{
	if (gMultiplayerConfig.mode == MP_MODE_NONE)
		return;

	EnsureStartedIfNeeded();
	if (!gStarted || !gSocket.IsOpen())
		return;

	CPed *player = FindPlayerPed();
	if (!player)
		return;

	uint32 nowMs = CTimer::GetTimeInMilliseconds();
	CVector pos = FindPlayerCoors();
	float heading = player->m_fRotationCur;

	PumpNetwork(nowMs);

	if (gIsHost) {
		// Timeout clients
		for (int32 i = 0; i < MAX_CLIENTS; i++) {
			if (!gClients[i].active)
				continue;
			if (nowMs - gClients[i].lastHeardMs > 5000) {
				gClients[i].active = false;
			}
		}

		if (gNextSnapshotMs == 0 || nowMs >= gNextSnapshotMs)
			BroadcastSnapshot(nowMs, pos, heading);
	} else {
		if (gLocalId == 0) {
			if (gNextHelloMs == 0 || nowMs >= gNextHelloMs)
				SendHello(nowMs);
		} else {
			if (gNextStateMs == 0 || nowMs >= gNextStateMs)
				SendStateToHost(nowMs, pos, heading);
		}
	}
}

