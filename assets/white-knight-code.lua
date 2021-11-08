-- Pico-8 system functions

function _init()
    goto_main_menu(true)
end

function _update60()
        if game_state == MAIN_MENU then
            game_init = false
            update_main_menu()
    elseif game_state == INSTRUCTIONS then
            await_return_to_main_menu()
    elseif game_state == CREDITS then
            await_return_to_main_menu()
    elseif game_state == GAME then
            update_gameplay()
    elseif game_state == GAME_OVER_LOSE then
            update_gameover_lost()
    elseif game_state == GAME_OVER_WIN then
            update_gameover_won()
        end
end

function _draw()
        cls()
        palt(0, false)
        palt(9, true)
        if game_state == MAIN_MENU then
            draw_main_menu()
    elseif game_state == INSTRUCTIONS then
            draw_instruction_text()
    elseif game_state == CREDITS then
            draw_credits()
    elseif game_state == GAME then
            draw_gameplay()
    elseif game_state == GAME_OVER_LOSE then
            draw_gameover_lost()
    elseif game_state == GAME_OVER_WIN then
            draw_gameover_won()
        end

        pal()
end



--------------- globals ---------------

-- App states
MAIN_MENU = 0
GAME = 1
INSTRUCTIONS = 2
CREDITS = 3
GAME_OVER_LOSE = 4
GAME_OVER_WIN = 5

-- Main/sub menus
menu_index = 1
menu_hint_return = "🅾️/❎ to go back"
menu_items = {
    "start game",
    "instructions",
    "credits"
}

instructions_text = { 
    "use the arrow keys to move",
    "the princess. walk over keys",
    "and health to pick them up.",
    "sir chad the hero will move",
    "on his own and defeat the",
    "princess' enemies automatically",
    "however sir chad will",
    "prioritize loot over everything",
    "...even the princess' life!",
    "",
    "stay alive and escape!"
}



-- Game over screen (won)
princess_rnd_timer = rnd(150) + 30
knight_rnd_timer = rnd(150) + 30
hflip = false
twitch = false
line_timer = 0



-- Game over screen (lost) globals
game_over_menu_items = {
    "retry",
    "quit",
}



 -- Gameplay globals 
 game_intro_text = {
     "our story so far...",
     "sir chad the hero has made it",
     "to the dungeon where the",
     "beautiful princess daffodil",
     "was taken prisoner.",
     "",
     "after the passage closed",
     "behind him, the two must escape",
     "another way...",
     "",
     "which is great!",
     "because there are still chests",
     "that need looting!"
 }

g_entities= { }
g_tiles = { }
dpadx,dpady=0,0
btnz, btnx= false, false
princess = nil
hero = nil
room_x = 0
room_y = 0
play_start_time = 0
play_time = 0
show_intro = true
secret_key_spawned = false



--------------- Game state handlers ---------------

function goto_main_menu()
    game_state = MAIN_MENU
    menu_index = 1
    spawn_main_menu_entities()
    music(14, 1 << 3)
end

function goto_gameplay()
    init_gameplay()
    game_state = GAME
end

function goto_game_over_won()
    line_timer = 0
    camera()
    music(13, 1 << 3)
    game_state = GAME_OVER_WIN
end

function goto_game_over_lost()
    music(09, 1 << 3)
    menu_index = 1
    game_state = GAME_OVER_LOSE
end

function draw_title_logo()
    for i = 0, 11 do
        spr(100 + i, 16 + 8 * i, 19)
        spr(116 + i, 16 + 8 * i, 27)
    end
end

function draw_dungeon_background()
    for x = 0, 15 do
        for y = 0, 15 do
            spr(mget(x, y + 16), x * 8, y * 8)
        end
    end
end

function spawn_main_menu_entities()
    g_entities={}
    princess = nil
    hero = nil
    local xo =  rnd() < 0.5 and 8 or 1
    for x=1, 5 do
        for y=1, 3 do
            local slime = EntityTypes:spawn(5, (x+xo) * 8, (y + 20) * 8)
            slime.active = true
        end
    end
    xo = xo > 1 and 1 or 9
    hero = EntityTypes:spawn(1, (2 + xo) * 8, 22 * 8)
    hero.active = true
    hero.perception = 175
end

function update_main_menu()
    if #g_entities == 1 then
        hero:move_to_point(9*8, 6.5*8 + 16*8, 0.5)
        local cx, cy = hero:centroid()
        if cx == 9*8 and cy == (6.5*8 + 16*8) then
            local chest = EntityTypes:spawn(7, 7*8, 6*8 + 16*8)
            chest.active = true
        end
    end
    
    for e in all(g_entities) do
        e:update()
    end

    if btnp(4) or btnp(5) then
        if menu_index == GAME then
            goto_gameplay()
        else
            game_state = menu_index
        end
        sfx(1)
        return
    end

    local i = menu_index
    if btnp(2) then
        menu_index -= 1
    end
    if btnp(3) then
        menu_index += 1
    end
    menu_index = mid(1, menu_index, #menu_items)
    if i ~= menu_index then
        sfx(0,1)
    end
end

function draw_main_menu()
    map(0,16)
    camera(0,128)
    for e in all(g_entities) do
        e:draw()
        if e.message then
            if e.message_time > 0 then
                local xo = (#(e.message) / 2 * 3)
                local yo = 6
                rectfill(e.x - xo + 3, e.y - yo - 1, e.x - xo + 3 + (#(e.message) * 4), e.y - yo + 5, 0)
                print(e.message, e.x - xo + 4, e.y - yo, 7)
                e.message_time -= 1
            end
        end
        e:late_update()
    end    
    
    for i=#g_entities, 1, -1 do
        if g_entities[i].removed then
            deli(g_entities, i)
        end
    end

    camera()
    draw_title_logo()

    for i = 1, #menu_items do
        local str = menu_items[i]
        if i == menu_index then
            str = "[" .. str .. "]"
        end
        print_center(str, 64, 71 + (i - 1) * 8)
    end
    print_center("⬆️⬇️ + 🅾️/❎ to select   ", 63, 121)
end

function draw_credits()
    draw_dungeon_background()
    draw_title_logo()
    print_center("credits:", 63, 46)
    print_center("program: z", 63, 60)
    print_center("ART AND MUSIC:", 63, 74)
    print_center("t.l. langham", 63, 82)
    print_center("made with pico-8", 63, 104)
    print_center(menu_hint_return, 63, 121)
end

function await_return_to_main_menu()
    if btnp(4) or btnp(5) then
        game_state = MAIN_MENU
        spawn_main_menu_entities()
        sfx(1)
    end
end

function draw_instruction_text()
    cls()
    for i = 1, #instructions_text do
        print_center(instructions_text[i], 63, 12 + 8 * (i - 1))
    end
    print_center(menu_hint_return, 63, 121)
end

function update_gameover_won()
    if btnp(4) or btnp(5) then
        goto_main_menu()
    end
end

function draw_gameover_won()
    cls(12)
    map(0, 48)
    draw_title_logo()

    if knight_rnd_timer < 0 then
        knight_rnd_timer = rnd(150) + 30
        twitch = (not twitch)
    end

    knight_rnd_timer -= 1

    if princess_rnd_timer < 0 then
        princess_rnd_timer = rnd(150) + 30
        hflip = (not hflip)
    end
    princess_rnd_timer -= 1

    spr(3, 40, 80, 1, 1, hflip)
    spr(twitch and 1 or 16, 56, 80)
    spr(7, 64, 80)
    spr(7, 72, 80)
    spr(7, 68, 76)

    print_center("★conglaturatoins★", 63, 42)
    if(line_timer > 60)  print_center("mighty not-hero of the land!", 63, 50)
    if(line_timer > 120)  print_center("you have make a succeed!", 63, 58)

    local time = flr(play_time)
    local str = "time: " .. time_str(time)
    if(line_timer > 180) print_center(str, 63, 66, 10)

    line_timer+=1
end

function update_gameover_lost()
    if btnp(4) or btnp(5) then
        sfx(1)
        if menu_index == 1 then
            goto_gameplay()
        else
            goto_main_menu()
        end
        return
    end
    local i = menu_index
    if btnp(2) then
        menu_index -= 1
    end
    if btnp(3) then
        menu_index += 1
    end
    menu_index = mid(1, menu_index, 2)
    if i ~= menu_index then
        sfx(00)
    end
end

function draw_gameover_lost()
    camera()
    print_center("game over", 63, 48)
    spr(36, 59, 56)
    for i = 1, 2 do
        local str = game_over_menu_items[i]
        if i == (menu_index) then
            str = "[" .. str .. "]"
        end
        print_center(str, 63, 64 + 8*i)
    end
end

function draw_gameplay_intro()
    cls()
    for i = 1, #game_intro_text do
        print_center(game_intro_text[i], 63, 12 + 8 * (i - 1))
    end
end

function init_gameplay()
    g_entities={}
    dpadx,dpady=0,0
    btnz, btnx= false, false
    princess = nil
    hero = nil
    room_x = 0
    room_y = 0
    play_start_time = 0
    play_time = 0
    show_intro = true
    load_level()
    hero.active = true
    princess.active = true
    music(0, 1 << 3)
end

function update_gameplay()
    
    if show_intro then
        for i = 0, 5 do
            if btnp(i) then
                show_intro = false
            end
        end
        if not show_intro then
            play_start_time = t()
        end
        return
    end
    
    play_time = t() - play_start_time

    if princess and (not princess:is_alive()) then
        music(-1)  
        if princess.state_time > 180 then
            goto_game_over_lost()
            return
        end
    end

    local x = princess.x
    local y = princess.y

    local new_room_x, new_room_y = (x \ 128), (y \ 128)
    if new_room_x ~= room_x or new_room_y ~= room_y then
        load_room(new_room_x, new_room_y)
        room_x, room_y = new_room_x, new_room_y
        -- entered the final room
        if new_roomx == 4 and new_roomy == 0 then
            hero:force_say("let's gooooo!")
            princess:force_say("omg...")
        end
    end
    local nn = 0
    if room_x == 4 and room_y == 0 then
        local trigger_secret_key_spawn = true
        for e in all(g_entities) do
            if e.active and not e.removed and (e.id == 5 or e.id == 26) then
                trigger_secret_key_spawn  = false
                break
            end
        end

        if trigger_secret_key_spawn and not secret_key_spawned then
            princess:force_say("a secret key!")
            secret_key_spawned = true
            EntityTypes:spawn(13 , 71 * 8, 9 * 8).active = true
            EntityTypes:spawn(14 , 71 * 8, 8 * 8).active = true
            sfx(21)
        end
    end
 
    local tx, ty = princess.x, princess.y
    tx \= 8
    ty \= 8
    if tx == 72 and ty == 0 then
        goto_game_over_won()
        return
    end

    if princess:is_alive() then
        dpadx, dpady = poll_dpad()
        btnz, btnx = poll_btns()

        local s = dpadx*dpadx + dpady*dpady
        if s ~= 0 then
            local ax, ay = 0.5*dpadx, 0.5*dpady
            local my = princess:moveby_y(ay)
            local mx = princess:moveby_x(ax)
        end
    end
    for obj in all(g_entities) do
        if obj.active then
            obj:update()
        end
    end
end

function draw_gameplay()
    cls(13)
    map()    
    camera()
    draw_hud()
    camera(room_x * 128, room_y * 128)
    sort_draw_order()
    pal()
    palt(0, false)
    palt(9, true)
    for obj in all(g_entities) do
        if obj.active then
            obj:draw()
            if obj.message then
                if obj.message_time > 0 then
                    local xo = (#(obj.message) / 2 * 3)
                    local yo = 6
                    rectfill(obj.x - xo + 3, obj.y - yo - 1, obj.x - xo + 3 + (#(obj.message) * 4), obj.y - yo + 5, 0)
                    print(obj.message, obj.x - xo + 4, obj.y - yo, 7)
                    obj.message_time -= 1
                end
            end
        -- Collision / centroid visualization
        -- rect(obj.x + obj.solid_x, obj.y + obj.solid_y, obj.x + obj.solid_x + obj.solid_w, obj.y + obj.solid_y + obj.solid_h, 7)
        -- local cx, cy = obj:centroid()
        pset(cx, cy, 8)
        obj:late_update()
        end
    end

    -- local cx, cy = princess:centroid()
    -- pset(cx, cy, 10)
    -- local cx, cy = princess:bottom()
    -- pset(cx, cy, 8)
    -- local x, y = princess:tile_pos()
    -- rect(x*8, y*8,(x+1)*8,(y+1)*8,8)
    -- x, y = princess:prev_tile_pos()
    -- rect(x*8, y*8,(x+1)*8,(y+1)*8,7)
    
    -- Path debugging / visualization
    -- for wp in all(hero.path) do
    --     rect(wp.x*8, wp.y*8, wp.x*8+8, wp.y*8+8)
    --     pset(wp.x*8 + 4, wp.y*8 + 4, 8)
    -- end
    -- if hero.path then
    --     for i=2, #(hero.path) do
    --         local p1= hero.path[i]
    --         local p2= hero.path[i-1]
    --         line(p1.x*8+4, p1.y*8+4, p2.x*8+4, p2.y*8+4)
    --     end
    -- end

    for i=#g_entities, 1, -1 do
        if g_entities[i].removed then
            deli(g_entities, i)
        end
    end

    if show_intro then
        camera()
        draw_gameplay_intro()
    end
end

function draw_hud()
    if not princess then return end
    for i = 1, princess.hpmax do
        spr((i - 1) < (princess.hpmax - princess.damage) and 14 or 30, 8 * (i - 1), 119)
    end
    for i = 1, princess.held_keys do
        spr(13 or 50, princess.hpmax * 8 + (i - 1) * 8, 119)
    end

    local time = flr(play_time)
    local str = "⧗" .. time_str(time)
    local x = 124 - #str * 4
    local y = 126 - 4

    print(str, x + 1, y + 1, 1)
    print(str, x + 1, y + 0, 1)
    print(str, x, y, 7)
end

function time_str(time_sec)
    local m = time_sec \ 60
    local s = time_sec % 60
    return (m < 10 and "0"..m or m)..":".. (s < 10 and "0"..s or s)
end

function sort_draw_order()
    for i=1, #g_entities do
        local j = i
        while j > 1 and g_entities[j - 1].y > g_entities[j].y do
            g_entities[j], g_entities[j - 1] = g_entities[j - 1], g_entities[j]
            j = j - 1
        end
    end
end

function load_level()
    -- reloads map data from cart
    reload(0x2000, 0x2000, 0x1000)
    for x=0, 127 do
        for y=0, 127 do
            local id = mget(x, y);
            local obj = EntityTypes:spawn(id, x*8, y*8)
            if obj then
                --replace the embedded object sprite with the tileset's "floor" filler sprite
                mset(x, y, 64)  
                if (id == 1) hero = obj
                if (id == 3) princess = obj
                obj.active = (x < 16 and y < 16)
                obj:init()
            end
            local tile = TileTypes:spawn(id, x, y)
            if tile then
                tile:on_init()
            end
        end
    end
end

function load_room(rx, ry)
    for e in all(g_entities) do
        if e ~= hero and e ~= princess then
            local erx, ery = e:room_pos()
            if rx == erx and ry == ery then
                e.active = true
            else
                e.active = false
            end
        end
    end
end

function set_tile(x, y, id)
    TileTypes:spawn(id, x, y)
    mset(x, y, id)
end

function get_tile(x, y)
    return g_tiles[x + y * 128]
end



--------------- Tile object system ---------------

-- "Class" declaration
TileTypes = { }
function TileTypes:declare(id)
    local prototype = { }
    prototype.__index = prototype
    setmetatable(prototype, prototype)

    -- Properties
    prototype.sprite = id

    -- "Virtual" methods
    prototype.on_init = function(self) end
    prototype.on_enter = function(self, entity) end
    prototype.on_stand = function(self, entity) end
    prototype.on_leave = function(self, entity) end
    TileTypes[id] = prototype
    return prototype
end

-- Instantiation
function TileTypes:spawn(id, tx, ty)
    local prototype = self[id]
    if prototype then
        local instance = setmetatable({ }, prototype)
        instance.id = id
        instance.tx = tx
        instance.ty = ty
        g_tiles[tx + ty * 128] = instance
        return instance
    end
    return nil
end



--------------- Concrete tile types ---------------

-- Spike floor
SpikeFloor = TileTypes:declare(80)
function SpikeFloor:on_stand(entity)
    if entity == princess and entity.state ~= EntityStates.Die then
        entity:goto_state(EntityStates.HurtBySpikes)
    end
    if entity == hero then
        hero:say(rnd(Knight.spike_msgs))
    end
end

-- Spike floor aliases
SpikeFloor2 = TileTypes:declare(96)
SpikeFloor2.on_stand = SpikeFloor.on_stand

SpikeFloor3 = TileTypes:declare(97)
SpikeFloor3.on_stand = SpikeFloor.on_stand

SpikeFloor4 = TileTypes:declare(98)
SpikeFloor4.on_stand = SpikeFloor.on_stand

SpikeFloor5 = TileTypes:declare(112)
SpikeFloor5.on_stand = SpikeFloor.on_stand

SpikeFloor6 = TileTypes:declare(113)
SpikeFloor6.on_stand = SpikeFloor.on_stand

SpikeFloor7 = TileTypes:declare(114)
SpikeFloor7.on_stand = SpikeFloor.on_stand

SpikeFloor8 = TileTypes:declare(115)
SpikeFloor8.on_stand = SpikeFloor.on_stand


CrackedFloor = TileTypes:declare(81)
CrackedFloor.strength = 60
function CrackedFloor:on_stand(entity)
    if entity ~= princess and entity ~= hero then return end
    if self.strength % 30 == 0 then sfx(5) end
    self.strength -= 1
    
    if self.strength <= 0 then
        set_tile(self.tx, self.ty, 82)
    end
    if entity == princess then
        princess:say(rnd(Princess.crack_msgs))
    end

end

PitfallFloor = TileTypes:declare(82)
function PitfallFloor:on_enter(entity)
    entity:goto_state(EntityStates.Fall)
end

function PitfallFloor:on_stand(entity)
    entity:goto_state(EntityStates.Fall)
end



--------------- Entity object system ---------------

-- "Class" declaraion
EntityTypes = { }
function EntityTypes:declare(id)
    local prototype = Entity:new()
    prototype.sprite = id
    EntityTypes[id] = prototype
    return prototype
end

-- Instantiation
function EntityTypes:spawn(id, x, y)
    local prototype = self[id]
    if prototype then
        local instance = setmetatable({ }, prototype)
        instance.id = id
        instance.x = x
        instance.xprev = x
        instance.y = y
        instance.yprev = y
        instance.tx, instance.ty = x \ 8, y \ 8
        instance.tx_prev, instance.ty_prev  = x \ 8, y \ 8
        instance = add(g_entities, instance)
        return instance
    end
    return nil
end

EntityStates = {
    Respawn = 99,
    Default = 0,
    Attack = 1,
    HurtByEnemy = 2,
    Die = 3,
    Fall = 4,
    HurtBySpikes = 5,
}

-- Base class
Entity = {}
Entity.__index=Entity
Entity.sprite=0
Entity.x=0
Entity.y=0
Entity.xprev=0
Entity.yprev=0
Entity.tx = 0
Entity.ty = 0
Entity.tx_prev = 0
Entity.ty_prev = 0
Entity.xf=0
Entity.yf=0
Entity.vx=0
Entity.vy=0
Entity.solid_x=0
Entity.solid_y=0
Entity.solid_w=8
Entity.solid_h=8
Entity.travelled = 0
Entity.is_enemy = false
Entity.removed = false
Entity.active = false
Entity.state = 0
Entity.state_prev = 0
Entity.state_time = 0
Entity.message_interval = 60 * 2
Entity.message_cd = 0

function Entity:new()
    local instance = { }
    instance.__index=instance
    return setmetatable(instance, Entity)
end

function Entity:draw() 
    spr(self.sprite, self.x, self.y)
end

-- "Virtual" methods
function Entity:init() end
function Entity:update() end
function Entity:touch(other) end
function Entity:interact(other) end
function Entity:hurt(other) end

function Entity:late_update()
    self.xprev, self.yprev = self.x, self.y

    local ntx, nty = self:centroid()
    ntx \= 8
    nty \= 8
    if ntx ~= self.tx or nty ~= self.ty then
        self.tx_prev, self.ty_prev = self.tx, self.ty
    end
    self.tx, self.ty = ntx, nty
    self.state_time += 1
    self.message_cd -= 1
    self:process_tile()
end

function Entity:room_pos()
    local cx, cy = self:centroid()
    return (cx \ 128), (cy \ 128)--(self.x \ 128), (self.y \ 128)
end

function Entity:tile_pos()
    return self.tx, self.ty
end

function Entity:prev_tile_pos()
    return self.tx_prev, self.ty_prev
end

function Entity:tile_pos()
    return self.tx, self.ty
end

function Entity:centroid()
    return self.x + self.solid_x + self.solid_w * 0.5, self.y + self.solid_y + self.solid_h * 0.5
end

function Entity:bottom()
    return self.x + self.solid_x + flr(self.solid_w * 0.5), self.y + self.solid_y + self.solid_h - 1
end

function Entity:process_tile()
    local ptx, pty = (self.xprev + 4) \ 8, (self.yprev + 4) \ 8
    local ctx, cty = (self.x + 4) \ 8, (self.y + 4) \ 8

    if ptx == ctx and pty == cty then
        local tile = get_tile(ctx, cty)
        if tile then
            tile:on_stand(self)
        end 
    else
        local old_tile = get_tile(ptx, pty)
        if old_tile then
            old_tile:on_leave(self)
        end 
        local new_tile = get_tile(ctx, cty)
        if new_tile then
            new_tile:on_enter(self)
        end
    end
end

function Entity:sq_dist(other)
    local sx, sy = self:centroid()
    local ox, oy = other:centroid()
    return (ox-sx)^2 + (oy-sy)^2
    --return (other.x - self.x) ^ 2 + (other.y - self.y) ^ 2
end

function Entity:center()
    return self.x + 4, self.y + 4
end

function Entity:in_range(other, range)
    return (self:center() - other:center()) ^ 2 <= range * range
end

function Entity:moveby_x(dx, on_collision)
    if(dx == 0) return true
    self.xf += dx
    local total_delta = round(self.xf)
    local step_delta = sgn(total_delta)
    local applied = 0
    for step = 1, abs(total_delta) do
        if not self:collision(step_delta, 0) then
            self.travelled += 1
            self.xf -= step_delta
            self.x += step_delta
            applied += step_delta
            self.vx = applied
        else

            self.xf = 0
            if on_collision then
                on_collision(self, applied, total_delta)
                return false
            end
        end
    end
    return true
end

function Entity:moveby_y(dy, on_collision)
    if(dy == 0) return true
    self.yf += dy
    local total_delta = round(self.yf)
    local step_delta = sgn(total_delta)
    local applied = 0
    for step = 1, abs(total_delta) do
        if not self:collision(0, step_delta) then
            self.travelled += 1
            self.yf -= step_delta
            self.y += step_delta
            applied += step_delta
            self.vy = applied
        else
            self.yf = 0
            if on_collision then
                on_collision(self, applied, total_delta)
                return false
            end
        end
    end
    return true
end

function Entity:collision(dx, dy)
    dx = dx or 0
    dy = dy or 0

    if(dx == 0 and dy == 0) return false
    local xt0 = flr((self.x + self.solid_x + dx) \ 8)
    local xt1 = flr((self.x + self.solid_x + self.solid_w + dx - 1) \ 8)
    local yt0 = flr((self.y + self.solid_y + dy) \ 8)
    local yt1 = flr((self.y + self.solid_y + self.solid_h + dy - 1) \ 8)
    for x = xt0, xt1 do
        for y = yt0, yt1 do
            if fget(mget(x, y), 1) then --or
               --fget(mget(x, y), 2) then
                return true
            end
            if self ~= princess and self ~= hero and fget(mget(x, y), 2) then
                return true
            end
        end
    end

    for other in all(g_entities) do
        if self:intersects(other, dx, dy) then
            self:touch(other)
            other:touch(self)
            if fget(other.sprite, 1) then
                return true
            end
        end
    end
    return false
end

function Entity:intersects(other,dx ,dy)
    if self == other or other == nil then
        return false
    end

    dx = dx or 0
    dy = dy or 0

    return
        self.x + dx + self.solid_x + self.solid_w > other.x + other.solid_x and
        self.y + dy + self.solid_y + self.solid_h > other.y + other.solid_y and
        self.x + dx + self.solid_x < other.x + other.solid_x + other.solid_w and
        self.y + dy + self.solid_y < other.y + other.solid_y + other.solid_h
end

function Entity:intersects_rect(x, y, w, h)
    return
        self.x + self.solid_x + self.solid_w > x and
        self.y + self.solid_y + self.solid_h > y and
        self.x + self.solid_x < x + w and
        self.y + self.solid_y < y + h
end

function Entity:intersects_point(x, y)
    return
        self.x + self.solid_x + self.solid_w > x and
        self.y + self.solid_y + self.solid_h > y and
        self.x + self.solid_x <= x and
        self.y + self.solid_y <= y
end

function Entity:can_see(other)
    local x0, y0 = self:center()
    local x1, y1 = other:center()
    local in_los = false
    local cb = function(x, y)
        if fget(mget(x \ 8, y \ 8), 1) then
            return false
        end
        if other:intersects_point(x, y) then
            in_los = true
            return false
        end
        return true
    end
    raycast(x0, y0, x1, y1, cb)
    return in_los
end

function Entity:say(message)
    if self.message_cd < 0 then
        self.message_cd = self.message_interval
        self.message = tostring(message)
        self.message_time = 60
    end
end

function Entity:force_say(message)    
    self.message_cd = -1
    self:say(message)
end

function Entity:goto_state(state)
    if self.state != state then
        self.state_prev = self.state
        self.state = state
        self.state_time = 0

        local handler_name = "on_enter_state_" .. tostring(state)
        local handler = self[handler_name]
        if handler then
            handler(self)
        end
    end
end



--------------- Concrete entity types ---------------

-- Knight
Knight = EntityTypes:declare(1)
Knight.facing = 1
Knight.solid_x = 2              --Princess.solid_x = 2
Knight.solid_y = 5              --Princess.solid_y = 5
Knight.solid_w = 2              --Princess.solid_w = 3
Knight.solid_h = 2              --Princess.solid_h = 3
Knight.attack_frames = 15
Knight.attack_timer = 0
Knight.attack_range = 8
Knight.attack_dirx = 0
Knight.attack_diry = 0
Knight.target = nil
Knight.perception = 56
Knight.follow_threshold = 8
Knight.interact_range = 12
Knight.path = nil
Knight.wait_timer = 0
Knight.active = true
Knight.fell_to_his_death = true
Knight.respawn_timer = 0
Knight.respawn_delay = 180
Knight.see_chest_msgs = {
    "oh, a chest!",
    "phat lewtz!",
    "the gold is mine!",
}
Knight.open_chest_msgs = {
    "i'm rich!",
    "another sword?",
    "meh.",
    "holy !@*&",
    "phat loot!",
    "sick lewtz",
    "new armor!",
    "you call this loot?",
    "treasure!",
}
Knight.kill_msgs = {
    "i striketh thee down!",
    "got 'em!",
    "you are slain!",
    "foul spawn!",
    "take that!",
    "by my blade!",
    "level up!",
    "rekt!",
    "(flexes)",
    "en garde!",
    "attack!",
    "monster!",
}
Knight.follow_msgs = {
    "oh right, you exist",
    "escort quests suck",
    "at your side, m'lady.",
    "at your service!",
    "my sword is yours.",
    "what now?",
    "i'll save you!",
}
Knight.spike_msgs = {
    "armor > spikes",
    "ouch! spikes! jk",
}
Knight.princess_died_msgs = {
    "uh oh...",
    "whoops.",
    "sorry 'bout that",
    "whatever.",
    "oh well.",
    "princess?",
    "yikes.",
    "next princess plz"
}

function Knight:attack(dx, dy)
    self.attack_dirx = dx
    self.attack_diry = dy
    self:goto_state(EntityStates.Attack)
end

function approach(current, target, max_delta)
    return min(abs(target - current), max_delta) * sgn(target - current)
end

function Knight:move_to_point(xto, yto, s)
    local x, y = self:centroid()
    local vx = approach(x, xto, s)
    local vy = approach(y, yto, s)
    self:moveby_x(vx)
    self:moveby_y(vy)
end

function Knight:move_on_path()
    if(not self.path) return
    local wp = nil
    while #(self.path) > 0 do
        wp = self.path[1]
        local fx, fy = self:centroid()
        if fx ~= wp.x*8+4 or fy ~= wp.y*8+4 then
            break
        else
            deli(self.path, 1)
        end
    end
    if wp then
        self:move_to_point(wp.x*8+4, wp.y*8+4, 0.5)
    end
end

function Knight:path_behind(other)
    local tx, ty   = self:centroid()
    local ttx, tty = other:prev_tile_pos()

    if self.path and #self.path > 0 then
        local goal =  self.path[#self.path]
        if goal.x == ttx and goal.y == tty then
            return
        end
    end

    self.path = Pathfinding:compute(tx\8, ty\8, ttx, tty, Pathfinding.euclidean)
    if self.path then 
        deli(self.path, 1)
    end
end

function Knight:update_path(other)
    local tx, ty   = self:centroid()
    local ttx, tty = other:centroid()

    if self.path and #self.path > 0 then
        local goal =  self.path[#self.path]
        if goal.x == ttx \ 8 and goal.y == tty \ 8 then
            return
        end
    end

    self.path = Pathfinding:compute(tx\8, ty\8, ttx\8, tty\8, Pathfinding.euclidean)
    if self.path then 
        deli(self.path, 1)
    end
end

function Knight:nearest_chest()
    return self:get_closest(function(e)
        return 
        (e.sprite == TreasureChest.sprite) and 
        (not e.open) and
        e:sq_dist(self) < (self.perception)^2
    end)
end

function Knight:nearest_enemy()
    return self:get_closest(function(e)
        return e.is_enemy and
               e.state != EntityStates.Die and
               e:sq_dist(self) < (self.perception)^2
    end)
end

function Knight:get_closest(predicate)
    local closest = -1
    local rval = nil
    for e in all(g_entities) do
        if predicate(e) and not e.removed and e.active then
            local dist = self:sq_dist(e)
            if closest < 0 or dist < closest then
                rval = e
                closest = dist
            end
        end
    end
    return rval
end

function Knight:try_attack(other)
    if self:sq_dist(other) < self.attack_range ^ 2  then
        local dx = other.x - self.x
        local dy = other.y - self.y
        if abs(dx) < abs(dy) then
            dy = sgn(dy)
            dx = 0
        else
            dx = sgn(dx)
            dy = 0
        end
        self:attack(dx, dy)
        return true
    end
    return false
end

function Knight:update()

    if self.wait_timer > 0 then
        self.wait_timer -= 1
        return
    end

    if self.state == EntityStates.Default then

        local chest = self:nearest_chest()
        if chest then
            if self.target ~= chest then
                self.target = chest
                if game_state ~= MAIN_MENU then 
                    self:say(rnd(Knight.see_chest_msgs))
                end
                self:update_path(chest)
            end
            self:move_on_path()
            return
        end

        local enemy = self:nearest_enemy()
        if enemy then
            -- if self.target == nil or not self.target.is_enemy then
            --     self:say(rnd(Knight.attack_msgs))
            -- end
            self.target = enemy
            self:update_path(enemy)
            self:move_on_path()
            if self:try_attack(enemy) then
                local x1,x2,y1,y2=0,0,0,0
                if self.attack_diry > 0 then
                    x1 = self.x
                    x2 = self.x + 8
                    y1 = self.y
                    y2 = self.y + 12
                elseif self.attack_diry < 0 then
                    x1 = self.x
                    x2 = self.x + 8
                    y1 = self.y - 6
                    y2 = self.y + 8
                elseif self.attack_dirx < 0 then
                    x1 = self.x - 5
                    x2 = self.x + 7
                    y1 = self.y
                    y2 = self.y + 8
                else
                    x1 = self.x
                    x2 = self.x + 12
                    y1 = self.y
                    y2 = self.y + 8
                end
                for e in all(g_entities) do
                    if e.is_enemy then
                        if e:intersects_rect(x1, y1, x2-x1, y2-y1) then
                            e:hurt(self)
                            self:say(rnd(Knight.kill_msgs))
                        end
                    end
                end
            end
            return
        end

        if self.target and (self.target.removed or (not self.target.active)) then
            self.target = nil
        end
        if princess then -- main menu hack
            if not self.target then
                self:say(rnd(Knight.follow_msgs))
                self.target = princess
            end

            if self:sq_dist(princess) > self.follow_threshold ^ 2 then
                self:path_behind(princess)
                self:move_on_path()
            end
        end
    elseif self.state == EntityStates.Attack then
        local enemy = self:nearest_enemy()
        if enemy then
            self:update_path(enemy)
        end
        self:move_on_path() 
        if self.state_time > self.attack_frames then
            self:goto_state(EntityStates.Default)
        end
    elseif self.state == EntityStates.Fall then
        self.x = 8 * ((self.x + 4) \ 8)
        self.y = 8 * ((self.y + 4) \ 8)
        self.fell_to_his_death = true
        if self.state_time > self.respawn_delay and princess:is_alive() then
            --self.x, self.y = princess.x, princess.y
            self.x, self.y = princess:prev_tile_pos()
            self.x *= 8
            self.y *= 8
            self:goto_state(EntityStates.Default)
        end
    else

    end
end

--falling
function Knight:on_enter_state_4()
    if(princess:is_alive()) princess:force_say(rnd(Princess.knight_is_a_moron_msgs))
    sfx(4)
end

function Knight:draw()
    if self.state == EntityStates.Attack then
        self.sprite = 1
        local sword_sprite = 17
        local sword_hflip = false
        local sword_vflip = false
        local sword_xoffset = 6
        local sword_yoffset = 0
        local self_hflip = false
        if self.attack_dirx < 0 then
            sword_hflip = true
            self_hflip = true
            sword_xoffset= -6
            -- local x1 = self.x - 5
            -- local x2 = self.x + 7
            -- local y1 = self.y
            -- local y2 = self.y + 8
            -- rect(x1,y1,x2,y2,8)
        elseif self.attack_diry < 0 then
            sword_vflip = true
            sword_hflip = true
            sword_xoffset = 0
            sword_yoffset = -4
            self.sprite = 32
            sword_sprite = 21
            -- local x1 = self.x
            -- local x2 = self.x + 8
            -- local y1 = self.y - 6
            -- local y2 = self.y + 8
            -- rect(x1,y1,x2,y2,8)
        elseif self.attack_diry > 0 then
            sword_hflip = true
            sword_yoffset = 3
            sword_xoffset = 2
            self.sprite = 16
            sword_sprite = 21
            -- local x1 = self.x
            -- local x2 = self.x + 8
            -- local y1 = self.y
            -- local y2 = self.y + 12
            -- rect(x1,y1,x2,y2,8)
        else
            -- local x1 = self.x
            -- local x2 = self.x + 12
            -- local y1 = self.y
            -- local y2 = self.y + 8
            -- rect(x1,y1,x2,y2,8)
        end
        local frame = 16 * flr(min(self.state_time, self.attack_frames - 1) / 7)
        spr(self.sprite, self.x, self.y, 1, 1, self_hflip)
        spr(sword_sprite + frame, self.x + sword_xoffset, self.y + sword_yoffset, 1, 1, sword_hflip, sword_vflip)
    elseif self.state == EntityStates.Fall then
        local frame = flr(min(self.state_time, 60) / 20)
        self.sprite = 2 + 16 * frame
        spr(self.sprite, self.x, self.y)
    else
        local hflip = sgn(self.vx) < 0
        spr(1 + (self.travelled \ 2 % 2 ~= 0 and 1 or 0), self.x, self.y, 1, 1, hflip)
    end
end

-- Princess
Princess = EntityTypes:declare(3)
Princess.facing = 1
Princess.solid_x = 2
Princess.solid_y = 5
Princess.solid_w = 3
Princess.solid_h = 3
Princess.hpmax = 5
Princess.damage = 0
Princess.active = true
Princess.held_keys = 0
Princess.hurt_msgs = {
    "frick!", 
    "yowch!", 
    "ow!", 
    "wtf!", 
    "eeek!", 
    "help!", 
    "that hurts!" 
}
Princess.pickup_key_msgs = {
    "key get!",
    "a key!",
    "what does it unlock?" 
}
Princess.unlock_door_msgs = {
    "knock, knock",
    "open sesame!",
    "(grand entrance)"
}
Princess.pickup_heart_msgs = {
    "i'm healed!",
    "i feel good",
    "that's better",
    "good as new" 
}
Princess.death_msgs = {
    "noo!",
    "my kingdom!",
    ":(",
    "ahhh!"
}
Princess.crack_msgs = {
    "watch your step!",
    "get to safety!",
    "tread lightly!",
    "the floor is weak!"
}
Princess.knight_is_a_moron_msgs = {
    "(cringe)",
    "you fool!",
    "really...?",
    "hurry back!",
    "fell down *again*?",
    "your pathing sucks.",
    "(facepalm)" 
}

function Princess:is_alive()
    return self.damage < self.hpmax
end

function Princess:update()
    if self.state == EntityStates.Fall then
        self.x = 8 * ((self.x + 4) \ 8)
        self.y = 8 * ((self.y + 4) \ 8)
        self:fall()
    elseif self.state == EntityStates.Die then
        self:die()
    elseif self.state == EntityStates.HurtByEnemy then
        self:damaged()
    elseif self.state == EntityStates.HurtBySpikes then
        self:damaged()
    else
        self.sprite = 3 + (self.travelled \ 2 % 2 ~= 0 and 1 or 0)
    end
end

function Princess:damaged()
    if self.state_time > 30 then
        self:goto_state(EntityStates.default)
    end
end

--hurt by spikes
function Princess:on_enter_state_5()
    sfx(6)
    self:apply_damage(1)
    self:say(rnd(Princess.hurt_msgs))
end

--ded
function Princess:on_enter_state_3()
    sfx(8)
    self:force_say(rnd(Princess.death_msgs))
    if (hero.state ~= EntityStates.Fall) hero:force_say(rnd(Knight.princess_died_msgs))
end

--hurt by enemy
function Princess:on_enter_state_2()
    sfx(7)
    self:apply_damage(1)
    self:say(rnd(Princess.hurt_msgs))
end

--falling
function Princess:on_enter_state_4()
    sfx(4)
    self.damage = self.hpmax
    self:force_say(rnd(Princess.death_msgs))
    if (hero.state ~= EntityStates.Fall) hero:force_say(rnd(Knight.princess_died_msgs))
end

function Princess:apply_damage(amount)
    self.damage += amount
    self.damage = mid(0, self.damage, self.hpmax)
    if not self:is_alive() then
        self:goto_state(EntityStates.Die)
    end
end

function Princess:hurt(other)
    if other and
       self:is_alive() and
       self.state ~= EntityStates.HurtBySpikes then
        self:goto_state(EntityStates.HurtByEnemy)
    end
end

function Princess:fall()
    local frame = flr(min(self.state_time, 60) / 20)
    self.sprite = 3 + 16 * frame
end

function Princess:die()    
    local frame = flr(min(self.state_time, 59) / 20)
    self.sprite = 4 + 16 * frame
end

function Princess:draw()
    if self.state == EntityStates.HurtByEnemy or self.state == EntityStates.HurtBySpikes then
        if self.state_time\8 % 2 == 0 then
            for i = 1, 15 do
                pal(i, 8)
            end
            spr(self.sprite, self.x, self.y, 1, 1, sgn(self.vx) < 0)
            pal()
            palt(0, false)
            palt(9, true)
        else
            spr(self.sprite, self.x, self.y, 1, 1, sgn(self.vx) < 0)
        end
    else
        spr(self.sprite, self.x, self.y, 1, 1, sgn(self.vx) < 0)
    end
end

-- Slime
Slime = EntityTypes:declare(5)
Slime.facing = 1
Slime.solid_x = 2
Slime.solid_y = 5
Slime.solid_h = 3
Slime.solid_w = 3
Slime.is_enemy = true
Slime.hpmax = 2
Slime.damage = 0

function Slime:process_tile()
    if not self:is_alive() then return end
    local ptx = self.x + self.solid_x + flr(self.solid_w * 0.5)
    local pty = self.y + self.solid_y + self.solid_h - 1
    local ctx = self.xprev + self.solid_x + flr(self.solid_w * 0.5)
    local cty = self.yprev + self.solid_y + self.solid_h - 1

    local ctx, cty = self:tile_pos()
    
    if ptx == ctx and pty == cty then
        local tile = get_tile(ctx, cty)
        if tile then
            tile:on_stand(self)
            --self:force_say("stand tile")
        end 
    else
        local old_tile = get_tile(ptx, pty)
        if old_tile then
            old_tile:on_leave(self)
            --self:force_say("left tile")
        end 
        local new_tile = get_tile(ctx, cty)
        if new_tile then
            --self:force_say("new tile")
            new_tile:on_enter(self)
        end
    end
end

function Slime:draw()
    spr(self.sprite, self.x, self.y, 1, 1, sgn(self.vx) < 0)
end

function Slime:update()
    if self.state == EntityStates.Die then
        if self.state_time < 30 then
            local frame = 6 + 16 * flr(min(self.state_time, 30) / 10)
            self.sprite = frame
        else
            self.removed = true
        end
    else
        local vx, vy = self:seek(princess and princess or hero, .2)
        self:moveby_x(vx*.5)
        self:moveby_y(vy*.5)
        self.sprite = 5 + (self.travelled \ 2 % 2 ~= 0 and 1 or 0)
    end
end

-- Falling (hack)
-- There's an edge case where slimes sometimes enter pitfall tiles even though they
-- are supposed to avoid them. Probably an off-by-one error somewhere or something.
-- Not enough time to properly fix it, so just kill them if it happens
function Slime:on_enter_state_4()
    self:apply_damage(2)
end

function Slime:apply_damage(amount)
    self.damage += amount
    if not self:is_alive() then
        self:goto_state(EntityStates.Die)
    end
end

function Slime:is_alive()
    return self.damage < self.hpmax
end

function Slime:hurt(other)
    --freeze = 15
    sfx(0)
    self:apply_damage(1)
end

function Slime:touch(other)
    if other == princess then
        other:hurt(self)
    end
end

function Slime:seek(target, max_speed)
    local tox = target.x - self.x
    local toy = target.y - self.y
    local m = sqrt(tox * tox + toy * toy)
    if (m == 0) return 0,0
    local vx = max_speed * tox / m -- seeker.vx
    local vy = max_speed * toy / m -- seeker.vy
    return vx, vy
end

-- Eye bullets
EyeLaser = EntityTypes:declare(63)
EyeLaser.solid_x = -1
EyeLaser.solid_y = -1
EyeLaser.solid_w = 2
EyeLaser.solid_h = 2
EyeLaser.maxspeed = 2
EyeLaser.active = true

function EyeLaser:update()
    self.x += self.vx * self.maxspeed
    self.y += self.vy * self.maxspeed

    if princess:is_alive() and self:intersects(princess) then
        princess:hurt(self)
        self.removed = true
    end

    if self:intersects_rect(hero.x, hero.y, 8, 8) then
        self.removed = true
    end

    if self.active and not is_onscreen(self.x, self.y) then
        self.removed = true
    end
end

function EyeLaser:draw()
    circfill(self.x, self.y, 2, 1)
    circfill(self.x, self.y, 1, 0 + ((self.state_time/3) % 15))
end

-- Floating evil eye of doom
Eye = EntityTypes:declare(26)
Eye.is_enemy = true
Eye.floating_offset = 0
Eye.angle = 0
Eye.pupil_x = 0
Eye.pupil_y = 0
Eye.hpmax = 5
Eye.damage = 0

function Eye:apply_damage(amount)
    self.damage += amount
    if not self:is_alive() then
        self:goto_state(EntityStates.Die)
    end
end

function Eye:is_alive()
    return self.damage < self.hpmax
end

function Eye:init()
    self.floating_offset = rnd(2) + 2
end

function Eye:hurt(other)
    sfx(0)
    self:apply_damage(1)
end

function Eye:shoot()
    sfx(9)
    local bullet = EntityTypes:spawn(63, self.pupil_x, self.pupil_y)
    bullet.vx = cos(self.angle) * 0.1
    bullet.vy = sin(self.angle) * 0.1
end

function Eye:update()
    if self.state == EntityStates.Die then
        if self.state_time < 60 then
            local frame = 9 + 16 * round(3 * min(self.state_time, 60) / 60)
            self.sprite = frame
        else
            self.removed = true
        end
    else
        -- look at the princess
        if princess and princess:is_alive() and 
           self.state_time > 0 and 
           (flr(floating_offset) + self.state_time) % 120 == 0 then
            self:shoot()
        end
    end
end

function Eye:draw()
    if self.state == EntityStates.Die then
        spr(self.sprite, self.x, self.y)
        return
    end

    local ratio = 0.5*(sin(self.floating_offset + t()) + 1)

    --draw lil shadow
    local shadow_height = flr(0 * (ratio) + 2*(1 - ratio))
    local shadow_width = 2 * (ratio) + 7 * (1 - ratio)
    local yo = round(-2 * ratio - 1)
    local shadow_margin = 0.5 * (8 - shadow_width)
    rectfill(self.x + shadow_margin, self.y + 8 - shadow_height, self.x + shadow_margin+shadow_width, self.y + 8, 1)
    
    --draw sclera
    spr(self.sprite, self.x, self.y + yo)
    
    --draw pupil
    local cx = self.x + 4
    local cy = self.y + yo + 4
    local tcx, tcy = princess:center()
    self.angle = atan2(tcx - cx, tcy - cy)
    self.pupil_x = cx + 2 * cos(self.angle)
    self.pupil_y = cy + 2 * sin(self.angle)
    circfill(self.pupil_x, self.pupil_y, 1, 12)

    --rect(self.x+self.solid_x,self.y+self.solid_y,self.x+self.solid_x+self.solid_w,self.y+self.solid_y+self.solid_h, 7)
end

-- Key
Key = EntityTypes:declare(13)
function Key:touch(other)
    if not self.removed and other == princess then
        sfx(1)
        princess.held_keys += 1
        self.removed = true
        princess:say(rnd(Princess.pickup_key_msgs))
    end
end

Heart = EntityTypes:declare(14)
function Heart:touch(other)
    if not self.removed and other == princess and princess.damage > 0 then
        sfx(1)
        princess:apply_damage(-1)
        self.removed = true
        princess:say(rnd(Princess.pickup_heart_msgs))
    end
end

-- Treasure
TreasureChest = EntityTypes:declare(7)
TreasureChest.open = false
function TreasureChest:touch(other)
    if other == hero and not self.open then
        sfx(3)
        self.sprite = 8
        self.open = true
        other:force_say(rnd(Knight.open_chest_msgs))
    end
end

-- Door
Door = EntityTypes:declare(15)
Door.open = false
function Door:touch(other)
    if (not self.open) and other == princess and other.held_keys > 0 then
        sfx(2)
        self.sprite = 50
        self.open = true
        other.held_keys -= 1
        princess:say(rnd(Princess.unlock_door_msgs))
    end
end

-- Door alias
SideDoor = EntityTypes:declare(31)
SideDoor.open = false
function SideDoor:touch(other)
    if (not self.open) and other == princess and other.held_keys > 0 then
        sfx(2)
        self.sprite = 50
        self.open = true
        other.held_keys -= 1
        princess:say(rnd(Princess.unlock_door_msgs))
    end
end



--------------- Pathfinding ---------------
Pathfinding = { }
PathList = { }
PathList.__index = PathList

function PathList:__len()
    return #(self.items)
end

function PathList:new()
    local instance = { }
    instance.membership = { }
    instance.items = { }
    instance = setmetatable(instance, self)
    return instance 
end

function PathList:node(xx, yy, gg, hh, pprev)
    return { x = xx, y = yy, g = gg, h = hh, f = (gg + hh), prev = pprev }
end

function PathList:push(n)
    self.membership[n.x + n.y * 128] = true
    add(self.items, n)
end

function PathList:pop()
    local rval = deli(self.items)
    self.membership[rval.x + rval.y * 128] = false
    return rval
end

function PathList:contains(x, y)
    return self.membership[x + y * 128] == true
end

--credits: impbox
function PathList:sort()
    for i=1,#(self.items) do
        local j = i
        while j > 1 and self.items[j - 1].f < self.items[j].f do
            self.items[j], self.items[j - 1] = self.items[j - 1], self.items[j]
            j = j - 1
        end
    end
end

function PathList:get(x, y)
    for i=1, #(self.items) do
        if self.items[i].x == x and self.items[i].y == y then
            return self.items[i]
        end
    end
    return nil
end

Pathfinding.euclidean = function(xfrom, yfrom, xto, yto)
    local dx = abs(xto - xfrom)
    local dy = abs(yto - yfrom)
    if dx > dy then 
        return 14 * dy + 10 * (dx - dy) 
    end
    return 14 * dx + 10 * (dy - dx)
end

Pathfinding.manhattan = function(xfrom, yfrom, xto, yto)
    return abs(xto-xfrom) + abs(yto-yfrom)
end

Pathfinding.djikstra = function(xfrom, yfrom, xto, yto)
    return 1
end

iterations = 0
function Pathfinding:compute(xfrom, yfrom, xto, yto, heuristic)
    heuristic = heuristic or Pathfinding.manhattan
    local closed = PathList:new()
    local open = PathList:new()
    open:push(PathList:node(xfrom, yfrom, 0, heuristic(xfrom, yfrom, xto, yto), nil))
    iterations = 0
    while(#open > 0 and iterations < 256) do
        iterations += 1
        
        local current = open:pop()
        closed:push(current)

        if current.x == xto and current.y == yto then
            return self:make_path(current)
        end

        for xo=-1, 1 do
            for yo = -1, 1 do
                if xo ~= 0 or yo ~= 0 then -- 8-way including diagonals
                --if abs(xo) ~= abs(yo) then -- 4-way
                    local nx, ny = current.x + xo, current.y + yo
                    if fget(mget(nx, ny), 1) or 
                       fget(mget(nx, ny), 2) or
                       closed:contains(nx, ny) then
                       goto continue
                    end

                    local g = current.g + heuristic(current.x, current.y, nx, ny)
                    local h = heuristic(nx, ny, xto, yto)
                    -- if fget(mget(nx, ny), 2) then
                    --     h *= 1000
                    -- end

                    if open:contains(nx, ny) then
                        local node = open:get(nx, ny)
                        if g < node.g then
                            node.g = g
                            node.h = h
                            node.f = g + h
                            node.prev = current
                        end
                    else
                        open:push(PathList:node(nx, ny, g, h, current))
                    end
                end
                ::continue::
            end
        end
        open:sort()
    end
    return self:make_path(current)
end

function Pathfinding:make_path(tail)
    local len = 0
    local n = tail
    while n ~= nil do
        len += 1
        n = n.prev
    end

    local path =  { }
    for i=len, 1, -1 do
        path[i] = tail
        tail = tail.prev
    end

    return path
end



--------------- General/utility functions ---------------

function get_mouse()
    return stat(32), stat(33), (stat(34) & 0x01) 
end

function poll_dpad()
    local mask = btn()
    return ((mask&0x02)>>1)-((mask&0x01)>>0),
           ((mask&0x08)>>3)-((mask&0x04)>>2)
end

function poll_btns()
    return btn(4),btn(5)
end

function round(n) 
    return flr(n+0.5) 
end

-- credit: https://github.com/lvictorino/pico8-collection/blob/master/bresenham.p8
function raycast(x1, y1, x2, y2, on_step)
	local dx = abs(x2-x1)
	local dy = abs(y2-y1)
	local x = x1
	local y = y1
    local sx = sgn(x2-x1)
    local sy = sgn(y2-y1)
    local err = 0
	if dx > dy then
		err = dx * 0.5
		while x != x2 do
            if on_step(x, y) then
                err -= dy
                if err < 0 then 
                    y += sy
                    err += dx
                end
                x += sx
            else return end
		end
	else
		err = dy * 0.5
		while y != y2 do 
            if on_step(x, y) then
                err -= dx
                if err < 0 then
                    x += sx
                    err += dy
                end
                y += sy
            else return end
		end
	end
end

function print_center(text, x, y, c, sc)
    c = c or 7
    sc = sc or 1
	x -= (#text * 4 - 1) / 2
    if sc then
        print(text, x + 1, y + 1, sc)
        print(text, x + 1, y + 0, sc)
    end
	print(text, x, y, c)

end

function is_onscreen(x, y)
    local camera_x = peek2(0x5f28)
	local camera_y = peek2(0x5f2a)
    return not(x < (camera_x - 8) or
               x > (camera_x + 127 + 8) or
               y < (camera_y - 8) or
               y > (camera_y + 127 + 8))
end
