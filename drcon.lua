-- peripherals side config
local monitorName = 'left'
local reactorName = 'draconic_reactor_1'
local fluxgateInName = 'flux_gate_4'
local fluxgateOutName = 'flux_gate_3'

-- monitor 
local monitor = peripheral.wrap(monitorName)
if monitor == nil then
	error("No valid monitor was found")
end
local monX, monY = monitor.getSize()

-- peripherals
local reactor = peripheral.wrap(reactorName)
if reactor == nil then
	error("No valid reactor was found")
end
local fluxgateIn = peripheral.wrap(fluxgateInName)
if fluxgateIn == nil then
	error("No valid input fluxgate was found")
end
local fluxgateOut = peripheral.wrap(fluxgateOutName)
if fluxgateOut == nil then
	error("No valid output fluxgate was found")
end

-- reactor information
local ri = reactor.getReactorInfo()

-- target params
local targetField = 50
local targetSaturation = 50
local increment = 1

-- UTILS
function clear()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()
  monitor.setCursorPos(1,1)
end

function writeLeft(x, y, text, color, bgColor)
  monitor.setTextColor(color or colors.white)
  monitor.setBackgroundColor(bgColor or colors.black)
  monitor.setCursorPos(x, y)
  monitor.write(text)
end

function writeRight(x, y, text, color, bgColor)
  monitor.setTextColor(color or colors.white)
  monitor.setBackgroundColor(bgColor or colors.black)
  monitor.setCursorPos(x - string.len(text) + 1, y)
  monitor.write(text)
end

function getColorForStatus(status)
  if status == 'cold' then
    return colors.lightGray
  elseif status == 'running' then
    return colors.green
  else
    return colors.yellow
  end    
end

function getColorForTemperature(temp)
  if temp > 8000 then
    return colors.red
  elseif temp > 7500 then
    return colors.orange
  elseif temp > 7000 then
    return colors.yellow
  else
    return colors.green
  end
end

function getDiffColor(currentValue, targetValue)
  diff = math.abs(currentValue - targetValue)
  if diff < 0.1 then
    return colors.green
  else
    return colors.yellow
  end
end

-- EVENT
function handleTouch()
  while true do
    event, side, xPos, yPos = os.pullEvent("monitor_touch")
    if xPos == monX - 1 and yPos == 2 then
      break
    end
    if yPos == 7 then
      if xPos >= 34 and xPos <= 35 and targetField > 1 then
        targetField = targetField - 1
      end
      if xPos >= 37 and xPos <= 38 and targetField < 99 then
        targetField = targetField + 1
      end
    end
    if yPos == 8 then
      if xPos >= 34 and xPos <= 35 and targetSaturation > 1 then
        targetSaturation = targetSaturation - 1
      end
      if xPos >= 37 and xPos <= 38 and targetSaturation < 99 then
        targetSaturation = targetSaturation + 1
      end
    end
    if yPos == 11 then
      if xPos >= 34 and xPos <= 35 then
        if increment > 1 and increment <= 10 then
          increment = increment - 1
        elseif increment > 10 and increment <= 50 then
          increment = increment - 5
        elseif increment > 50 then
          increment = increment - 50
        end
      end
      if xPos >= 37 and xPos <= 38 then
        if increment < 10 then
          increment = increment + 1
        elseif increment >= 10 and increment < 50 then
          increment = increment + 5
        elseif increment >= 50 then
          increment = increment + 50
        end
      end
    end
    if xPos >= 29 and xPos <= 38 then 
      if yPos >= 13 and yPos <= 15 then
        if ri.status == 'cold' or ri.status == 'cooling' then
          reactor.chargeReactor()
        elseif ri.status == 'warming_up' and ri.temperature >= 2000 or ri.status == 'stopping' then
          reactor.activateReactor()
        end
      end
      if yPos >= 16 and yPos <= 18 then
        if ri.status == 'warming_up' or ri.status == 'running' then
          reactor.stopReactor()
        end
      end
    end
  end
end

-- MAIN
function getData()
  ri = reactor.getReactorInfo()
end

function updateData()
  if ri.status == 'warming_up' then
    fluxgateIn.setSignalLowFlow(200000)
    fluxgateOut.setSignalLowFlow(0)
  elseif ri.status == 'running' or ri.status == 'stopping' then
    -- shutdown on low fuel
    if ri.fuelConversion / ri.maxFuelConversion > 0.9 then
      reactor.stopReactor()
    end
    -- input gate
    fluxval = ri.fieldDrainRate / (1 - (targetField/100))
    fluxgateIn.setSignalLowFlow(fluxval)
    -- output gate
    local saturation = ri.energySaturation / ri.maxEnergySaturation
    if saturation < targetSaturation / 100 or ri.temperature > 8000 then
      fluxgateOut.setSignalLowFlow(ri.generationRate - increment * 1000)
    elseif saturation > targetSaturation / 100 then
      fluxgateOut.setSignalLowFlow(ri.generationRate + increment * 1000)
    else
      fluxgateOut.setSignalLowFlow(ri.generationRate)
    end
  elseif ri.status == 'cold' or ri.status == 'cooling'then
    fluxgateIn.setSignalLowFlow(0)
    fluxgateOut.setSignalLowFlow(0)
  end
end

function draw()
  clear()
  writeLeft(38, 2, 'X', colors.white, colors.gray)
  writeLeft(7, 2, 'Draconic Reactor Controller')
  writeLeft(3, 4, 'ACTUAL')
  writeLeft(2, 6, 'Temperature')
  writeRight(25, 6, string.format('%.1f', ri.temperature) .. 'C', getColorForTemperature(ri.temperature))
  writeLeft(2, 7, 'Field level')
  if ri.maxFieldStrength == 0 then
    writeRight(25, 7, 'n/a %', colors.red)
  else
    local fieldLevel = ri.fieldStrength / ri.maxFieldStrength * 100
    writeRight(25, 7, string.format('%.1f', fieldLevel) .. '%', getDiffColor(fieldLevel, targetField))
  end
  writeLeft(2, 8, 'Saturation')
  if ri.maxEnergySaturation == 0 then
    writeRight(25, 8, 'n/a %', colors.red)
  else
    local saturation = ri.energySaturation / ri.maxEnergySaturation * 100
    writeRight(25, 8, string.format('%.1f', saturation) .. '%', getDiffColor(saturation, targetSaturation))
  end
  writeLeft(2, 9, 'Fuel level')
  if ri.maxFuelConversion == 0 then
    writeRight(25, 9, 'n/a %', colors.red)
  else
    local fuelLevel = (1 - ri.fuelConversion / ri.maxFuelConversion) * 100
    writeRight(25, 9, string.format('%.1f', fuelLevel) .. '%', colors.green)
  end
  writeLeft(2, 11, 'Power')
  writeRight(19, 11, string.format('%.1f', ri.generationRate / 1000))
  writeLeft(21, 11, 'kRF/t')
  writeLeft(2, 12, 'Field drain')
  writeRight(19, 12, string.format('%.1f', ri.fieldDrainRate / 1000))
  writeLeft(21, 12, 'kRF/t')
  writeLeft(2, 13, 'Fuel drain')
  writeRight(19, 13, string.format('%.0f', ri.fuelConversionRate))
  writeLeft(22, 13, 'nb/t')
  writeLeft(2, 15, 'Input gate')
  writeRight(19, 15, string.format('%.1f', fluxgateIn.getSignalLowFlow() / 1000))
  writeLeft(21, 15, 'kRF/t')
  writeLeft(2, 16, 'Output gate')
  writeRight(19, 16, string.format('%.1f', fluxgateOut.getSignalLowFlow() / 1000))
  writeLeft(21, 16, 'kRF/t')
  writeLeft(2, 18, 'Status')
  writeRight(25, 18, string.upper(ri.status), getColorForStatus(ri.status))  
  
  for y=4,19 do
    writeLeft(27, y, '|')
  end
  writeLeft(30, 4, 'TARGET')
  writeRight(32, 7, tostring(targetField) .. '%')
  writeLeft(34, 7, '<<', colors.white, colors.gray)
  writeLeft(37, 7, '>>', colors.white, colors.gray)
  writeRight(32, 8, tostring(targetSaturation) .. '%')
  writeLeft(34, 8, '<<', colors.white, colors.gray)
  writeLeft(37, 8, '>>', colors.white, colors.gray)
  writeLeft(29, 10, 'Increment')
  writeRight(32, 11, tostring(increment) .. 'k')
  writeLeft(34, 11, '<<', colors.white, colors.gray)
  writeLeft(37, 11, '>>', colors.white, colors.gray)
  if ri.status == 'cold' or ri.status == 'cooling' then
    writeLeft(29, 13, string.rep(' ', 10), colors.white, colors.green)
    writeLeft(29, 14, '  CHARGE  ', colors.white, colors.green)
    writeLeft(29, 15, string.rep(' ', 10), colors.white, colors.green)
  elseif ri.status == 'warming_up' and ri.temperature >= 2000 or ri.status == 'stopping' then
    writeLeft(29, 13, string.rep(' ', 10), colors.white, colors.green)
    writeLeft(29, 14, ' ACTIVATE ', colors.white, colors.green)
    writeLeft(29, 15, string.rep(' ', 10), colors.white, colors.green)
  end
  if ri.status == 'warming_up' then
    writeLeft(29, 16, string.rep(' ', 10), colors.white, colors.orange)
    writeLeft(29, 17, '  CANCEL  ', colors.white, colors.orange)
    writeLeft(29, 18, string.rep(' ', 10), colors.white, colors.orange)
  elseif ri.status == 'running' then
    writeLeft(29, 16, string.rep(' ', 10), colors.white, colors.red)
    writeLeft(29, 17, ' SHUTDOWN ', colors.white, colors.red)
    writeLeft(29, 18, string.rep(' ', 10), colors.white, colors.red)
  end
end

function mainLoop()
  while true do
    getData()
    updateData()
    draw()
    sleep(0.1)
  end
end

print('drcon is running...')
parallel.waitForAny(mainLoop, handleTouch)
print('exiting')
clear()

