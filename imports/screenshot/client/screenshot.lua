local activeScreenshotPromises = {}
local activeUploadPromises = {}
local activeBgRemovePromises = {}

local function generateUniqueId(prefix)
    return string.format('%s_%d_%d', prefix or 'id', GetGameTimer(), math.random(100000, 999999))
end

-- NUI Callback: Screenshot Result
RegisterNUICallback('screenshotResult', function(data, cb)
    local captureId = data and data.captureId
    if captureId and activeScreenshotPromises[captureId] then
        activeScreenshotPromises[captureId]:resolve(data or { success = false, error = 'Empty screenshot response' })
        activeScreenshotPromises[captureId] = nil
    end
    if cb then cb('ok') end
end)

-- NUI Callback: FiveManage Upload Result
RegisterNUICallback('fiveManageUploadResult', function(data, cb)
    local uploadId = data and data.uploadId
    if uploadId and activeUploadPromises[uploadId] then
        activeUploadPromises[uploadId]:resolve(data or { success = false, error = 'Empty upload response' })
        activeUploadPromises[uploadId] = nil
    end
    if cb then cb('ok') end
end)

-- NUI Callback: Remove Background Result
RegisterNUICallback('removeBackgroundResult', function(data, cb)
    local imageId = data and data.imageId
    if imageId and activeBgRemovePromises[imageId] then
        activeBgRemovePromises[imageId]:resolve(data or { success = false, error = 'Empty remove background response' })
        activeBgRemovePromises[imageId] = nil
    end
    if cb then cb('ok') end
end)

--- Takes a screenshot on demand using WebGL GameRenderer
--- @param options table (optional: encoding ['jpg'|'png'], quality [0.1..1.0], hideRadar [bool], crop [{x,y,width,height}], aspect [number|string], removeBg [bool|table], outputWidth [number], outputHeight [number])
--- @return string|nil dataUrl (base64 image data url)
--- @return string|nil error
Lib47.TakeScreenshot = function(options)
    options = options or {}
    local captureId = generateUniqueId('cap')
    local p = promise.new()
    activeScreenshotPromises[captureId] = p

    local hideRadar = options.hideRadar ~= false
    if hideRadar then
        DisplayRadar(false)
    end

    local isBgRemove = options.removeBg or options.removeGreenScreen
    local encoding = isBgRemove and 'png' or (options.encoding or 'jpg')

    SendNUIMessage({
        action = 'CAPTURE_SCREENSHOT',
        captureId = captureId,
        options = {
            encoding = encoding,
            quality = options.quality or (isBgRemove and 1.0 or 0.92),
            crop = options.crop,
            aspect = options.aspect,
            targetAspect = options.targetAspect,
            removeBg = isBgRemove,
            outputWidth = options.outputWidth,
            outputHeight = options.outputHeight,
            centerX = options.centerX,
            centerY = options.centerY,
            hue = options.hue,
            hueTolerance = options.hueTolerance,
            feather = options.feather,
            minSaturation = options.minSaturation,
            minBrightness = options.minBrightness,
            maxBrightness = options.maxBrightness,
        }
    })

    -- Safety timeout: 5 seconds
    SetTimeout(5000, function()
        if activeScreenshotPromises[captureId] == p then
            activeScreenshotPromises[captureId]:resolve({ success = false, error = 'Screenshot request timed out' })
            activeScreenshotPromises[captureId] = nil
        end
    end)

    local result = Citizen.Await(p)

    if hideRadar then
        DisplayRadar(true)
    end

    if result and result.success and result.data then
        return result.data, nil
    else
        return nil, (result and result.error) or 'Screenshot capture failed'
    end
end

--- Uploads a single file or table of files to FiveManage or Discord Webhook via NUI
--- @param fileData string|table Base64 string, data URL, or array of strings/tables
--- @param token string FiveManage API token OR Discord Webhook URL
--- @param path string (optional, default: 'ak47_uploads') Folder path in FiveManage (ignored for Discord)
--- @param mediaType string (optional: 'image' | 'video' | 'audio', default: 'image')
--- @return string|table|nil url (FiveManage URL, Discord CDN URL, or array of URLs if batch)
--- @return string|nil error
Lib47.UploadToFiveManage = function(fileData, token, path, mediaType)
    if not fileData or (type(fileData) == 'string' and fileData == '') or (type(fileData) == 'table' and #fileData == 0) then
        return nil, 'Missing file data to upload'
    end
    if not token or token == '' then
        return nil, 'Missing authorization token or Discord webhook URL'
    end

    path = path or GetInvokingResource()
    mediaType = mediaType or 'image'

    local uploadId = generateUniqueId('upl')
    local p = promise.new()
    activeUploadPromises[uploadId] = p

    local isBatch = type(fileData) == 'table'
    local payload = {
        token = token,
        path = path,
        mediaType = mediaType,
    }

    if isBatch then
        payload.files = fileData
    else
        payload.file = fileData
    end

    SendNUIMessage({
        action = 'UPLOAD_TO_FIVEMANAGE',
        uploadId = uploadId,
        payload = payload,
    })

    -- Safety timeout: 45 seconds for uploads
    SetTimeout(45000, function()
        if activeUploadPromises[uploadId] == p then
            activeUploadPromises[uploadId]:resolve({ success = false, error = 'Upload request timed out' })
            activeUploadPromises[uploadId] = nil
        end
    end)

    local result = Citizen.Await(p)

    if result and result.success then
        if isBatch then
            return result.urls or { result.url }, nil
        else
            return result.url, nil
        end
    else
        return nil, (result and result.error) or 'Upload failed'
    end
end

--- Uploads multiple files to FiveManage in parallel
--- @param filesList table Array of base64 strings or { file = ..., mediaType = ... } tables
--- @param token string FiveManage API token
--- @param path string (optional, default: 'ak47_uploads')
--- @param mediaType string (optional: 'image' | 'video' | 'audio', default: 'image')
--- @return table|nil urls (Array of FiveManage public URLs)
--- @return string|nil error
Lib47.UploadMultipleToFiveManage = function(filesList, token, path, mediaType)
    return Lib47.UploadToFiveManage(filesList, token, path, mediaType)
end

--- Takes a screenshot on-demand and uploads it to FiveManage or Discord in a single call
--- @param token string FiveManage API token OR Discord Webhook URL
--- @param path string (optional, default: 'ak47_uploads') Folder path in FiveManage (ignored for Discord)
--- @param options table (optional, options passed to TakeScreenshot)
--- @return string|nil url (FiveManage or Discord CDN public URL)
--- @return string|nil error
Lib47.TakeScreenshotAndUpload = function(token, path, options)
    local dataUrl, err = Lib47.TakeScreenshot(options)
    if not dataUrl then
        return nil, err
    end
    return Lib47.UploadToFiveManage(dataUrl, token, path or 'ak47_uploads', 'image')
end

--- Removes background (e.g. green screen chroma-keying) and optionally crops to aspect ratio on an existing image Data URL
--- @param dataUrl string Base64 image data URL
--- @param options table (optional: aspect [number|string], hue, hueTolerance, feather, outputWidth, outputHeight, etc.)
--- @return string|nil processedDataUrl (transparent PNG base64)
--- @return string|nil error
Lib47.RemoveBackground = function(dataUrl, options)
    if not dataUrl or dataUrl == '' then
        return nil, 'Missing dataUrl to process'
    end
    options = options or {}
    local imageId = generateUniqueId('bg')
    local p = promise.new()
    activeBgRemovePromises[imageId] = p

    SendNUIMessage({
        action = 'REMOVE_BACKGROUND',
        imageId = imageId,
        dataUrl = dataUrl,
        options = options,
    })

    -- Safety timeout: 15 seconds
    SetTimeout(15000, function()
        if activeBgRemovePromises[imageId] == p then
            activeBgRemovePromises[imageId]:resolve({ success = false, error = 'Remove background request timed out' })
            activeBgRemovePromises[imageId] = nil
        end
    end)

    local result = Citizen.Await(p)
    if result and result.success and result.data then
        return result.data, nil
    else
        return nil, (result and result.error) or 'Remove background failed'
    end
end

-- Register Exports
exports('TakeScreenshot', Lib47.TakeScreenshot)
exports('UploadToFiveManage', Lib47.UploadToFiveManage)
exports('UploadMultipleToFiveManage', Lib47.UploadMultipleToFiveManage)
exports('TakeScreenshotAndUpload', Lib47.TakeScreenshotAndUpload)
exports('RemoveBackground', Lib47.RemoveBackground)

