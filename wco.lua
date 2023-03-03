#!/usr/bin/env lua

-- When will the Class be Over?
-- Asked by a HUSTer.
--
-- Uages:
--     wco          通过当前时间计算
--     wco HOUR MIN 通过给出时间计算

local time = os.date("*t")

local hour = time.hour
local min = time.min

-- 时间也可以由以空格分割的时分给出
if arg and arg[1] and arg[2] then
  hour = tonumber(arg[1], 10)
  min = tonumber(arg[2], 10)
end

--- 计算距离下课的时间
-- 假设传入的参数都是合理的
-- @param part string: 一天的哪个部分 "Morning", "Afternoon" or "Night"
-- @param start table: 开始的时间，拥有两个字段，时 `hour` 和分 `min`
-- @param class_ends list: 每节课结束时距离开始时间的分钟数
-- @param last integer: 上一节课的序号，默认为 0
-- @return nil
local function calculate(part, start, class_ends, last)
  local offset = (hour - start.hour) * 60 + (min - start.min)
  if last == nil then
    last = 0
  end
  for i, t in ipairs(class_ends) do
    local left = t - offset
    if left > 0 then
      if left < 45 then
        print(string.format("%s, class %d, %d min(s) left", part, i + last, left))
      else
        print(string.format("%s, class %d is over. Time for break now!", part,
                            i - 1 + last))
      end
      break
    end
  end
end

if hour < 8 then
  -- 太早
  print("Too early in the morning!")
elseif hour > 22 then
  -- 太晚
  print("Too late at night!")
elseif (hour > 8 or (hour == 8 and min > 0)) and
    hour < 11 or (hour == 11 and min < 50) then
  -- 早上
  calculate("Morning", { hour = 8, min = 0 }, { 45, 100, 175, 230 })
elseif not time.isdst and (hour > 14 or (hour == 14 and min > 0)) and
  -- 非夏令时下午
    (hour < 17 or (hour == 17 and min < 30)) then
  calculate("Afternoon", { hour = 14, min = 0 }, { 45, 95, 160, 210 }, 4)
elseif time.isdst and (hour > 14 or (hour == 14 and min > 30)) and
  -- 夏令时下午
    hour < 18 then
  calculate("Afternoon", { hour = 14, min = 30 }, { 45, 95, 160, 210 }, 4)
elseif not time.isdst and (hour > 18 or (hour == 18 and min > 30)) and
  -- 非夏令时晚上
    (hour < 21 or (hour == 21 and min < 50)) then
  calculate("Night", { hour = 18, min = 30 }, { 45, 95, 150, 200 }, 8)
elseif time.isdst and hour >= 19 and
  -- 夏令时晚上
    (hour < 22 or (hour == 22 and min < 20)) then
  calculate("Night", { hour = 19, min = 00 }, { 45, 95, 150, 200 }, 8)
else
  -- 其他时间
  print("Time for having rest now!")
end
