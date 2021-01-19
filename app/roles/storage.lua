

local function init_spaces()
    local data = box.schema.space.create('data', {
        format = {
            {'key', 'string'},
            {'bucket_id', 'unsigned'},
            {'value', 'string'},
        },
        if_not_exists = true,
    })
    data:create_index('key', {
        type = 'hash',
        parts = {'key'},
        if_not_exists = true,
    })
    data:create_index('bucket_id', {
        parts = {'bucket_id'},
        unique = false,
        if_not_exists = true,
    })
end

local function data_add(data)
  local log = require('log')
    log.info('adding data ...')

  local json = require('json')
  local data_value = json.encode(data.value)
    box.begin()
    box.space.data:insert({
        data.key,
        data.bucket_id,
        data_value
    })
    box.commit()
    return true
end


local function data_get(data_id)
    local log = require('log')
    log.info('getting data ...')
    local data = box.space.data:get(data_id)

    if data == nil then
        return nil
    end
    data = {
        data_id = data.data_id;
        value = data.value;
    }
    return data
end

local function data_update(data_id,datainfo)
    local json = require('json')
    local log = require('log')
    log.info('updating data ...')
    datainfo = json.encode(datainfo)
    local data = box.space.data:update(data_id, {{'=', 3, datainfo}})
    if data == nil then
        return nil
    end
    return true
end

local function data_delete(data_id)
    local log = require('log')
    log.info('deleting data ...')
    local data = box.space.data:delete(data_id)

    if data == nil then
        return nil
    end
    return true
end



local exported_functions = {
    data_add = data_add,
    data_get = data_get,
    data_update = data_update,
    data_delete = data_delete,
}

local function init(opts)
    if opts.is_master then
        init_spaces()

        for name in pairs(exported_functions) do
            box.schema.func.create(name, {if_not_exists = true})
            box.schema.role.grant('public', 'execute', 'function', name, {if_not_exists = true})
        end
    end

    for name, func in pairs(exported_functions) do
        rawset(_G, name, func)
    end

    return true
end


return {
    role_name = 'storage',
    init = init,
    dependencies = {
        'cartridge.roles.vshard-storage',
    },
}
