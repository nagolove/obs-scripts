package.path = package.path .. ";" .. os.getenv("HOME") .. "/obs-scripts/?.lua"
--package.path = package.path .. ';./*.lua'

local format = string.format
local inspect = require 'inspect'
obs = obslua

local state_break = false
local state_audio_kbmicro = true
local state_audio_cammicro = true
--local state_audio_desktop_audio = true

--[[
function on_frontend_event(event)
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
        obs.script_log(obs.LOG_INFO, "Трансляция началась!")
    elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
        obs.script_log(obs.LOG_INFO, "Трансляция остановлена!")
    end
end
--]]

-- Название сцены, которую будем использовать
--local scene_name = "Scene"

-- Функция, возвращающая список всех сцен (по их названиям)
local function get_scene_names()
    local scene_list = obs.obs_frontend_get_scenes()
    local names = {}

    if scene_list ~= nil then
        for i = 1, #scene_list do
            local scene_source = scene_list[i]
            local scene_name = obs.obs_source_get_name(scene_source)
            table.insert(names, scene_name)
        end

        -- ВАЖНО: освободить все источники после использования
        for i = 1, #scene_list do
            obs.obs_source_release(scene_list[i])
        end
    end

    return names
end


-- Функция для изменения видимости источника
function toggle_source_visibility(source_name, visible)
    print(format(
        "toggle_source_visibility: source_name '%s'", source_name
    ))

    local scenes_all = get_scene_names();

    for _, scene_name in ipairs(scenes_all) do

        local scene_source = obs.obs_get_source_by_name(scene_name)
        if scene_source then
            local scene_item = obs.obs_scene_from_source(scene_source)
            local items = obs.obs_scene_enum_items(scene_item)
            print("toggle_source_visibility: items " .. inspect(items))
            if items then
                for _, item in ipairs(items) do
                    local source = obs.obs_sceneitem_get_source(item)
                    if obs.obs_source_get_name(source) == source_name then
                        print("toggle_source_visibility: source found")
                        obs.obs_sceneitem_set_visible(item, visible)
                    end
                end
                obs.sceneitem_list_release(items)
            end
            obs.obs_source_release(scene_source)
        end
    end

    return not visible
end

-- Функция для включения/отключения аудио элемента
function toggle_audio_source_mute(source_name, mute)
    local source = obs.obs_get_source_by_name(source_name)
    if source then
        obs.obs_source_set_muted(source, mute)
        obs.obs_source_release(source)
    end
    return not mute
end

-- Горячая клавиша для переключения видимости источника
hotkey_id = obs.OBS_INVALID_HOTKEY_ID
source_name_to_toggle = "break"

function on_event(pressed)
    print('on_event:' .. tostring(pressed))
    if pressed then
        state_break = toggle_source_visibility(source_name_to_toggle, state_break)
        state_audio_kbmicro = toggle_audio_source_mute("kbmicro", state_audio_kbmicro)
        state_audio_cammicro = toggle_audio_source_mute("cammicro", state_audio_cammicro)
        print('on_event: state_break ' .. tostring(state_break))
    end
    --else
        --toggle_source_visibility(source_name_to_toggle, true)
    --end
end

function script_description()
    return "Скрипт для управления источниками сцены и аудио элементами"
end

function script_load(settings)
    hotkey_id = obs.obs_hotkey_register_frontend("toggle_source_visibility", "Toggle Source Visibility", on_event)
    local hotkey_save_array = obs.obs_data_get_array(settings, "toggle_source_visibility")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
    --obs.obs_frontend_add_event_callback(on_event)
end

function script_save(settings)
    local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    obs.obs_data_set_array(settings, "toggle_source_visibility", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
end

function script_update(settings)
    print(format(
        "script_update: source_name_to_toggle '%s'",
        source_name_to_toggle
    ))
    --source_name_to_toggle = obs.obs_data_get_string(settings, "break")
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "source_name", "Source Name to Toggle", obs.OBS_TEXT_DEFAULT)
    return props
end

-- Примеры вызовов функций
--state_break = toggle_source_visibility("break", state_break)
toggle_audio_source_mute("Desktop Audio", false)
--]]
