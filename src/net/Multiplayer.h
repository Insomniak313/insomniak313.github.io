#pragma once

#include "common.h"

struct NetAddr;

enum eMultiplayerMode
{
	MP_MODE_NONE = 0,
	MP_MODE_HOST,
	MP_MODE_CLIENT,
};

struct MultiplayerConfig
{
	eMultiplayerMode mode;
	uint16 port;
	char connectIp[64];

	MultiplayerConfig()
	{
		mode = MP_MODE_NONE;
		port = 7777;
		connectIp[0] = '\0';
	}
};

extern MultiplayerConfig gMultiplayerConfig;

bool MultiplayerHandlePreInitCommandLine(const char *arg);
void MultiplayerUpdate();

