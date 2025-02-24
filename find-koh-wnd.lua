obs = obslua

local source_name = "current_project"
local window_names = {
    "lapsha",
    "vector font",
    "color worms",
    "proekt80",
    "magic",
    "2048",
}

local function os_capture(cmd)
    local f = io.popen(cmd, 'r')
    local s = f:read('*a')
    f:close()
    return s
end

function log_windows(windows)
    print("📋 Доступные окна:")
    for i, win in ipairs(windows) do
        print(string.format("  [%d] ID: %s | Class: %s | Title: %s", i, win.id, win.class, win.title))
    end
end

function get_windows_list()
    local windows = {}
    local output = os_capture("wmctrl -lx")
    for line in output:gmatch("[^\r\n]+") do
        local id, _, class, _, title = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.+)$")
        if id and class and title then
            table.insert(windows, {id = id, class = class:lower(), title = title:lower()})
        else
            print("⚠️ Ошибка парсинга строки wmctrl: " .. line)
        end
    end
    return windows
end

function find_window()
    local windows = get_windows_list()
    log_windows(windows)
    for _, win in ipairs(windows) do
        for _, name in ipairs(window_names) do
            local lower_name = name:lower()
            if win.title:find(lower_name, 1, true) or win.class:find(lower_name, 1, true) then
                print("✅ Найдено подходящее окно: " .. win.title)
                return win
            end
        end
    end
    print("⚠️ Нет подходящих окон.")
    return nil
end

function set_window_capture(win)
    local source = obs.obs_get_source_by_name(source_name)
    if source then
        local settings = obs.obs_source_get_settings(source)
        --local window_string = win.class .. ":" .. win.title .. ":"
        local window_string = "2048"
        obs.obs_data_set_string(settings, "window", window_string)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)

        local scene_source = obs.obs_frontend_get_current_scene()
        local scene = obs.obs_scene_from_source(scene_source)
        local scene_item = obs.obs_scene_find_source(scene, source_name)
        if scene_item then
            obs.obs_sceneitem_set_visible(scene_item, true)
            print("👁️ Источник '" .. source_name .. "' теперь видим.")
        else
            print("❌ Элемент сцены '" .. source_name .. "' не найден.")
        end

        obs.obs_source_release(scene_source)
        obs.obs_source_release(source)
    else
        print("❌ Источник '" .. source_name .. "' не найден.")
    end
end

function hide_window_capture()
    local scene_source = obs.obs_frontend_get_current_scene()
    local scene = obs.obs_scene_from_source(scene_source)
    local scene_item = obs.obs_scene_find_source(scene, source_name)
    if scene_item then
        obs.obs_sceneitem_set_visible(scene_item, false)
        print("🚫 Источник '" .. source_name .. "' скрыт.")
    else
        print("❌ Элемент сцены '" .. source_name .. "' не найден.")
    end
    obs.obs_source_release(scene_source)
end

function update_window_capture()
    print("\n🔍 Запуск проверки окон...")
    local win = find_window()
    if win then
        set_window_capture(win)
    else
        --hide_window_capture()
    end
end

function script_load(settings)
    print("📌 Скрипт запущен. Проверка каждые 5 секунд.")
    obs.timer_add(update_window_capture, 5000)
end

function script_unload()
    obs.timer_remove(update_window_capture)
    print("🛑 Скрипт остановлен.")
end

function script_description()
    return "Ищет окно из списка по названию и классу, включает/выключает источник current_project."
end


local I = require "inspect"
print(I(get_windows_list()))
