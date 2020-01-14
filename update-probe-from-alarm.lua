--------------------------------------------------------------------------------
-- script : update-probe-from-alarm.lua
-- author : Dan Gill
-- January 2020
-- version: 1.00
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- desc   : The intention of this script is to automate the process of updating
-- packages. It was originally designed specifically to update the ntevl probe
-- when the alarm "Max. restarts reached for probe 'ntevl' (command = ntevl.exe)
-- " is received.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Version  | Details
--------------------------------------------------------------------------------
-- 1.00     | Initial Version
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set Variables
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Where are your require files?
package.path = package.path .. ";./scripts/includes/?.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- DO NOT EDIT BELOW THIS LINE
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

require ("logging_functions")
require ("error_functions")
require ("table_functions")

local ade = ""
local package_version = ""

if SCRIPT_ARGUMENT ~= nil then
   parms = split(SCRIPT_ARGUMENT)
   for k,v in ipairs (parms) do
      if k == 1 then
         ade = v
      elseif k == 2 then
         package_version = v
      end
   end
end

local str_beg, str_end = string.find (SCRIPT_NAME,".",1,true)

local function deploy_package(robot_addr, ade, pkg_name, pkg_ver, nimid)
   local job = pds.create ()

   pds.putString (job, "jobname", left (SCRIPT_NAME, str_beg-1) .. "-" .. nimid)

   local args = pds.create()
   pds.putString (args, "package", pkg_name)
   pds.putString (args, "version", pkg_ver)
   pds.putString (args, "robot", robot_addr)
    -- Documentation is unclear for update
-- pds.putString (args, "update", fresh_install)
   pds.putTable (job, "probes", args)
   pds.delete(args)

   local job_id, ret = nimbus.request(ade,"submit_job", job)

   pds.delete(job)
end

local function close_alarm(nimid)
   local args = pds.create ()
   pds.putString (args, "nimid", nimid)

   nimbus.request("nas", "close_alarms", args)
   pds.delete(args)
end

local function main()
   local a = alarm.get()

   deploy_package("/" .. a.domain .. "/" .. a.hub .. "/" .. a.robot, ade, \
    a.supp_key, package_version, a.nimid)
   close_alarm(a.nimid)
end

main()
