script_name("WeaponIcon")
script_author("Guzers")

local imgui = require 'mimgui'
local ffi   = require('ffi')
local cfg   = require('jsoncfg')

local cast = ffi.cast
local gta  = ffi.load('GTASA')
local new  = imgui.new

ffi.cdef[[
    typedef struct {
        uint8_t r, g, b, a;
    } CRGBA;

    typedef struct {
        float left, bottom, right, top;
    } CRect;

    void _ZN7CSprite18RenderOneXLUSpriteEfffffhhhsfhhhff(float, float, float, float, float, uint8_t, uint8_t, uint8_t, int16_t, float, uint8_t, uint8_t, uint8_t, float, float);
    void _ZN9CSprite2d4DrawEffffRK5CRGBA(void*, float, float, float, float, CRGBA*);
    void _ZN17CWidgetPlayerInfo14DrawWeaponIconEP4CPed5CRectf(void*, void*, CRect, float);
    extern void* _ZN4CHud7SpritesE;
]]

local defaultConfig = {
    enabled = true,
    x = 100, y = 100,
    w = 100, h = 100,
    R = 255, G = 255, B = 255, A = 255,
}

local config    = cfg.load(defaultConfig, 'weaponicon')
cfg.save(config, 'weaponicon')

local SW, SH    = getScreenResolution()
local WinState  = new.bool(false)
local enabled   = new.bool(config.enabled)
local posX      = new.int(config.x)
local posY      = new.int(config.y)
local sizeW     = new.int(config.w)
local sizeH     = new.int(config.h)
local iconColor = ffi.new('float[4]', {config.R / 255, config.G / 255, config.B / 255, config.A / 255})
local color     = ffi.new('CRGBA', {255, 255, 255, 255})

local function saveConfig()
    config.enabled = enabled[0]
    config.x = posX[0]; config.y = posY[0]
    config.w = sizeW[0]; config.h = sizeH[0]
    config.R = iconColor[0] * 255; config.G = iconColor[1] * 255
    config.B = iconColor[2] * 255; config.A = iconColor[3] * 255
    cfg.save(config, 'weaponicon')
end

local function onD3DPresent()
    if not enabled[0] or isPauseMenuActive() then return end
    local weapon = getCurrentCharWeapon(PLAYER_PED)
    color.r = iconColor[0] * 255
    color.g = iconColor[1] * 255
    color.b = iconColor[2] * 255
    color.a = iconColor[3] * 255
    if weapon <= 0 then
        gta._ZN9CSprite2d4DrawEffffRK5CRGBA(cast('void*', gta._ZN4CHud7SpritesE), posX[0] - sizeW[0] / 2, posY[0] - sizeH[0] / 2, sizeW[0], sizeH[0], color)
    else
        local CRect = ffi.new('CRect', {9999, 9999, 9999, 9999})
        gta._ZN17CWidgetPlayerInfo14DrawWeaponIconEP4CPed5CRectf(nil, cast('void*', getCharPointer(PLAYER_PED)), CRect, 0.0)
        gta._ZN7CSprite18RenderOneXLUSpriteEfffffhhhsfhhhff(posX[0], posY[0], 10.0, sizeW[0] * 0.5, sizeH[0] * 0.5, color.r, color.g, color.b, 255, 1.0, color.a, 0, 0, 0.0, 0.0)
    end
end

imgui.OnFrame(
    function() return WinState[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(SW / 2, SH / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(280, 240), imgui.Cond.FirstUseEver)
        imgui.Begin('Weapon Icon', WinState, imgui.WindowFlags.NoCollapse)
        if imgui.Checkbox('Enable', enabled) then saveConfig() end
        imgui.PushItemWidth(imgui.GetContentRegionAvail().x)
        if imgui.SliderInt('##x',  posX,  0, SW,   'PosX: %d')   then saveConfig() end
        if imgui.SliderInt('##y',  posY,  0, SH,   'PosY: %d')   then saveConfig() end
        if imgui.SliderInt('##w', sizeW,  0, 1000, 'Width: %d')  then saveConfig() end
        if imgui.SliderInt('##h', sizeH,  0, 1000, 'Height: %d') then saveConfig() end
        if imgui.ColorEdit4('##color', iconColor) then saveConfig() end
        imgui.PopItemWidth()
        imgui.End()
    end
)

addEventHandler('onD3DPresent', onD3DPresent)

function main()
    sampRegisterChatCommand('weaponicon', function() 
        WinState[0] = not WinState[0] 
    end)
    wait(-1)
end
