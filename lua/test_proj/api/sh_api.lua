local trans = SHLIB.Net.Trans
local types = SHLIB.Net.Types

-- Player

trans:RegisterType("Player", {
    PlayerID = "ID",
    Name = "String"
})

SHLIB.Net:RegisterRequest("AddPlayer", SHLIB.Net.ConfigAccessLevel, types.String, types.ID)
SHLIB.Net:RegisterRequest("RemovePlayer", SHLIB.Net.ConfigAccessLevel, types.ID, _)
SHLIB.Net:RegisterRequest("GetPlayers", SHLIB.Net.ConfigAccessLevel, _, types.PlayerList)

SHLIB.Net:RegisterAction("OpenPlayerMenu", _)