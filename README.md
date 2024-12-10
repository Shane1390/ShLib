# ShLib - A Garry's Mod Net Request Library
ShLib is a library designed to solve the callback hell problem in Garry's Mod

## How it works
ShLib is designed to follow a CRUD-like flow. By defining contracts/endpoints that the client can use to interact with the server and leveraging coroutines, we can avoid manually setting up net message responses from the server and trying to painfully rig those into Derma menus.

ShLib also provides a wrapper for vgui.RegisterPanel, so that your panels can automatically make these requests without any additional overhead. Currently, the list of methods that are wrapped in a coroutine are hardcoded in cl_uiutils.lua

Check the test project for a real example of how ShLib can enrich your workflow and provide real value.

## Example
See the test project for more examples!

### This is the current flow you need to follow to request information from the server

Client
```lua
net.Start("DemoNetStr")
    net.WriteString("test")
net.SendToServer()

net.Receive("DemoNetStr", function()
    local result = net.ReadString()
    print(result)
end)
```

Server
```lua
util.AddNetworkString("DemoNetStr")

net.Receive("DemoNetStr", function(_, ply)
    local result = net.ReadString()

    net.Start("DemoNetStr")
        net.WriteString(result)
    net.Send(ply)
end)
```

### This is that same request but with ShLib:

Client
```lua
local result, str = SHLIB.Client:DemoNetStr("test")
```

Server
```lua
SHLIB.Net:ImplementRequest("DemoNetStr", function(ply, str)
    return true, str
end)
```

## How to use it
### Database
ShLib ships with mysqloo/sqlite support and implements these modules with an interface - so creating another option is not a painful process! To use mysqloo, you'll need to provide details for your MySQL instance in sv_config.lua and make sure UseMySQL is set to true.

There is a hook that fires during the server Initialize process, telling addons that it is time to register your tables. We utilise this hook, because it is only fired _after_ the database connects, example:
```lua
hook.Add("SHLIB_RegisterDatabaseTables", "TestProj::RegisterDatabaseTables", function()
    SHLIB:AddDatabaseTable("SHLIB_Test", [[
        CREATE TABLE IF NOT EXISTS SHLIB_Players (
        PlayerID INT NOT NULL AUTO_INCREMENT,
        Name VARCHAR(64),

        PRIMARY KEY (PlayerID)
    )
    ]])
end)
```

### Types
Types are used to network basic objects, complex objects or lists of either.
Whenever a type is created, a list version is also created, so that there's no additional overhead to send multiple objects. For example, the type 'ID' comes built in, therefore 'IDList' automatically exists. To send an ID, I just need to supply an integer value but to send an IDList, I need to send a numerically keyed, sequential list of integer values.

This is the list of all "basic" types that are currently built-in:
- ID
- UInt32
- UInt16
- UInt8
- UInt4
- Angle
- Bit
- Color
- Float
- Entity
- String
- Vector

And this is an example of how a "complex" type can be created:
```lua
local trans = SHLIB.Net.Trans

trans:RegisterType("Player", {
    PlayerID = "ID",
    Name = "String"
})
```

### API
What I have dubbed the 'API' layer, is the shared space where the client and server are made aware of the ShLib contracts. To create a request, you need to follow this format:
```lua
SHLIB.Net:RegisterRequest("NameOfRequest", "AccessFlag", types.<ArgumentType>, types.<ReturnType>)
```

Below is an example definition for an action:
```lua
SHLIB.Net:RegisterAction("NameOfAction", types.<ArgumentType>)
```

You may be wondering what the difference between an action and a request is:
- **A Request** is the client asking the server to do something. The server can respond with a message or simply just success/failure
- **An Action** is the server _telling_ the client to do something and optionally providing data to supplement the request.

Access flags can be defined in sh_types.lua and just need to follow a string, function pairing. Below is a list of built-in flags, so you could replace "AccessFlag" with All, Admin or SuperAdmin
```lua
trans.Access = {
    All = function() return true end,
    Admin = function(ply) return ply:IsAdmin() end,
    SuperAdmin = function(ply) return ply:IsSuperAdmin() end
}
```

### Controller
Now that we have a request defined, we need to implement it. Each implementation must always return 1 value - the success/failure of the request. If a return type is defined for that request, a return value must also be provided.

Below, we have the implementation from the test project:
```lua
SHLIB.Net:ImplementRequest("AddPlayer", function(ply, name)
    local query = ([[
        INSERT INTO SHLIB_Players (Name)
        VALUES ('%s')
    ]]):format(name)

    return connector:QueryInsert(query)
end)
```

ImplementRequest accepts 2 arguments - the name of the request you're implementing and a function with 2 arguments: the player sending the request and the argument type object.
You can also see that here, the QueryInsert method is being leveraged - this method is only for use in INSERT queries and will return the database ID of the last object you insert with your query.

This is an example of an action implementation:
```lua
SHLIB.Net:ImplementAction("OpenPlayerMenu", function()
    OpenPlayerMenu()
end)
```

### Other built-in functionality
ShLib does have some other general-purpose methods that can be found in the utils folder. There's matrix rotations, a convenient detouring implementation, entity creation and the singleton panels.

Singleton panels are useful, so you don't need to constantly pass around panel references to a "master" panel, you can simply define it as a singleton as such:
```lua
SHLIB:RegisterSingletonPanel(self)
```

And then anywhere in your code, you can access it as such:
```lua
SHLIB:GetSingletonPanel("<PanelClass>")
```