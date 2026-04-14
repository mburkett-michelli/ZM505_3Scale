--[[
*******************************************************************************

Filename:      ReqWeb.lua
Version:       1.0.0.0
Date:          2016-07-01
Customer:      Avery Weigh-Tronix
Description:
This lua application file provides basic general weighing functionality.

*******************************************************************************
]]

local outSetpoint1 = 0
local outSetpoint2 = 0
local outSetpoint3 = 0
local inSetpoint1  = 0
local inSetpoint2  = 0
local inSetpoint3  = 0

local TTYPE = awtx.fmtPrint.TYPE_WEIGHT

function onCreate()
  local varSetResult11= awtx.fmtPrint.varSet(11, inSetpoint1, "Setpoint 1 Out",TTYPE)
  local varSetResult12= awtx.fmtPrint.varSet(12, inSetpoint2, "Setpoint 2 Out",TTYPE)
  local varSetResult13= awtx.fmtPrint.varSet(13, inSetpoint3, "Setpoint 3 Out",TTYPE)
  local result = awtx.fmtPrint.registerVarChangeReqEvent(luaVarChangeFunc)
  buildVersionString()
  awtx.os.createTimer(updateWeb,300)
 -- awtx.os.registerFtpFileReceivedEvent(FTPtoWeb) 
  awtx.os.registerFtpFileAddedEvent(FTPtoWeb)
  
  webTimerID = awtx.os.createTimer(webTimerCallback, 1000)   
end

function webTimerCallback(webTimerID)
  local varSetResult4= awtx.fmtPrint.varSet(4, inSetpoint3, "Setpoint 3",TTYPE)
  local varSetResult3= awtx.fmtPrint.varSet(3, inSetpoint2, "Setpoint 2",TTYPE)
  local varSetResult2= awtx.fmtPrint.varSet(2, inSetpoint1, "Setpoint 1",TTYPE)
end

function luaVarChangeFunc(scaleNum, slotNum, varValue)
  awtx.display.doBeep()
  if slotNum==11 then 
    inSetpoint1=varValue
    Setpoint1Value=varValue
  elseif slotNum==12 then 
    inSetpoint2=varValue
    Setpoint2Value=varValue
  elseif slotNum==13 then 
    inSetpoint3=varValue
    Setpoint3Value=varValue
  elseif slotNum==95 then             -- app var 95 -PB Tare
    awtx.weight.requestTare(1)
  elseif slotNum == 94 then           -- app var 94  - Print
    awtx.weight.requestPrint(1)   
  elseif  slotNum == 93 then            -- app var 93  - Zero
    awtx.weight.requestZero(1)
  elseif slotNum == 92 then              -- app var 92  - Cycle Units
    awtx.weight.cycleUnits(1)
  elseif slotNum == 91 then            -- app var 91  - Cycle Active Value
    awtx.weight.cycleActiveValue(1)
  end
end



--[[
Description:
  This function creates a delimiter string with setpoint info. The string is stored into an application variable
  read by the web client 
  This function is called by a timer
  
Parameters:
  None
  
Returns:
  None
]]
function updateWeb()
  local activeValueNames= {"Gross","Net","Tare","----"}
  local activeValue = awtx.weight.getActiveValue() +1
  local displayedWeight
  local displayedUnits 
    wt = awtx.weight.getCurrent(1) 
    displayedUnits = wt.unitsStr 
  if activeValue == 1 then 
    displayedWeight = wt.gross 
  elseif activeValue == 2 then 
    displayedWeight = wt.net
  elseif activeValue == 3 then
    displayedWeight = wt.tare
  else
    activeValue = 4
    displayedUnits = "--"
    displayedWeight = 0
  end
     
  if math.abs(displayedWeight) == 0 then 
     displayedWeight = 0 
  end

  local stpt1Stat 
  weightFormat = string.format ("%%.%df",wt.curDigitsRight) 

  local tStr = string.format("%d|%d|%d",inSetpoint1,inSetpoint2,inSetpoint3)
  tStr = tStr .. string.format("|%d|%d|%d",awtx.setpoint.getState(1),awtx.setpoint.getState(2),awtx.setpoint.getState(3))
  tStr = tStr .. string.format("|"..weightFormat.."|%s|%s",displayedWeight,displayedUnits,activeValueNames[activeValue])
  awtx.fmtPrint.varSet(99, tStr, "Web",awtx.fmtPrint.TYPE_STRING)
end

--[[
Description:
  This function is called when a file is added ob the FTP. The file is then copied to the flash drive
  
  
Parameters:
  None
  
Returns:
  None
]]
function FTPtoWeb(fileName)
  local baseFileName = string.sub(fileName,4) 
  local destFile = "C:\\Apps\\WebFiles\\"..baseFileName 
 
  awtx.os.copyFile(fileName, destFile) 
  awtx.os.deleteFile(fileName)
end


--[[
Description:
  This function encodes non-printable characters in an HTML string.
 
Parameters:
  str : string to encode
  
Returns:
  str : encoded string
]]
function urlEncode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
  end
  return str	
end


--[[
Description:
  This function builds an HTML string with ZM version and configuration information.
  This string is stored in an application variable read from the web client.
 
Parameters:
  None
  
Returns:
  None
]]
function buildVersionString()
  local versionString = ""
  local vti = awtx.os.getVersionInfo("*all")
  fw=vti[10]  --firmware
  ap=vti[13]  -- application
  local vt = awtx.hardware.getSystem(1)
  local gc = awtx.weight.getConfig(1)
 
  versionString = string.format("<table> <tr><td>Model</td> <td>%s</td></tr>  \
    <tr><td>Application</td> <td>%s</td></tr> <tr><td> Application Version </td> <td>%s</td></tr>\
    <tr><td>Firmware  </td> <td>%s</td></tr>  \
    <tr><td>Capacity  </td> <td>%d</td></tr>  \
    <tr><td>Division Size</td> <td>%g</td></tr>  \
    <tr><td>Calibration Units  </td> <td>%s</td></tr>  \
    </table> " ,vt.modelStr, ap.desc,ap.version, fw.version,gc.capacity,gc.division,gc.calwtunitStr)
  awtx.fmtPrint.varSet(98, urlEncode(versionString), "Web",awtx.fmtPrint.TYPE_STRING)
  
end

onCreate()