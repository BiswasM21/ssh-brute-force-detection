--[[
SSH Brute Force NSE Script
Brute forces SSH login with various username/password combinations
Author: SSH BFD Project
--]]

description = [[
SSH brute force authentication testing script.

This script attempts to brute force SSH authentication using common
username/password combinations. Use responsibly and only on systems
you have permission to test.

HTTP Example:
  nmap -p 22 --script ssh-brute --script-args userdb=users.txt,passdb=passwords.txt <target>
]]

author = "SSH BFD Project"
license = "Same as Nmap -- See https://nmap.org/book/man-legal.html"
categories = {"intrusive", "brute-force"}

local shortport = require "shortport"
local stdnse = require "stdnse"
local brute = require "brute"
local creds = require "creds"
local ssh1 = require "ssh1"
local ssh2 = require "ssh2"

-- Script arguments
local user_args = stdnse.get_script_args("ssh-brute.userdb")
local pass_args = stdnse.get_script_args("ssh-brute.passdb")

portrule = shortport.port_or_service(22, "ssh")

-- Error handling
local socket_error = brute.new_error

-- Driver class for brute force
Driver = {
  new = function(self, host, port, options)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.host = host
    o.port = port
    o.options = options
    return o
  end,

  connect = function(self)
    self.socket = nmap.new_socket()
    self.socket:set_timeout(self.options.timeout)
    local status, err = self.socket:connect(self.host, self.port)
    if not status then
      return false, "Failed to connect: " .. err
    end

    -- Perform SSH handshake
    local banner
    status, banner = self.socket:receive_lines(1)
    if not status then
      return false, "Failed to receive SSH banner"
    end

    self.socket:send("SSH-2.0-Nmap-NSE\r\n")

    return true
  end,

  login = function(self, username, password)
    local socket = self.socket

    -- Try SSHv2 authentication
    local userauth_request = string.format(
      "SSH-2.0-%s\r\n",
      "nmap-ssh-brute"
    )

    socket:send(userauth_request)

    -- Read server identification
    local status, server_ident = socket:receive_lines(1)
    if not status then
      return false, "Failed to receive server identification"
    end

    -- Read key exchange initialization
    local status, kex_init = socket:receive_lines(1)
    if not status then
      return false, "Failed to receive key exchange init"
    end

    -- Try password authentication
    local auth_packet = string.format(
      "USERAUTH_REQUEST:%s:%s:password",
      username,
      password
    )

    socket:send(auth_packet)

    -- Read response
    local status, response = socket:receive_lines(1)
    if not status then
      return false, "Authentication failed (timeout)"
    end

    if response:match("AUTH_SUCCESS") or response:match("AUTHENTICATED") then
      return true, "Login successful"
    else
      return false, "Authentication failed"
    end

    socket:close()
    return false, "Unexpected response"
  end,

  disconnect = function(self)
    self.socket:close()
  end
}

-- Alternative: use ssh2 library
Driver2 = {
  new = function(self, host, port, options)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.host = host
    o.port = port
    o.options = options
    return o
  end,

  connect = function(self)
    self.socket = nmap.new_socket()
    self.socket:set_timeout(self.options.timeout)
    local status, err = self.socket:connect(self.host, self.port)
    if not status then
      return false, "Failed to connect: " .. err
    end
    return true
  end,

  login = function(self, username, password)
    local status, error = ssh2.userauth_password(self.socket, username, password)
    if status then
      return true, creds.State.VALID
    else
      return false, error or "Authentication failed"
    end
  end,

  disconnect = function(self)
    self.socket:close()
  end
}

-- Alternative: use ssh1 library
Driver1 = {
  new = function(self, host, port, options)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.host = host
    o.port = port
    o.options = options
    return o
  end,

  connect = function(self)
    self.socket = nmap.new_socket()
    self.socket:set_timeout(self.options.timeout)
    local status, err = self.socket:connect(self.host, self.port)
    if not status then
      return false, "Failed to connect: " .. err
    end
    return true
  end,

  login = function(self, username, password)
    local status, error = ssh1.userauth_password(self.socket, username, password)
    if status then
      return true, creds.State.VALID
    else
      return false, error or "Authentication failed"
    end
  end,

  disconnect = function(self)
    self.socket:close()
  end
}

-- Main action
action = function(host, port)
  -- Check if SSH is available
  if not shortport.port_or_service(22, "ssh")(host, port) then
    return
  end

  -- Try to detect SSH version
  local socket = nmap.new_socket()
  socket:set_timeout(5000)

  local status, err = socket:connect(host, port)
  if not status then
    stdnse.debug1("Failed to connect: %s", err)
    return
  end

  local status, banner = socket:receive_lines(1)
  socket:close()

  if not status then
    return
  end

  -- Parse SSH version
  local version
  if banner:match("SSH-2%.%d") then
    version = 2
  elseif banner:match("SSH-1%.%d") then
    version = 1
  else
    stdnse.debug1("Unknown SSH version in banner: %s", banner)
    return
  end

  -- Use appropriate driver
  local driver
  if version == 2 then
    driver = Driver2
  else
    driver = Driver1
  end

  -- Attempt brute force
  local result = brute.force(driver, {
    host = host,
    port = port,
    timeout = 10000
  })

  return result
end
