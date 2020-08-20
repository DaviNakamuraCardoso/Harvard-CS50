--========================= Player Class =====================================--

Player = Class()

require 'Animation'

local MOVE_SPEED = 70
local JUMP_VELOCITY = 400
--============================================================================--


function Player:construct(map)
    self.width = 16
    self.height = 20

    self.map = map

    self.x = self.map.tileWidth * 10
    self.y = self.map.tileHeight * (map.mapHeight / 2 - 1) - self.height

    self.texture = love.graphics.newImage('graphics/blue_alien.png')
    self.frames = generateQuads(self.texture, 16, 20)

    self.state = 'idle'
    self.direction = 'right'

    self.dx = 0
    self.dy = 0

    local idle = {
        texture = self.texture,
        frames = {
            self.frames[1]
        },
        interval = 1
    }

    local walking = {
        texture = self.texture,
        frames = {
        self.frames[9], self.frames[10], self.frames[11]
    },
        interval = 0.15
    }

    local jumping = {
        texture = self.texture,
        frames = {
            self.frames[3]
        },
        interval = 0.15
    }

    self.animations = {
        ['idle'] = Animation(idle),
        ['walking'] = Animation(walking),
        ['jumping'] = Animation(jumping)

    }

    self.animation = self.animations['idle']

    self.behaviors = {
        ['idle'] = function(dt)
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            elseif love.keyboard.isDown('a') then
                self.dx = math.floor(-MOVE_SPEED * dt)
                self.animation = self.animations['walking']
                self.direction = 'left'
            elseif love.keyboard.isDown('d') then
                self.dx = math.ceil(MOVE_SPEED * dt)
                self.animation = self.animations['walking']
                self.direction = 'right'
            else
                self.dx = 0
                self.animation = self.animations['idle']
            end
        end,
        ['walking'] = function(dt)
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            elseif love.keyboard.isDown('a') then
                self.dx = math.floor(-MOVE_SPEED * dt)
                self.animation = self.animations['walking']
                self.direction = 'left'

            elseif love.keyboard.isDown('d') then
                self.dx = math.ceil(MOVE_SPEED * dt)
                self.animation = self.animations['walking']
                self.direction = 'right'
            else
                self.dx = 0
                self.animation = self.animations['idle']
            end

            -- Checks right and left for collisions
            self:checkRightCollision()
            self:checkLeftCollision()

            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end

        end,
        ['jumping'] = function(dt)
            if love.keyboard.isDown('a') then
                self.direction = 'left'
                self.dx = math.floor(-MOVE_SPEED * dt)
            elseif love.keyboard.isDown('d') then
                self.direction = 'right'
                self.dx = math.ceil(MOVE_SPEED * dt)

            end
            self.dy = self.dy + self.map.gravity
            -- check if there's a tile directly beneath us
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
                self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

                -- if so, reset velocity and position and change state
                self.dy = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end

            self:checkRightCollision()
            self:checkLeftCollision()

        end
    }
end


function Player:update(dt)
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.x = self.x + self.dx
    self.y = math.ceil(self.y + self.dy * dt)

    -- If jumping, check for collisions with the blocks above
    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
        self.map:tileAt(self.x + self.width - 1, self.y) ~= TILE_EMPTY then
            -- Reset y velocity
            self.dy = 0

            if self.map:tileAt(self.x, self.y).id == JUMP_BLOCK then
                self.map:setTile(math.floor(self.x / self.map.tileWidth) + 1,
                math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
            end

            if self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK then
                self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth)     + 1, math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
            end
        end
    end
end


function Player:render()
    local scaleX = 1
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end
    love.graphics.draw(self.texture, self.animation:getCurrentFrame(),
         math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
     0, scaleX, 1,
    self.width / 2, self.height / 2)

end


function Player:checkLeftCollision()
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then

            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
end

function Player:checkRightCollision()
    if self.dx > 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then

            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end
end
