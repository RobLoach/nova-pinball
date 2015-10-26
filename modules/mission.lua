-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.
   
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
   
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see http://www.gnu.org/licenses/.

-----------------------------------------------------------------------

-- Written by Wesley "keyboard monkey" Werner 2015
-- https://github.com/wesleywerner/

local mission = {}
mission.steps = {}
mission.currentIdx = nil
mission.build = nil

function mission:update(dt)
    if (self:current().wait) then
        self:current().wait = self:current().wait - dt
        -- expire the delay
        if (self:current().wait < 0) then
            self:current().wait = nil
            self:testState()
        end
    end
end

function mission:current()
    return self.steps[self.currentIdx]
end

function mission:define(title)
    local step = {title=title, needs={}, has={}}
    table.insert(self.steps, step)
    self.build = step
    return self
end

function mission:start()
    self.currentIdx = 1
    for _, v in pairs(self.steps) do
        print("mission '" .. v.title .. "' needs: ")
        for _, p in pairs(v.needs) do
            print(p)
        end
        if (v.wait) then print("wait delay of " .. v.wait) end
    end
end

function mission:on(signal)
    table.insert(self.build.needs, signal)
    return self
end

function mission:wait(delay)
    self.build.waitDefault = delay
    self.build.wait = delay
    return self
end

function mission:check(signal)
    -- Validate dependencies in a specific order
    local idx = #self:current().has+1
    local max = #self:current().needs
    if (idx > max) then
        print("max dependency reached.")
        return
    end
    if (self:current().needs[idx] == signal) then
        table.insert(self:current().has, signal)
        self:testState()
    end
end

function mission:testState()
    -- This step still has a delay
    if (self:current().wait) then return end
    -- This step has a remaining dependency
    local need = #self:current().needs
    local has = #self:current().has
    if (has ~= need) then return end
    -- Store the step just completed
    local completedTitle = self:current().title
    -- Advance to the next step
    if (self.currentIdx < #self.steps) then
        self.currentIdx = self.currentIdx + 1
    else
        -- Reset the steps
        self.currentIdx = 1
        for _, step in pairs(self.steps) do
            step.has = {}
            if (step.waitDefault) then step.wait = step.waitDefault end
        end
    end
    -- Fire the callback
    if (self.onMissionAdvanced) then self.onMissionAdvanced(completedTitle) end
end

function mission:nextTarget()
    -- This step still has a delay
    if (self:current().wait) then return "wait" end
    local idx = #self:current().has+1
    local max = #self:current().needs
    if (idx > max) then
        --print("max dependency reached.")
        return "NONE"
    else
        return self:current().needs[idx]
    end
end

function mission:skipWait()
    if (self:current().wait) then self:current().wait = 0.1 end
end

return mission
