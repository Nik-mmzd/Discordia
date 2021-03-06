local Snowflake = require('../Snowflake')

local format = string.format

local User, property, method = class('User', Snowflake)
User.__description = "Represents a Discord user."

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

function User:__tostring()
	return format('%s: %s', self.__name, self._username)
end

local defaultAvatars = {
	'6debd47ed13483642cf09e832ed0bc1b',
    '322c936a8c8be1b803cd94861bdfa868',
    'dd4dbc0016779df1378e7812eabaa04d',
    '0e291f67c9274a1abdddeb3fd919cbaa',
	'1cbd08c76f8af6dddce02c5138971129'
}

local function getDefaultAvatar(self)
	return defaultAvatars[self._discriminator % #defaultAvatars + 1]
end

local function getDefaultAvatarUrl(self)
	return format('https://discordapp.com/assets/%s.png', getDefaultAvatar(self))
end

local function getAvatarUrl(self)
	if self._avatar then
		return format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self._id, self._avatar)
	else
		return getDefaultAvatarUrl(self)
	end
end

local function getMentionString(self)
	return format('<@%s>', self._id)
end

local function getMembership(self, guild)
	return guild:getMember(self._id)
end

local function sendMessage(self, ...)
	local id = self._id
	local client = self._parent
	local channel = client._private_channels:find(function(v) return v._recipient._id == id end)
	if not channel then
		local success, data = client._api:createDM({recipient_id = id})
		if success then channel = client._private_channels:new(data) end
	end
	if channel then return channel:sendMessage(...) end
end

local function ban(self, guild, days)
	return guild:banUser(self, days)
end

local function unban(self, guild)
	return guild:unbanUser(self)
end

local function kick(self, guild)
	return guild:kickUser(self)
end

property('avatar', '_avatar', nil, 'string', "Hash representing the user's avatar")
property('avatarUrl', getAvatarUrl, nil, 'string', "URL that points to the user's avatar")
property('defaultAvatar', getDefaultAvatar, nil, 'string', "Hash representing the user's default avatar")
property('defaultAvatarUrl', getDefaultAvatarUrl, nil, 'string', "URL that points to the user's default avatar")
property('mentionString', getMentionString, nil, 'string', "Raw string that is parsed by Discord into a user mention")
property('name', '_username', nil, 'string', "The user's name (alias of username)")
property('username', '_username', nil, 'string', "The user's name (alias of name)")
property('discriminator', '_discriminator', nil, 'string', "The user's 4-digit discriminator")
property('bot', '_bot', function(self) return self._bot or false end, 'boolean', "Whether the user is a bot account")

method('ban', ban, 'guild[, days]', "Bans the user from a guild and optionally deletes their messages from 1-7 days.")
method('unban', unban, 'guild', "Unbans the user from the provided guild.")
method('kick', kick, 'guild', "Kicks the user from the provided guild.")
method('sendMessage', sendMessage, 'content[, mentions, tts, nonce]', "Sends a private message to the user.")
method('getMembership', getMembership, 'guild', "Returns the user's Member object for the provided guild.")

return User
