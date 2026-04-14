--[[
*******************************************************************************

Filename:      Application.lua
Version:       1.0.2.0
Firmware:      2.3.0.0 or higher

Date:          2016-07-01
Customer:      Avery Weigh-Tronix
Description:
This lua application file provides basic general weighing functionality.


*******************************************************************************
]]
--create the awtxReq namespace
awtxReq = {}

require("awtxReqConstants")
require("awtxReqVariables")

--Global Memory Sentinel ... Define this in your app to a different value to clear
-- the Variable table out.
MEMORYSENTINEL = "B0_120001072016Q2"         -- APP_Time_Day_Month_Year
MemorySentinel = awtxReq.variables.SavedVariable('MemorySentinel', "0", true)
-- if the memory sentinel has changed clear out the variable tables.
if MemorySentinel.value ~= MEMORYSENTINEL then
    -- Clears everything
    awtx.variables.clearTable()
    MemorySentinel.value = MEMORYSENTINEL
end

system = awtx.hardware.getSystem(1) -- Used to identify current hardware type.
config1= awtx.weight.getConfig(1)   -- Used to get current system configuration information.
config2= awtx.weight.getConfig(2)
config3= awtx.weight.getConfig(3)

wt1 = awtx.weight.getCurrent(1)      -- Used to hold current scale snapshot information.
wt2 = awtx.weight.getCurrent(2)
wt3 = awtx.weight.getCurrent(3)

TarePressed = false 
TSteerWt = 0
TDriveWt = 0
TTrailerWt = 0
TTotalWt = 0
GSteerWt = 0
GDriveWt = 0
GTrailerWt = 0
GTotalWt = 0
NetWt = 0

require("awtxReqAppMenu")         
require("awtxReqScaleKeys")       
require("awtxReqScaleKeysEvents")
require("awtxReqRpnEntry")
require("ReqSetpoint")
require("ReqPresetTare")
require("ReqWeb")
require("awtxReqDisplayMessages")   -- Provides display message support

-- AppName is displayed when escaping from password entry and entering a password of '0'
AppName = "3SCALE"
awtx.display.writeLine(AppName, 2000)
  
function onStart()
  if Setpoint1Value == 0 then  -- Initialize setpoint variables to be accessed by the firmware.
     Setpoint1Value = config1.capacity
  end
  if Setpoint2Value == 0 then
     Setpoint2Value = config1.capacity
  end
  if Setpoint3Value == 0 then
     Setpoint3Value = config1.capacity
  end
  
  awtx.weight.setActiveScale(3)
  awtx.weight.cycleActiveScale()
  
  
end
 
 function awtxReq.keypad.onZeroKeyHold()
   
   awtx.weight.requestZero(1)
   awtx.weight.requestZero(2)
   awtx.weight.requestZero(3)
   
 end
 
function awtxReq.keypad.onPrintKeyDown()
  
  wt1 = awtx.weight.getCurrent(1)  
  wt2 = awtx.weight.getCurrent(2)
  wt3 = awtx.weight.getCurrent(3)
  
  if (wt1.motion == false) and (wt2.motion == false) and (wt3.motion == false) then
        
    SteerWt = wt1.gross
    DriveWt = wt2.gross
    TrailerWt = wt3.gross
  
    TotalWt = SteerWt + DriveWt + TrailerWt
  
    awtx.fmtPrint.varSet(20, TotalWt, "Total Weight", awtx.fmtPrint.TYPE_FLOAT)
    awtx.fmtPrint.varSet(21, SteerWt, "Steer Weight", awtx.fmtPrint.TYPE_FLOAT)
    awtx.fmtPrint.varSet(22, DriveWt, "Drive Weight", awtx.fmtPrint.TYPE_FLOAT)
    awtx.fmtPrint.varSet(23, TrailerWt, "Trailer Weight", awtx.fmtPrint.TYPE_FLOAT)
  
    awtx.printer.printFmt(10)
    
  end
  
end

function awtxReq.keypad.onStartKeyUp()
  -- Default functionality.
  -- Redefine function to change functionality
  
  wt1 = awtx.weight.getCurrent(1)  
  wt2 = awtx.weight.getCurrent(2)
  wt3 = awtx.weight.getCurrent(3)
  
  if (wt1.motion == false) and (wt2.motion == false) and (wt3.motion == false) then
        
    TSteerWt = wt1.gross
    TDriveWt = wt2.gross
    TTrailerWt = wt3.gross
  
    TTotalWt = TSteerWt + TDriveWt + TTrailerWt
  
    awtx.fmtPrint.varSet(34, TTotalWt, "Total Tare Weight", awtx.fmtPrint.TYPE_FLOAT)
    awtx.fmtPrint.varSet(31, TSteerWt, "Steer Tare Weight", awtx.fmtPrint.TYPE_FLOAT)
    awtx.fmtPrint.varSet(32, TDriveWt, "Drive Tare Weight", awtx.fmtPrint.TYPE_FLOAT)
    awtx.fmtPrint.varSet(33, TTrailerWt, "Trailer Tare Weight", awtx.fmtPrint.TYPE_FLOAT)
  
    TarePressed = true
    
    awtx.display.setMode(awtx.display.MODE_MENU)
    awtx.display.writeLine('TARE',2000)
    awtx.display.setMode(awtx.display.MODE_SCALE)
    
  end
  
end

function awtxReq.keypad.onStopKeyUp()
  -- Default functionality.
  -- Redefine function to change functionality
  
  wt1 = awtx.weight.getCurrent(1)  
  wt2 = awtx.weight.getCurrent(2)
  wt3 = awtx.weight.getCurrent(3)
  
  if (wt1.motion == false) and (wt2.motion == false) and (wt3.motion == false) then
     
    if (TarePressed == true) then
     
      GSteerWt = wt1.gross
      GDriveWt = wt2.gross
      GTrailerWt = wt3.gross
    
      GTotalWt = GSteerWt + GDriveWt + GTrailerWt
    
      NetWt = GTotalWt - TTotalWt
      
      awtx.fmtPrint.varSet(38, GTotalWt, "Total Gross Weight", awtx.fmtPrint.TYPE_FLOAT)
      awtx.fmtPrint.varSet(35, GSteerWt, "Steer Gross Weight", awtx.fmtPrint.TYPE_FLOAT)
      awtx.fmtPrint.varSet(36, GDriveWt, "Drive Gross Weight", awtx.fmtPrint.TYPE_FLOAT)
      awtx.fmtPrint.varSet(37, GTrailerWt, "Trailer Gross Weight", awtx.fmtPrint.TYPE_FLOAT)
      awtx.fmtPrint.varSet(40, NetWt, "Total Net Weight", awtx.fmtPrint.TYPE_FLOAT)
      
      TarePressed = false 
      
      awtx.printer.printFmt(12)
   
      awtx.display.setMode(awtx.display.MODE_MENU)
      awtx.display.writeLine('PRINT',2000)
      awtx.display.setMode(awtx.display.MODE_SCALE)
    
    else
      
      awtx.display.setMode(awtx.display.MODE_MENU)
      
      awtx.display.writeLine('EMPTY',1000)
      awtx.display.writeLine('TRUCK',1000)
      awtx.display.writeLine('PRESS',1000)
      awtx.display.writeLine('START',1000)
      
      awtx.display.setMode(awtx.display.MODE_SCALE)
        
    end 
  
  else
    
    awtx.display.setMode(awtx.display.MODE_MENU)
    awtx.display.writeLine('MOTION',2000)
    awtx.display.setMode(awtx.display.MODE_SCALE)
    
  end
  
end

  
--------------------------------------------------------------------------------------------------
  --  Super Menu
  --------------------------------------------------------------------------------------------------
  -- Top level Menu
  TopMenu1 = {text = "Super", key = 1, action = "MENU", variable = "SuperMenu"}
  TopMenu2 = {text = "EXIT",  key = 2, action = "FUNC", callThis = supervisor.SupervisorMenuExit} 
  TopMenu = {TopMenu1, TopMenu2}

  -- These lines are needed to construct the top layer of the Supervisor Menu
  -- As more menus are added through require files, this layer will grow to include them.
  --SuperMenu  = { }

  SuperMenu1 = {text = " TARE  ",  key = 1, action = "MENU", variable = "TareSetupMenu", show = (system.modelStr == "ZM405")}
  SuperMenu2 = {text = " BACK  ",  key = 2, action = "MENU", variable = "TopMenu", subMenu = 1} 
  SuperMenu  = {SuperMenu1, SuperMenu2}

  TareSetupMenu1 = {text = " Edit  ",  key = 1, action = "FUNC", callThis = findTare}
  TareSetupMenu2 = {text = " Print ",  key = 2, action = "FUNC", callThis = printTareList, show = true}
  TareSetupMenu3 = {text = " Reset ",  key = 3, action = "FUNC", callThis = tareReset, show = true}
  TareSetupMenu4 = {text = " BACK  ",  key = 4, action = "MENU", variable = "SuperMenu", subMenu = 1} 
  TareSetupMenu  = {TareSetupMenu1, TareSetupMenu2, TareSetupMenu3, TareSetupMenu4}

  -- Need this to turn the table string names into the table addresses 
  generalMenu = {
    TopMenu = TopMenu,
      SuperMenu = SuperMenu,
        TareSetupMenu = TareSetupMenu
  }

--[[
Description:
  Function override from ReqAppMenu.lua
  This function is called when the Supervisor menu is entered.
Parameters:
  None
  
Returns:
  None
]]--
function appEnterSuperMenu()
  setpoint.disableOutputSetpoints()  -- Disable setpoints before entering supervisor menu.
  supervisor.menuLevel    = TopMenu         -- Set current menu level
  supervisor.menuCircular = generalMenu     -- Set menu address table
end


--[[
Description:
  Function override from ReqAppMenu.lua
  This function is called when the Supervisor menu is exited.
Parameters:
  None
  
Returns:
  None
]]--
function appExitSuperMenu()
    -- This function retrieves the updated values from the setpoint configuration table
    --  and updates the current setpoints with the latest information.
  setpoint.enableOutputSetpoints()
end

onStart()
