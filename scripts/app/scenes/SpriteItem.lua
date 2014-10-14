local SpriteItem = class("SpriteItem", function(batchNode, row, col, imageIndex)
    math.newrandomseed()
    imageIndex = imageIndex or math.round(math.random()*1000)%5 + 1
    local item = display.newSprite("#sushi_"  .. imageIndex .. 'n.png')
    item.m_imageIndex, item.m_row, item.m_col = imageIndex, row, col
    item.m_batchNode = batchNode
    item.m_isActive = false
    return item end
)

function SpriteItem:ctor()
end

function SpriteItem:setActive(active)
    self.m_isActive = active

    local frame
    if (active) then
        frame = display.newSpriteFrame("sushi_"  .. self.m_imageIndex .. 'h.png')
    else
        frame = display.newSpriteFrame("sushi_"  .. self.m_imageIndex .. 'n.png')
    end

    self:setDisplayFrame(frame)

    if (active) then
        self:stopAllActions()
        local scaleTo1 = CCScaleTo:create(0.1, 1.1)
        local scaleTo2 = CCScaleTo:create(0.05, 1.0)
        self:runAction(transition.sequence({scaleTo1, scaleTo2}))
    end
end

function SpriteItem:isActive()
    return  self.m_isActive
end

function SpriteItem:getCol()
    return self.m_col
end

function SpriteItem:setCol(col)
    self.m_col = col
end

function SpriteItem:getRow()
    return self.m_row
end

function SpriteItem:setRow(row)
    self.m_row = row
end

function SpriteItem:getImgIndex()
    return self.m_imageIndex
end

function SpriteItem.getContentWidth()
    local itemWidth = 0
    if (0 == itemWidth) then
        local sprite = display.newSprite("#sushi_1n.png")
        itemWidth = sprite:getContentSize().width
    end
    return itemWidth
end

return SpriteItem

