--- Makes working with events in Factorio a lot more simple.
-- <p>By default, Factorio allows you to register **only one handler** to an event.
-- <p>This module lets you easily register **multiple handlers** to an event.
-- <p>Using this module is as simple as replacing @{LuaBootstrap.on_event|script.on_event} with @{Event.register}.
-- <blockquote>
-- Due to the way that Factorio's event system works, it is not recommended to intermingle `script.on_event` and `Event.register` in a mod.
-- <br>This module hooks into Factorio's event system, and using `script.on_event` for the same event will change which events are registered.
-- </blockquote>
-- <blockquote>
-- This module is multiplayer desync safe when registering dynamic events (as in defines.events) from events/from console
-- <br>This module WILL DESYNC when registering dynamic custom (as in generate_event_name) events UNLESS the event names are generated during initial file load.
-- <br>Generating event names in a remote interface, command, or dynamic event handler currently WILL DESYNC until this is patched
-- <br>Removing dynamic events is safe anytime, dynamically removing non-dynamic events WILL DESYNC currently
-- </blockquote>
-- @module Event
-- @usage local Event = require('lualib/event')

--Holds the event registry
local event_registry = {}

--Map IDs to names
local event_names = {}
for k,v in pairs(defines.events) do
    event_names[v] = k
end

local custom_events = {} -- Holds custom event ids
local custom_event_names = {}

local Event = {
    _module = 'Event',
    core_events = {
        on_init = 'on_init',
        on_load = 'on_load',
        on_configuration_changed = 'on_configuration_changed',
        init = 'on_init',
        load = 'on_load',
        configuration_changed = 'on_configuration_changed',
        init_and_config = {'on_init', 'on_configuration_changed'}
    },
    events = defines.events,
    event_names = event_names,
    custom_events = custom_events,
    custom_event_names = custom_event_names,
    protected_mode = true,
    stop_processing = {}, -- just has to be unique
}

-- Make dynamic registering strictly safe for multiplayer

--Tells Events when it should cache added events dynamically for multiplayer safety
--THIS MUST BE FALSE DURING LOADING
local cache_future_events = false

-- Events must pre-empt all other event handlers for this to work

local bootstrap_register = {
    on_init = function()
        global._event_cache = global._event_cache or {}
        -- cache future events now that loading is complete
        cache_future_events = true
        Event.dispatch({name = 'on_init'})
    end,
    on_load = function()
        -- restore cached dynamic events for new multiplayer connections and persist across save/load
        local cache_registry = global._event_cache
        for i = 1, #cache_registry do
            local cache = cache_registry[i]
            Event.register(cache.event_id, cache.handler, cache.matcher, cache.pattern)
        end
        --TODO: cache removal of non-dynamic events and process here
        --TODO: cache dynamic generate_event_name
        -- cache future events now that loading is complete
        cache_future_events = true
        Event.dispatch({name = 'on_load', tick = -1})
    end,
    on_configuration_changed = function(event)
        event.name = 'on_configuration_changed'
        Event.dispatch(event)
    end
}

local function valid_event_id(id)
    return (tonumber(id) and id >= 0) or ((type(id) == 'string') and not bootstrap_register[id])
end

local function get_event_name(name)
    return event_names[name] or custom_event_names[name] or name or 'unknown'
end

local function get_file_path(append)
    return script.mod_name .. '/Event/' .. append
end

--- Registers a handler for the given events.
-- If a `nil` handler is passed, remove the given events and stop listening to them.
-- <p>Events dispatch in the order they are registered.
-- <p>An *event ID* can be obtained via @{defines.events},
-- @{LuaBootstrap.generate_event_name|script.generate_event_name} which is in <span class="types">@{int}</span>,
-- and can be a custom input name which is in <span class="types">@{string}</span>.
-- <p>The `event_id` parameter takes in either a single, multiple, or mixture of @{defines.events}, @{int}, and @{string}.
-- @usage
-- -- Create an event that prints the current tick every tick.
-- Event.register(defines.events.on_tick, function(event) print event.tick end)
-- -- Create an event that prints the new ID of a train.
-- Event.register(Trains.on_train_id_changed, function(event) print(event.new_id) end)
-- -- Function call chaining
-- Event.register(event1, handler1).register(event2, handler2)
-- @param event_id (<span class="types">@{defines.events}, @{int}, @{string}, or {@{defines.events}, @{int}, @{string},...}</span>)
-- @tparam function handler the function to call when the given events are triggered
-- @tparam[opt=nil] function matcher a function whose return determines if the handler is executed. event and pattern are passed into this
-- @tparam[opt=nil] mixed pattern an invariant that can be used in the matcher function, passed as the second parameter to your matcher
-- @return (<span class="types">@{Event}</span>) Event module object allowing for call chaining
function Event.register(event_id, handler, matcher, pattern)
    assert(event_id, 'missing event_id argument')
    assert(handler and ((type(handler) == 'function') or (type((getmetatable(handler) or {}).__call) == 'function')), 'handler function is missing, use Event.remove to un register events')
    assert((not matcher) or ((type(matcher) == 'function') or (type((getmetatable(matcher) or {}).__call) == 'function')), 'matcher must be a function when present')

    --Recursively handle event id tables
    if type(event_id) == 'table' then
        for _, id in pairs(event_id) do
            Event.register(id, handler)
        end
        return Event
    end

    assert(bootstrap_register[event_id] or valid_event_id(event_id), 'Invalid Event Id, Must be string/int/defines.events')

    -- If the event_id has never been registered before make sure we call the correct script action to register
    -- our Event handler with factorio
    if not event_registry[event_id] then
        event_registry[event_id] = {}

        if type(event_id) == 'string' then
            --String event ids will either be Bootstrap events or custom input events
            if bootstrap_register[event_id] then
                script[event_id](bootstrap_register[event_id])
            else
                script.on_event(event_id, Event.dispatch)
            end
        elseif event_id >= 0 then
            --Positive values will be defines.events
            script.on_event(event_id, Event.dispatch)
        elseif event_id < 0 then
            --Use negative values to register on_nth_tick
            script.on_nth_tick(math.abs(event_id), Event.dispatch)
        end
    end

    local registry = event_registry[event_id]

    --If handler is already registered for this event: ignore, because order is important currently
    local registered    
    for i = 1, #registry do
        registered = registry[i]
        if registered.handler == handler and registered.pattern == pattern and registered.matcher == matcher then
            log('Same handler already registered for event ' .. event_id .. ' at position ' .. i .. ', ignoring')
            return Event
        end
    end
    
    --If handler is already registered for this event: remove it for re-insertion at the end.
    -- Until this is DESYNC SAFE it is commented out
    --[[
    if #registry > 0 then
        for i, registered in ipairs(registry) do
            if registered.handler == handler and registered.pattern == pattern and registered.matcher == matcher then
                table.remove(registry, i)
                -- if we are caching dynamic events, also remove from the cache
                if cache_future_events then
                    local cache_registry = global._event_cache
                    for i = #cache_registry, 1, -1 do
                        local cache = cache_registry[i]
                        local is_match = (event_id == cache.event_id) and ((not handler) or (handler and handler == cache.handler)) and ((not matcher) or (matcher and matcher == cache.matcher)) and ((not pattern) or (pattern and pattern == cache.pattern))
                        if is_match then
                            table.remove(cache_registry, i)
                        end
                    end
                end
                log('Same handler already registered for event ' .. event_id .. ' at position ' .. i .. ', moving it to the bottom')
                break
            end
        end
    end
    ]]

    --Finally insert the handler
    -- this is so removes from the cache table are fast/accurate and the order of adds is retained, for multiplayer safety
    local to_insert = {event_id = event_id, handler = handler, matcher = matcher, pattern = pattern}
    table.insert(registry, to_insert)
    if cache_future_events then
        table.insert(global._event_cache, to_insert)
    end
    return Event
end

--- Removes a handler from the given events.
-- <p>When the last handler for an event is removed, stop listening to that event.
-- <p>An *event ID* can be obtained via @{defines.events},
-- @{LuaBootstrap.generate_event_name|script.generate_event_name} which is in <span class="types">@{int}</span>,
-- and can be a custom input name which is in <span class="types">@{string}</span>.
-- <p>The `event_id` parameter takes in either a single, multiple, or mixture of @{defines.events}, @{int}, and @{string}.
-- @param event_id (<span class="types">@{defines.events}, @{int}, @{string}, or {@{defines.events}, @{int}, @{string},...}</span>)
-- @tparam[opt] function handler the handler to remove, if not present remove all registered handlers for the event_id
-- @tparam[opt] function matcher
-- @tparam[opt] mixed pattern
-- @return (<span class="types">@{Event}</span>) Event module object allowing for call chaining

                       

function Event.remove(event_id, handler, matcher, pattern)
    assert(event_id, 'missing event_id argument')

    -- Handle recursion here
    if type(event_id) == 'table' then
        for _, id in pairs(event_id) do
            Event.remove(id, handler)
        end
        return Event
    end
    
    assert(bootstrap_register[event_id] or valid_event_id(event_id), 'Invalid Event Id, Must be string/int/defines.events')

    local registry = event_registry[event_id]
    if registry then
        local found_something = false
        for i = #registry, 1, -1 do
            local registered = registry[i]
            local is_match = ((not handler) or (handler and handler == registered.handler)) and ((not matcher) or (matcher and matcher == registered.matcher)) and ((not pattern) or (pattern and pattern == registered.pattern))
            if is_match then
                table.remove(registry, i)
                -- if we are caching dynamic events, also remove from the cache
                found_something = true
            end
        end
        if found_something then
            if cache_future_events then
                local cache_registry = global._event_cache
                for i = #cache_registry, 1, -1 do
                    local cache = cache_registry[i]
                    local is_match = (event_id == cache.event_id) and ((not handler) or (handler and handler == cache.handler)) and ((not matcher) or (matcher and matcher == cache.matcher)) and ((not pattern) or (pattern and pattern == cache.pattern))
                    if is_match then
                        table.remove(cache_registry, i)
                    end
                end
            end
        end
        if found_something and table.size(registry) == 0 then
            -- Clear the registry data and un subscribe if there are no registered handlers left
            event_registry[event_id] = nil

            if type(event_id) == 'string' then
                -- String event ids will either be Bootstrap events or custom input events
                if bootstrap_register[event_id] then
                    script[event_id](nil)
                else
                    script.on_event(event_id, nil)
                end
            elseif event_id >= 0 then
                -- Positive values will be defines.events
                script.on_event(event_id, nil)
            elseif event_id < 0 then
                -- Use negative values to remove on_nth_tick
                script.on_nth_tick(math.abs(event_id), nil)
            end
        elseif not found_something then
            log('Attempt to deregister already non-registered listener from event: ' .. event_id)
        end
    else
        log('Attempt to deregister already non-registered listener from event: ' .. event_id)
    end
    return Event
end

-- A dispatch helper function
--
-- Call any matcher and, as applicable, the event handler, in protected mode.  Errors are
-- caught and logged to stdout but event processing proceeds thereafter; errors are suppressed.
local function run_protected(event, registered)
    local success, err

    if registered.matcher then
        success, err = pcall(registered.matcher, event, registered.pattern)
        if success and err then
            success, err = pcall(registered.handler, event)
        end
    else
        success, err = pcall(registered.handler, event)
    end

    -- If the handler errors lets make sure someone notices
    if not success and not Event.log_and_print(err) then
        -- no players received the message, force a real error so someone notices
        error(err)
    end

    return success and err or nil
end

--- The user should create a table in this format, for a table that will be passed into @{Event.dispatch}.
-- <p>In general, the user should create an event data table that is in a similar format as the one that Factorio returns.
--> The event data table **MUST** have either `name` or `input_name`.
-- @tfield[opt] int|defines.events name unique event ID generated with @{LuaBootstrap.generate_event_name|script.generate_event_name} ***OR*** @{defines.events}
-- @tfield[opt] string input_name custom input name of an event
-- @field[opt] ... any # of additional fields with extra data, which are passed into the handler registered to an event that this table represents
-- @usage
-- -- below code is from Trains module.
-- -- old_id & new_id are additional fields passed into the handler that's registered to Trains.on_train_id_changed event.
-- local event_data = {
-- old_id = renaming.old_id,
-- new_id = renaming.new_id,
-- name = Trains.on_train_id_changed
-- }
-- Event.dispatch(event_data)
-- @table event_data

--- Calls the handlers that are registered to the given event.
-- <p>Abort calling remaining handlers if any one of them has invalid userdata.
-- <p>Handlers are dispatched in the order they were created.
-- @param event (<span class="types">@{event_data}</span>) the event data table
-- @see https://forums.factorio.com/viewtopic.php?t=32039#p202158 Invalid Event Objects
function Event.dispatch(event)
    assert(type(event) == 'table', 'missing event table')
    --get the registered handlers from name, input_name, or nth_tick in that priority.
    local registry

    if event.name and event_registry[event.name] then
        registry = event_registry[event.name]
    elseif event.input_name and event_registry[event.input_name] then
        registry = event_registry[event.input_name]
    elseif event.nth_tick then
        registry = event_registry[-event.nth_tick]
    end

    if registry then
        -- protected_mode runs the handler and matcher in pcall,
        -- additionaly forcing a crc or inspect can only be
        -- accomplished in protected_mode
        local protected = Event.protected_mode or event.protected_mode

        --add the tick if it is not present, this only affects calling Event.dispatch manually
        --doing the check up here as it will faster than checking every iteration for a constant value
        event.tick = event.tick or (game and game.tick) or 0
        event.define_name = event_names[event.name or '']

        local registered    
        for i = 1, #registry do
            registered = registry[i]
            -- Check for userdata and stop processing this and further handlers if not valid
            -- This is the same behavior as factorio events.
            -- This is done inside the loop as other events can modify the event.
            for _, val in pairs(event) do
                if (type(val) == 'table') and val.__self and not val.valid then
                    return
                end
            end

            if protected then
                if run_protected(event, registered) == Event.stop_processing then
                    return
                end
            elseif registered.matcher then
                if registered.matcher(event, registered.pattern) then
                    if registered.handler(event) == Event.stop_processing then
                        return
                    end
                end
            else
                if registered.handler(event) == Event.stop_processing then
                    return
                end
            end
        end
    end
end

--- Retrieve or Generate an event_name and store it in custom_events
-- @tparam string event_name the custom name for your event.
-- @treturn int the id associated with the event.
-- @usage
-- Event.register(Event.generate_event_name("my_custom_event"), handler)
function Event.generate_event_name(event_name)
    assert(type(event_name) == 'string', 'event_name must be a string.')

    local id
    if type(custom_events[event_name]) == 'number' then
        id = custom_events[event_name]
    else
        id = script.generate_event_name()
        custom_events[event_name] = id
        custom_event_names[id] = event_name
    end
    return id
end

function Event.get_event_name(event_name)
    assert(type(event_name) == 'string', 'event_name must be a string.')
    return custom_events[event_name]
end

-- TODO complete stub
function Event.raise_event(...)
    script.raise_event(...)
end

function Event.get_event_handler(event_id)
    assert(bootstrap_register[event_id] or valid_event_id(event_id), 'Invalid Event Id, Must be string/int/defines.events')
    return {
        script = bootstrap_register(event_id) or (valid_event_id(event_id) and script.get_event_handler(event_id)),
        handlers = event_registry[event_id]
    }
end

--- Retrieve the event_registry
-- @treturn table event_registry
function Event.get_registry()
    return event_registry
end

return Event