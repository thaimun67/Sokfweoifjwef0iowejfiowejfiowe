-- // Quantix Hub - RedstoneGuard Loader \\ --
-- [[ Upload this tiny script to RedstoneGuard, configure it with Centurion/Normal Obfuscation ]]

local success, mainScript = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/Quantix_Obfuscated.lua?t=" .. tostring(tick()))
end)

if success and mainScript then
    local payload, compileErr = loadstring(mainScript)
    if payload then
        print("[Quantix] Licensing verified. Launching orchestrator...")
        payload()
    else
        warn("[Quantix Loader] Compilation error: " .. tostring(compileErr))
    end
else
    warn("[Quantix Loader] Whitelist verification failed. Please check your internet connection.")
end
