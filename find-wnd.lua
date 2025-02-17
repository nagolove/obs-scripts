obs = obslua

-- Название окна, которое ищем
window_title = "koh-project"

-- Имя источника в OBS
source_name = "koh-project"

-- Функция поиска окна
function find_window_by_title(title)
    local sources = obs.obs_enum_sources()
    for _, source in ipairs(sources) do
        local settings = obs.obs_source_get_settings(source)
        local current_title = obs.obs_data_get_string(settings, "window")
        if current_title and string.find(current_title, title) then
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
            return source
        end
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    return nil
end

-- Функция обновления источника
function update_source()
    local source = obs.obs_get_source_by_name(source_name)
    
    if source == nil then
        obs.script_log(obs.LOG_WARNING, "Источник '" .. source_name .. "' не найден. Создаю новый...")
        source = obs.obs_source_create("window_capture", source_name, nil, nil)
        obs.obs_source_release(source)
    end

    local window_source = find_window_by_title(window_title)
    if window_source then
        local settings = obs.obs_source_get_settings(source)
        obs.obs_data_set_string(settings, "window", window_title)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
    else
        obs.script_log(obs.LOG_WARNING, "Окно с заголовком '" .. window_title .. "' не найдено.")
    end

    obs.obs_source_release(source)
end

-- Таймер для поиска окна
function script_tick()
    update_source()
end

-- Настройки плагина
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "window_title", "Название окна", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "source_name", "Имя источника в OBS", obs.OBS_TEXT_DEFAULT)
    return props
end

-- При изменении настроек
function script_update(settings)
    window_title = obs.obs_data_get_string(settings, "window_title")
    source_name = obs.obs_data_get_string(settings, "source_name")
end

-- Инициализация плагина
function script_load(settings)
    obs.timer_add(script_tick, 5000)  -- Проверять каждые 5 секунд
end

