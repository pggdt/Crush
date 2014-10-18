
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

local SpriteItem = import("app.scenes.SpriteItem")


local ITEM_GAP = 0
local SCORE_START = 30
local SCORE_STEP = 10

function MainScene:ctor()
    cc.ui.UILabel.new({
            UILabelType = 2, text = "Hello, World", size = 36})
        :align(display.CENTER, display.cx+80, display.cy)
        :addTo(self)
        
    display.newSprite("background.png"):pos(display.cx,display.cy):addTo(self)
    display.addSpriteFrames("sushi.plist", "sushi.pvr.ccz")
    
    self.m_level = 1
    self.m_rowLenght = 10
    self.m_colLenght = 6
    self.m_goalScore = 800
    self.m_leftMovements = 10
    self.m_levelScore = 0

    self.m_matrixLeftBottomX = (display.width - SpriteItem.getContentWidth() * self.m_colLenght - (self.m_colLenght - 1) * ITEM_GAP) / 2
    self.m_matrixLeftBottomY = (display.height - SpriteItem.getContentWidth() * self.m_rowLenght - (self.m_rowLenght - 1) * ITEM_GAP) / 2

    -- 创建BatchNode
    self.m_batchNode = display.newBatchNode("sushi.pvr.ccz")
    self:addChild(self.m_batchNode)

    -- init array
    local arraySize = self.m_rowLenght * self.m_colLenght
    self.m_matrix = {}
    self.m_acticves = {}

    -- active score lable
    self.m_labelActiveScore = cc.ui.UILabel.new({
            UILabelType = 2, text = "", size = 36})
    self.m_labelActiveScore:align(display.CENTER, display.cx, display.cy)
    self:addChild(self.m_labelActiveScore)

    local touchLayer = display.newLayer()
    touchLayer:setTouchEnabled(true)
    touchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function (event)
        print(event.name, event.x, event.y)
        if(event.name == "ended") then
            self:touchEndEvent(event.x, event.y)
        else
            return true
        end
    end)
    self:addChild(touchLayer)
    self:initMartix()
end

function MainScene:initMartix()
    for row = 0, self.m_rowLenght-1 do
        for col = 1, self.m_colLenght do
            if (1 == row and 1 == col) then
                self:createAndDropItem(row, col)
            else
                self:createAndDropItem(row, col)
            end
        end
    end
end

function MainScene:createAndDropItem(row, col, imgIndex)
    local newItem = SpriteItem.new(self.m_batchNode, row, col, imgIndex)
    local endPosition = self:positionOfItem(row, col)
    local startPosition = cc.p(endPosition.x, endPosition.y + display.height / 2)
    newItem:setPosition(startPosition)
    local speed = startPosition.y / (2 * display.height)
    newItem:runAction(cc.MoveTo:create(speed, endPosition))
    self.m_matrix[row * self.m_colLenght + col] = newItem
    self.m_batchNode:addChild(newItem)
end

function MainScene:positionOfItem(row, col)
    local x = self.m_matrixLeftBottomX + (SpriteItem.getContentWidth() + ITEM_GAP) * (col-1) + SpriteItem.getContentWidth() / 2
    local y = self.m_matrixLeftBottomY + (SpriteItem.getContentWidth() + ITEM_GAP) * (row) + SpriteItem.getContentWidth() / 2
    return cc.p(x, y)
end

function MainScene:itemOfPoint(point)
    local item = nil
    local rect = cc.rect(0, 0, 0, 0)

    for row = 0, self.m_rowLenght-1 do
        for col = 1, self.m_colLenght do
            item = self.m_matrix[row * self.m_colLenght + col]
            if (item) then
                rect.x = item:getPositionX() - (item:getContentSize().width / 2)
                rect.y = item:getPositionY() - (item:getContentSize().height / 2)
                rect.width = item:getContentWidth()
                rect.height = item:getContentHeight()
                if (cc.rectContainsPoint(rect, point)) then
                    return item
                end
            end
        end
    end
end

function MainScene:touchEndEvent(x,y)

    local item = self:itemOfPoint(cc.p(x,y))
    if (item) then
        if (item:isActive()) then
            -- 1. clean actived items, remove from array, explosion animation, score animation.
            self:removeActivedItems();
            -- 2. reform metrix
            self:dropItems();
            -- 3. check for gameover logic.
--            self:checkGameOver();
        else
            -- 1. clean old actived items
            self:inactiveItems();
            -- 2. active Neighbor all items
            self:activeNeighborItems(item);
        end
    end
end

function MainScene:inactiveItems()
    for _,item in pairs(self.m_acticves) do
        if (item) then
            item:setActive(false)
        end
--        self.m_acticves:removeAllObjects()
        self.m_acticves = nil
        self.m_acticves = {}

        --clean active score display
        self.m_labelActiveScore:setString("")
    end
end

function MainScene:activeNeighborItems(item)
    self.m_activeCount = 0
    local toCheck = nil
    local temp = nil

    local checkList = {}
    table.insert(checkList, item)

    -- before check, active item itself.
    item:setActive(true)
    while (#checkList > 0) do

        toCheck = checkList[1]
        table.remove(checkList, 1)

        -- get and remove the front of list and check its neighbor
        self.m_activeCount = self.m_activeCount + 1
        -- add to activeItems array
        table.insert(self.m_acticves,toCheck)

        print("ToCheck's row, col", toCheck:getRow(), toCheck:getCol())
        -- check left
        if (toCheck:getCol() > 1) then
            temp = self.m_matrix[toCheck:getRow() * self.m_colLenght + toCheck:getCol() - 1]
            print(toCheck:getCol() .. "", temp:getImgIndex() .. "")
            if (false == temp:isActive() and toCheck:getImgIndex() == temp:getImgIndex()) then
                temp:setActive(true)
                -- just avoid double add to checklist, do NOT m_activeCount++ here.
                table.insert(checkList,temp)
            end
        end

        -- check right
        if (toCheck:getCol() < (self.m_colLenght)) then
            temp = self.m_matrix[toCheck:getRow() * self.m_colLenght + toCheck:getCol() + 1]
            if (false == temp:isActive() and toCheck:getImgIndex() == temp:getImgIndex()) then
                temp:setActive(true)-- just avoid double add to checklist, do NOT m_activeCount++ here.
                table.insert(checkList, temp)
            end
        end

        -- check up
        if (toCheck:getRow() > 0) then
            temp = self.m_matrix[(toCheck:getRow() - 1) * self.m_colLenght + toCheck:getCol()]
            if (false == temp:isActive() and toCheck:getImgIndex() == temp:getImgIndex()) then
                temp:setActive(true) -- just avoid double add to checklist, do NOT m_activeCount++ here.
                table.insert(checkList, temp)
            end
        end

        -- check down
        if (toCheck:getRow() < (self.m_rowLenght-1)) then
            temp = self.m_matrix[(toCheck:getRow() + 1) * self.m_colLenght + toCheck:getCol()]
            if (false == temp:isActive() and toCheck:getImgIndex() == temp:getImgIndex()) then
                temp:setActive(true)-- just avoid double add to checklist, do NOT m_activeCount++ here.
                table.insert(checkList, temp)
            end
        end
    end

    if (self.m_activeCount < 2) then
        item:setActive(false)
        self.m_activeCount = 0
--        self.m_acticves:removeAllObjects()
        self.m_acticves = nil
        self.m_acticves = {}
    else
        audio.playSound(GAME_SFX.itemSelect)
        --SimpleAudioEngine:sharedEngine():playEffect("music/itemSelect.mp3")
        self:countAvtices()
        self:displayActiveScore()
    end
end

function MainScene:countAvtices()
    -- scoreOfLast = scoreOfStart + 10 * (m_activeCount - 1)
    -- m_activeScore = (scoreOfStart + scoreOfLast) * number / 2
    self.m_activeScore = (SCORE_START * 2 + SCORE_STEP * (self.m_activeCount - 1)) * self.m_activeCount / 2
end

function MainScene:displayActiveScore()
    self.m_labelActiveScore:setString(string.format("%d 连消 \n得分 %d", self.m_activeCount, self.m_activeScore))
    local x, y = self.m_labelActiveScore:getPosition()
    self.m_labelActiveScore:setColor(cc.c3b(255,0,0))
    self.m_labelActiveScore:runAction(
        transition.sequence({
        cc.MoveTo:create(0.15, cc.p(x, y + 8)),
        cc.MoveTo:create(0.2, cc.p(x,y))
    }))
end

function MainScene:scorePopupEffect(score, pos)
    local tmpStr = score .. ""
    local labelScore = cc.ui.UILabel.new({
            UILabelType = 2, text = tmpStr, size = 20})
    labelScore:align(display.CENTER, pos.x,  pos.y)
    self:addChild(labelScore)
    local move = cc.MoveBy:create(0.8, cc.p(0, 60))
    local fadeOut = cc.FadeOut:create(0.8)
    --local array = CCArray:create()
    --array:addObject(move)
    --array:addObject(fadeOut)
    local action = transition.sequence({
        cc.Spawn:create(cc.MoveBy:create(0.8, cc.p(0, 60)),cc.FadeOut:create(0.8)),
        -- auto remove after all action done.
        cc.CallFunc:create(function() labelScore:removeFromParent() end)
    })

    labelScore:runAction(action)
end

function MainScene:removeActivedItems(minusStep)

    -- if use bom, not play common music effect
    if (minusStep) then
        local musicIndex = self.m_activeCount
        if (musicIndex < 2) then
            musicIndex = 2
        end
        if (musicIndex > 9) then
            musicIndex = 9
        end
        local tmpStr = string.format("music/broken%d", musicIndex)
        --SimpleAudioEngine:sharedEngine():playEffect(tmpStr)
        audio.playSound(GAME_SFX.tmpStr)
    else
        --SimpleAudioEngine:sharedEngine():playEffect("music/effectBom.mp3")
        audio.playSound(GAME_SFX.effectBom)
    end

    local curItemScore = SCORE_START
    for _,value in pairs(self.m_acticves) do
        temp = value
        if (temp) then
            -- remove from the m_matrix
            self.m_matrix[temp:getRow() * self.m_colLenght + temp:getCol()] = nil
            self:scorePopupEffect(curItemScore, cc.p(temp:getPosition()))
--            self:explosiveEffect(temp:getPosition())
            curItemScore = curItemScore + SCORE_STEP
            temp:removeFromParent()
        end
    end

    self.m_acticves = nil
    self.m_acticves = {}

    -- update level score on UI
    self.m_levelScore = self.m_levelScore + self.m_activeScore
    self.m_activeScore = 0
--    local playLayer = self:getParent()
--    playLayer:setProgressValue(self.m_levelScore)

    -- update step on UI
    if (minusStep) then
        self.m_leftMovements = self.m_leftMovements - 1
        playLayer:setStep(self.m_leftMovements)

        -- logic for add WorningLayer
        if (self.m_leftMovements <= 3) then
            local worn = getParent():getChildByTag(TAG_WORNING_LAYER)
            if (not worn) then
                -- TODO:creat and add worning
--                getParent():addChild(WorningLayer:create())
            end
        end
    end

    -- 是否已达过关分数
    if (self.m_leftMovements > 0 and self.m_levelScore >= self.m_goalScore and not self.m_isPlayedPassEffect) then
        self.m_isPlayedPassEffect = true
        -- 等待爆炸结束再--播放
        self:passEffectCallback()
    end

    -- clean active score display
    self.m_labelActiveScore:setString("")
end

function MainScene:passEffectCallback(dt)
    -- 已达过关分数音乐播放&特效
    --SimpleAudioEngine:sharedEngine():playEffect("music/wow.mp3")
    audio.playSound(GAME_SFX.wow)
end

function MainScene:dropItems()
    local colEmptyInfo = {}

    -- 1. drop exist items
    local temp = nil
    -- XXX:count for each rol
    for col = 1, self.m_colLenght do
        local removedItemOfCol = 0
        local newRow = 0
        -- from buttom to top
        for row = 0, self.m_rowLenght-1 do
            temp = self.m_matrix[row * self.m_colLenght + col]
            if temp == nil then
                removedItemOfCol = removedItemOfCol + 1
            else
                if removedItemOfCol > 0 then
                    newRow = row - removedItemOfCol
                    self.m_matrix[newRow * self.m_colLenght + col] = temp
                    temp:setRow(newRow)
                    self.m_matrix[row * self.m_colLenght + col] = nil

                    local startPosition = cc.p(temp:getPosition())
                    local endPosition = self:positionOfItem(newRow, col)
                    local speed = (startPosition.y - endPosition.y) / display.height
                    temp:stopAllActions()-- must stop pre drop action, it a bug for action.
                    temp:runAction(cc.MoveTo:create(speed, endPosition))
                end
            end
        end

        -- record empty info
        colEmptyInfo[col] = removedItemOfCol
    end

    -- 2. create new item and drop down.
    for col = 1, self.m_colLenght do
        for row = self.m_rowLenght - colEmptyInfo[col], self.m_rowLenght - 1 do
            self:createAndDropItem(row, col)
        end
    end
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
