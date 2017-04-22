#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public void OnPluginStart() {
	AddTempEntHook("PlayerAnimEvent", PlayerAnimEvent);
}

public Action PlayerAnimEvent(const char[] te_name, const int[] clients, int numClients, float delay) {
	int client = TE_ReadNum("m_iPlayerIndex");
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}

	//if this event already has the sending client in the list of recipients, do nothing
	int clResult[MAXPLAYERS+1];
	for (int i = 0; i < numClients; i++) {
		if (clients[i] == client) {
			return Plugin_Continue;
		}
		//copy the original list to the new recipient list
		clResult[i] = clients[i];
	}

	//if the event wasn't event 0 + data 0, do nothing
	int event = TE_ReadNum("m_iEvent");
	int data = TE_ReadNum("m_nData");
	if (event != 0 || data != 0) {
		return Plugin_Continue;
	}

	//if not a pda, do nothing
	char weapon[64];
	GetClientWeapon(client, weapon, sizeof(weapon));
	if (strncmp(weapon, "tf_weapon_pda_", 14, false) != 0) {
		return Plugin_Continue;
	}

	//resend the event with the sending client added to recipients
	clResult[numClients] = client;
	TE_Start("PlayerAnimEvent");
	TE_WriteNum("m_iPlayerIndex", client);
	TE_WriteNum("m_iEvent", event);
	TE_WriteNum("m_nData", data);
	TE_Send(clResult, numClients+1, delay);

	//don't send the event we just hooked
	return Plugin_Stop;
}