local vshard = require('vshard')
local cartridge = require('cartridge')
local errors = require('errors')

local err_vshard_router = errors.new_class("Vshard routing error")
local err_httpd = errors.new_class("httpd error")

local function http_data_add(req)
    local log = require('log')
    local json = require('json')

    log.info('start post-handler')

    local jdata = req:read_cached()
    local s, data = pcall(json.decode, jdata)

    if s == false then
        local resp = req:render({json = {
            info = "body is incorrect"
        }})
        resp.status = 400
        log.info('body is incorrect')
        return resp
    end
    data.key = tostring(data.key)

    local bucket_id = vshard.router.bucket_id_strcrc32(data.key)
    data.bucket_id = bucket_id

    local _, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'write',
        'data_add',
        {data}
    )
    if error then
        if error.message == "Duplicate key exists in unique index 'key' in space 'data'" then
            local resp = req:render({json = {
                info = "this key already in use",
                error = error
            }})
            resp.status = 409
            log.info('this key already in use')
            return resp
        end
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 501
        return resp
    end
    local resp = req:render({json = { info = "Successfully created" }})
    resp.status = 201
    log.info('Successfully created')
    return resp
end

local function http_data_get(req)
    local log = require('log')
    log.info('start get-handler')

    local data_id = tostring(req:stash('id'))
    local bucket_id = vshard.router.bucket_id_strcrc32(data_id)

    local data, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'read',
        'data_get',
        {data_id}
    )
    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    if data == nil then
        local resp = req:render({json = { info = "Data not found" }})
        resp.status = 404
        log.info('Data not found')
        return resp
    end

    local resp = req:render({json = data})
    resp.status = 200
    log.info('Output data')
    return resp
end


local function http_data_update(req)
    local log = require('log')
    log.info('start update-handler')

    local data_id = tostring(req:stash('id'))
    local json = require('json')

    local jdata = req:read_cached()
    local s, datainfo = pcall(json.decode, jdata)

    if s == false then
        local resp = req:render({json = {
            info = "body is incorrect"
        }})
        resp.status = 400
        log.info('body is incorrect')
        return resp
    end

    local bucket_id = vshard.router.bucket_id_strcrc32(data_id)
    local res, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'write',
        'data_update',
        {data_id, datainfo.value}
    )

    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    if res == nil then
        local resp = req:render({json = {
            info = "Data not found",
            error = error
        }})
        resp.status = 404
        log.info('Data not found')
        return resp
    end

    local resp = req:render({json = { info = "ok" }})
    resp.status = 200
    log.info('Data was updated')
    return resp
end

local function http_data_delete(req)

    local log = require('log')
    log.info('start deleteing ...')

    local data_id = tostring(req:stash('id'))
    local bucket_id = vshard.router.bucket_id_strcrc32(data_id)

    local res, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'write',
        'data_delete',
        {data_id}
    )

    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    if res == nil then
        local resp = req:render({json = {
            info = "Data not found",
            error = error
        }})
        resp.status = 404
        log.info('Data not found')
        return resp
    end
    local resp = req:render({json = { info = "deleted" }})
    resp.status = 200
    log.info('deleted')
    return resp
end

local function init(opts)
    rawset(_G, 'vshard', vshard)

    if opts.is_master then
        box.schema.user.grant('guest',
            'read,write,execute',
            'universe',
            nil, { if_not_exists = true }
        )
    end

    local httpd = cartridge.service_get('httpd')

    if not httpd then
        return nil, err_httpd:new("not found")
    end

    httpd:route(
        { path = '/kv', method = 'POST', public = true },
        http_data_add
    )
    httpd:route(
        { path = '/kv/:id', method = 'GET', public = true },
        http_data_get
    )
    httpd:route(
        { path = '/kv/:id', method = 'PUT', public = true },
        http_data_update
    )
    httpd:route(
        { path = '/kv/:id', method = 'DELETE', public = true },
        http_data_delete
    )
    return true
end

return {
    role_name = 'api',
    init = init,
    dependencies = {'cartridge.roles.vshard-router'},
}
