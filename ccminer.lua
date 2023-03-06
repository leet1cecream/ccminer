-- CCMINER by leet1cecream

settings = {
    ["tunnelHuman"] = true,
    ["tunnelSpacing"] = 16,
    ["tunnelMaxWander"] = 8,
    ["autoRefuel"] = true,
    ["autoRefuelLevel"] = 1000,
    ["autoRefuelCoals"] = 64,
    ["modemBroadcast"] = false,
    ["modemSlot"] = 16
}

-- CONSTANTS ==============================================================

local ore_block_ids = {
    "coal",
    "iron",
    "gold",
    "redstone",
    "lapis",
    "diamond",
    "emerald",
    "quartz",
    "thermalfoundation:ore",
    "mekanism:oreblock"
}

-- UTILITY ================================================================

-- calculate the distance between two sets of coordinates
function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt(math.pow(x2-x1, 2) + math.pow(y2-y1, 2) + math.pow(z2-z1, 2))
end

-- check if the turtle has enough fuel to travel to the given block and return home
function checkBlockFuel(block)
    return ((getDistance(currentX, currentY, currentZ, currentX + block.x, currentY + block.y, currentZ + block.z) + getDistance(currentX, currentY, currentZ, homeX, homeY, homeZ)) < turtle.getFuelLevel())
end

-- return number of items in the turtles inventory based on the item name provided
function getItemCount(itemName)
    count = 0
    for i = 1,16 do
        itemDetails = turtle.getItemDetail(i)
        if itemDetails then
            if string.find(itemDetails.name, itemName) then
                count = count + itemDetails.count
            end
        end
    end
    return count
end

function clearInventory()
    for i = 1, 16 do
        itemDetails = turtle.getItemDetail(i)
        if itemDetails then
            if not string.find(itemDetails.name, blockName) and not string.find(itemDetails.name, "peripheral") and not string.find(itemDetails.name, "module") and not string.find(itemDetails.name, "modem") then
                turtle.select(i)
                turtle.drop()
            end
        end
    end
end

function organizeInventory()
    clearInventory()
    for i = 1, 14 do
        for j = i + 1, 15 do
            itemDetails = turtle.getItemDetail(j)
            if itemDetails then
                turtle.select(j)
                turtle.transferTo(i)
            end
        end
    end
end

-- translate the direction string to a numbered direction
function translateDirection(direction)
    if direction == "north" then
        return 1
    elseif direction == "west" then
        return 2
    elseif direction == "south" then
        return 3
    elseif direction == "east" then
        return 4
    else
        error("Invalid direction: " .. direction)
    end
end

-- dig in the specified direction until there is no block left
function digUntilEmpty(direction)
    detected = true
    while detected do
        if direction == "up" then
            if turtle.detectUp() then
                detected = true
                turtle.digUp()
            else
                detected = false
            end
        elseif direction == "down" then
            if turtle.detectDown() then
                detected = true
                turtle.digDown()
            else
                detected = false
            end
        else
            if turtle.detect() then
                detected = true
                turtle.dig()
            else
                detected = false
            end
        end
    end
end

-- MOVEMENT ===============================================================

-- turn the turtle to face the given direction
function turn(direction)
    local numberedDirection = translateDirection(direction)
    local clockwise = (currentDirection - numberedDirection + 4) % 4
    local counterclockwise = (numberedDirection - currentDirection + 4) % 4
    if clockwise <= counterclockwise then
        for i = 1, clockwise do
            turtle.turnRight()
        end
    else
        for i = 1, counterclockwise do
            turtle.turnLeft()
        end
    end
    currentDirection = numberedDirection
end

-- move the turtle in the given direction
function move(direction)
    -- dig the block above for a human to be able to move there
    if settings["tunnelHuman"] then
        digUntilEmpty("up")
    end

    if direction == "up" then
        digUntilEmpty("up")
        turtle.up()
        currentY = currentY + 1
    elseif direction == "down" then
        digUntilEmpty("down")
        turtle.down()
        currentY = currentY - 1
    elseif direction == "north" then
        turn("north")
        digUntilEmpty("")
        turtle.forward()
        currentZ = currentZ - 1
    elseif direction == "south" then
        turn("south")
        digUntilEmpty("")
        turtle.forward()
        currentZ = currentZ + 1
    elseif direction == "west" then
        turn("west")
        digUntilEmpty("")
        turtle.forward()
        currentX = currentX - 1
    elseif direction == "east" then
        turn("east")
        digUntilEmpty("")
        turtle.forward()
        currentX = currentX + 1
    else
        error("Invalid direction: " .. direction)
    end
end

-- move the turtle to the given coordinates
function moveTo(x, y, z)
    -- calculate the distance in x, y, and z directions
    local dx, dy, dz = x - currentX, y - currentY, z - currentZ

    -- move in the x direction
    if dx > 0 then
        for i = 1, dx do
            move("east")
        end
    elseif dx < 0 then
        for i = 1, math.abs(dx) do
            move("west")
        end
    end

    -- move in the y direction
    if dy > 0 then
        for i = 1, dy do
            move("up")
        end
    elseif dy < 0 then
        for i = 1, math.abs(dy) do
            move("down")
        end
    end

    -- move in the z direction
    if dz > 0 then
        for i = 1, dz do
            move("south")
        end
    elseif dz < 0 then
        for i = 1, math.abs(dz) do
            move("north")
        end
    end
end

function mineBlock(block)
    moveTo(currentX + block.x, currentY + block.y, currentZ + block.z)
end

-- MAIN ============================================================

function main()
    while true do
        -- find the nearest block to mine
        found = false
        nearestBlock = nil
        nearestDistance = 99999999
        for _, block in pairs(scanner.scan()) do
            if string.find(block.name, blockName) and currentY + block.y > heightLimit then
                found = true
                distance = getDistance(currentX, currentY, currentZ, currentX + block.x, currentY + block.y, currentZ + block.z)
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestBlock = block
                end
            end
        end
    
        if found then
            if checkBlockFuel(nearestBlock) == false then
                moveTo(homeX, homeY, homeZ)
                error("Ran out of fuel!")
            end
    
            mineBlock(nearestBlock)
        else
            moveTo(currentX, idealHeight, currentZ)
            move("north")
        end
    
        count = 0
        for i = 1,12 do
            itemDetail = turtle.getItemDetail(i)
            if itemDetail then
                if not string.find(itemDetail.name, blockName) then
                    turtle.select(i)
                    turtle.drop()
                else
                    count = count + itemDetail.count
                end
            end
        end
        if count >= blockAmount then
            moveTo(homeX, homeY, homeZ)
            error("Success!")
        end
    end
end

args = {...}
if (#args < 7) then
    print("Usage: ccminer <block> <amount> <height> <x> <y> <z> <direction>")
    error("Invalid parameters")
end

blockName = args[1]
blockAmount = tonumber(args[2])
idealHeight = tonumber(args[3])
homeX = args[4]
homeY = args[5]
homeZ = args[6]

currentX = homeX
currentY = homeY
currentZ = homeZ
currentDirection = translateDirection(args[7])

heightLimit = 6
scanner = peripheral.wrap("left")

main()
