package.path = package.path .. ";" .. os.getenv("HOME") .. "/obs-scripts/?.lua"
local inspect = require 'inspect'
local format  = string.format

obs = obslua

--------------------------------------------
-- Глобальные состояния
--------------------------------------------
local state_break = false
local state_audio_kbmicro = true
local state_audio_cammicro = true

--------------------------------------------
-- 1. Отслеживание событий OBS
--------------------------------------------
function on_frontend_event(event)
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
        obs.script_log(obs.LOG_INFO, "Трансляция началась!")
    elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
        obs.script_log(obs.LOG_INFO, "Трансляция остановлена!")
    end
end

--------------------------------------------
-- 2. Получить список всех сцен (по именам)
--------------------------------------------
local function get_scene_names()
    local scene_list = obs.obs_frontend_get_scenes()
    local names = {}

    if scene_list ~= nil then
        for i = 1, #scene_list do
            local scene_source = scene_list[i]
            local scene_name = obs.obs_source_get_name(scene_source)
            table.insert(names, scene_name)
        end
        -- Не забываем освобождать ссылки
        for i = 1, #scene_list do
            obs.obs_source_release(scene_list[i])
        end
    end

    return names
end

--------------------------------------------
-- 3. Переключить видимость источника (во всех сценах)
--------------------------------------------
function toggle_source_visibility(source_name, visible)
    obs.script_log(obs.LOG_INFO, "toggle_source_visibility: source_name = " .. source_name)

    local scenes_all = get_scene_names()

    -- ВАЖНО: цикл правильно итерируем
    for _, scene_name in ipairs(scenes_all) do
        local scene_source = obs.obs_get_source_by_name(scene_name)
        if scene_source then
            local scene_as_scene = obs.obs_scene_from_source(scene_source)
            if scene_as_scene then
                local items = obs.obs_scene_enum_items(scene_as_scene)
                if items then
                    for _, item in ipairs(items) do
                        local source = obs.obs_sceneitem_get_source(item)
                        if obs.obs_source_get_name(source) == source_name then
                            obs.obs_sceneitem_set_visible(item, visible)
                            obs.script_log(obs.LOG_INFO, 
                                format("Source '%s' in scene '%s' -> visible=%s", 
                                       source_name, scene_name, tostring(visible)))
                        end
                    end
                    obs.sceneitem_list_release(items)
                end
            end
            obs.obs_source_release(scene_source)
        end
    end

    return not visible
end

--------------------------------------------
-- 4. Переключить «мьют» (mute) аудио-источника
--------------------------------------------
function toggle_audio_source_mute(source_name, mute)
    local source = obs.obs_get_source_by_name(source_name)
    if source then
        obs.obs_source_set_muted(source, mute)
        obs.obs_source_release(source)
    end
    return not mute
end

--------------------------------------------
-- 5. Горячая клавиша: on_hotkey
--------------------------------------------
function on_hotkey(pressed)
    if not pressed then
        return
    end

    -- Тут переключаем всё, что нужно
    state_break = toggle_source_visibility("break", state_break)
    state_audio_kbmicro = toggle_audio_source_mute("kbmicro", state_audio_kbmicro)
    state_audio_cammicro = toggle_audio_source_mute("cammicro", state_audio_cammicro)

    obs.script_log(obs.LOG_INFO, "on_hotkey done. state_break=" .. tostring(state_break))
end

--------------------------------------------
-- 6. Функции скрипта (стандартный набор)
--------------------------------------------
function script_description()
    return "Скрипт для управления источниками сцены и аудио элементами во всех сценах."
end

function script_properties()
    local props = obs.obs_properties_create()
    -- Можно добавить поля для выбора имён источников и т.п.
    return props
end

function script_update(settings)
    -- Если что-то хотите считать из GUI-настроек, делаете здесь
end

function script_load(settings)
    -- Регистрируем коллбэк горячей клавиши
    hotkey_id = obs.obs_hotkey_register_frontend("toggle_source_visibility",
                                                 "Toggle Source Visibility",
                                                 on_hotkey)
    local hotkey_save_array = obs.obs_data_get_array(settings, "toggle_source_visibility")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    -- Регистрируем событие OBS
    obs.obs_frontend_add_event_callback(on_frontend_event)
end

function script_save(settings)
    local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    obs.obs_data_set_array(settings, "toggle_source_visibility", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
end

