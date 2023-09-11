#!/usr/bin/env lua

-- When will the Class be Over?
-- Asked by a HUSTer.
--
-- Uages:
--     wco          通过当前时间计算
--     wco HOUR MIN 通过给出时间计算
--     当环境变量 LANG 为 zh_CN* 时，输出为中文

local time = os.date("*t")

-- 华科夏令时从 5.1 开始 9.30 结束
local isdst = false
if time.month >= 5 and time.month < 10 then
  isdst = true
end

local hour = time.hour
local min = time.min
local sec = nil
local zh_cn = false

local i18n = {}
i18n["%s, class %d, %d min(s) left"] = "%s，第 %d 节课，剩余 %d 分钟"
i18n["%s, class %d is over %d min(s) ago. Time for break now!"] = "%s，第 %d 节课已在 %d 分钟前结束。是时候休息力！"
i18n["Next class will begin in %d min(s)!"] = "下节课将在 %d 分钟后开始！"
i18n["It's %s now."] = "现在时间 %s"
i18n["Too early in the morning!"] = "太早了，还没上课捏！"
i18n["Too late at night!"] = "太晚了，已经没课力！"
i18n["Morning"] = "早上"
i18n["Afternoon"] = "下午"
i18n["Evening"] = "晚上"
i18n["Time for having rest now!"] = "是时候休息力！"
i18n["Most students go for lunch after 11:50, and now it's %d min(s) past 11:50."] = "大部分学生在 11:50 后吃中饭，现在距离 11:50 已经过了 %d 分钟了。"
i18n["Most students go for dinner after 18:00, and now it's %d min(s) past 18:00."] = "大部分学生在 18:00 后吃晚饭，现在距离 18:00 已经过了 %d 分钟了。"
i18n["Most students go for dinner after 17:30, and now it's %d min(s) past 17:30."] = "大部分学生在 17:30 后吃晚饭，现在距离 17:30 已经过了 %d 分钟了。"

local function I(text)
  if zh_cn == true and i18n[text] ~= nil then
    return i18n[text]
  end
  return text
end

-- 时间也可以由以空格分割的时分给出
if arg and arg[1] and arg[2] then
  hour = tonumber(arg[1], 10)
  min = tonumber(arg[2], 10)
else
  sec = time.sec
end

local lang = os.getenv("LANG")
if lang ~= nil then
  if string.find(lang, "zh_CN") ~= nil then
    zh_cn = true
  end
end

--- 计算距离下课的时间
-- 假设传入的参数都是合理的
-- @param part string: 一天的哪个部分 "Morning", "Afternoon" or "Evening"
-- @param start table: 开始的时间，拥有两个字段，时 `hour` 和分 `min`
-- @param class_ends list: 每节课结束时距离开始时间的分钟数
-- @param last integer: 上一节课的序号，默认为 0
-- @return nil
local function calculate(part, start, class_ends, last)
  local offset = (hour - start.hour) * 60 + (min - start.min)
  if last == nil then
    last = 0
  end
  local beyond = nil
  for i, t in ipairs(class_ends) do
    local left = t - offset
    if left > 0 then
      if left < 45 then
        print(string.format(I"%s, class %d, %d min(s) left", part, i + last, left))
      else
        print(string.format(I"%s, class %d is over %d min(s) ago. Time for break now!", part, i - 1 + last, beyond))
        print(string.format(I"Next class will begin in %d min(s)!", left - 45))
      end
      break
    end
    beyond = -left
  end
end

local exact = nil
if sec then
  exact = string.format("%02d:%02d:%02d", hour, min, sec)
else
  exact = string.format("%02d:%02d", hour, min)
end
print(string.format(I"It's %s now.", exact))

if hour < 8 then
  -- 太早
  print(I"Too early in the morning!")
elseif hour > 22 then
  -- 太晚
  print(I"Too late at night!")
elseif (hour > 8 or (hour == 8 and min > 0)) and
    hour < 11 or (hour == 11 and min < 50) then
  -- 早上
  calculate(I"Morning", { hour = 8, min = 0 }, { 45, 100, 175, 230 })
elseif not isdst and (hour > 14 or (hour == 14 and min > 0)) and
  -- 非夏令时下午
    (hour < 17 or (hour == 17 and min < 30)) then
  calculate(I"Afternoon", { hour = 14, min = 0 }, { 45, 95, 160, 210 }, 4)
elseif isdst and (hour > 14 or (hour == 14 and min > 30)) and
  -- 夏令时下午
    hour < 18 then
  calculate(I"Afternoon", { hour = 14, min = 30 }, { 45, 95, 160, 210 }, 4)
elseif not isdst and (hour > 18 or (hour == 18 and min > 30)) and
  -- 非夏令时晚上
    (hour < 21 or (hour == 21 and min < 50)) then
  calculate(I"Evening", { hour = 18, min = 30 }, { 45, 95, 150, 200 }, 8)
elseif isdst and hour >= 19 and
  -- 夏令时晚上
    (hour < 22 or (hour == 22 and min < 20)) then
  calculate(I"Evening", { hour = 19, min = 00 }, { 45, 95, 150, 200 }, 8)
else
  -- 其他时间
  print(I"Time for having rest now!")
  -- 计算距离饭点时间
  if hour <= 14 then
    -- 中午
    local beyond = (hour - 11) * 60 + min - 50
    print(string.format(I"Most students go for lunch after 11:50, and now it's %d min(s) past 11:50.", beyond))
  elseif hour <= 19 then
    -- 下午
    if isdst then
      local beyond = (hour - 18) * 60 + min
      print(string.format(I"Most students go for dinner after 18:00, and now it's %d min(s) past 18:00.", beyond))
    else
      local beyond = (hour - 17) * 60 + min - 30
      print(string.format(I"Most students go for dinner after 17:30, and now it's %d min(s) past 17:30.", beyond))
    end
  end
end
