script_name("WeaponIconWithHook")

local imgui = require 'mimgui'
local ffi   = require('ffi')
local hook  = require('monethook')
local cfg   = require('jsoncfg')

local cast = ffi.cast
local gta  = ffi.load('GTASA')
local new  = imgui.new

ffi.cdef[[
    typedef struct {
        uint8_t r, g, b, a;
    } CRGBA;

    void _ZN7CSprite18RenderOneXLUSpriteEfffffhhhsfhhhff(float ScreenX, float ScreenY, float ScreenZ, float SizeX, float SizeY, uint8_t R, uint8_t G, uint8_t B, int16_t Intensity16, float RecipZ, uint8_t Alpha, uint8_t FlipU, uint8_t FlipV, float uvPad1, float uvPad2);
    void _ZN9CSprite2d4DrawEffffRK5CRGBA(void* sprite, float x, float y, float w, float h, CRGBA* color);
    void _ZN17CWidgetPlayerInfo14DrawWeaponIconEP4CPed5CRectf(void* self, void* ped, float left, float bottom, float right, float top, float f);
    extern void* _ZN4CHud7SpritesE;
]]

local defaultConfig = {
    enabled = true,
    x = 100, y = 100,
    w = 100, h = 100,
    R = 255, G = 255, B = 255, A = 255,
}

local config = cfg.load(defaultConfig, 'weaponicon')
cfg.save(config, 'weaponicon')

local SW, SH    = getScreenResolution()
local WinState  = new.bool(false)
local enabled   = new.bool(config.enabled)
local posX      = new.int(config.x)
local posY      = new.int(config.y)
local sizeW    = new.int(config.w)
local sizeH    = new.int(config.h)
local iconColor = ffi.new('float[4]', {config.R / 255, config.G / 255, config.B / 255, config.A / 255})

local color = ffi.new('CRGBA', {255, 255, 255, 255})

local function saveConfig()
    config.enabled = enabled[0]
    config.x = posX[0]; config.y = posY[0]
    config.w = sizeW[0]; config.h = sizeH[0]
    config.R = iconColor[0] * 255
    config.G = iconColor[1] * 255
    config.B = iconColor[2] * 255
    config.A = iconColor[3] * 255
    cfg.save(config, 'weaponicon')
end

local drawWeaponIconHook
drawWeaponIconHook = hook.new(
    'void(*)(void*, void*, float, float, float, float, float)',
    function(self, ped, left, bottom, right, top, f)
        drawWeaponIconHook(self, ped, left, bottom, right, top, f)
        if not enabled[0] then return end
        local weapon = getCurrentCharWeapon(PLAYER_PED)
        color.r = iconColor[0] * 255
        color.g = iconColor[1] * 255
        color.b = iconColor[2] * 255
        color.a = iconColor[3] * 255
        if weapon <= 0 then
            gta._ZN9CSprite2d4DrawEffffRK5CRGBA(cast('void*', gta._ZN4CHud7SpritesE), posX[0] - sizeW[0] / 2, posY[0] - sizeH[0] / 2, sizeW[0], sizeH[0], color)
        else
            gta._ZN7CSprite18RenderOneXLUSpriteEfffffhhhsfhhhff(posX[0], posY[0], 10.0, sizeW[0] * 0.5, sizeH[0] * 0.5, color.r, color.g, color.b, 255, 1.0, color.a, 0, 0, 0.0, 0.0)
        end
    end,
    cast('uintptr_t', cast('void*', gta._ZN17CWidgetPlayerInfo14DrawWeaponIconEP4CPed5CRectf))
)

imgui.OnFrame(
    function() return WinState[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(SW / 2, SH / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(280, 240), imgui.Cond.FirstUseEver)
        imgui.Begin('Weapon Icon', WinState, imgui.WindowFlags.NoCollapse)
        if imgui.Checkbox('Enable', enabled) then saveConfig() end
        imgui.PushItemWidth(imgui.GetContentRegionAvail().x)
        if imgui.SliderInt('##x',  posX,   0, SW,    'PosX: %d')    then saveConfig() end
        if imgui.SliderInt('##y',  posY,   0, SH,    'PosY: %d')    then saveConfig() end
        if imgui.SliderInt('##w', sizeW, 0, 1000, 'Width: %d')  then saveConfig() end
        if imgui.SliderInt('##h', sizeH, 0, 1000, 'Height: %d') then saveConfig() end
        if imgui.ColorEdit4('##color', iconColor) then saveConfig() end
        imgui.PopItemWidth()
        imgui.End()
    end
)

function main()
    sampRegisterChatCommand('weaponicon', function() 
        WinState[0] = not WinState[0] 
    end)
    wait(-1)
end

addEventHandler('onScriptTerminate', function(scr)
    if scr == script.this then drawWeaponIconHook.stop() end
end)
