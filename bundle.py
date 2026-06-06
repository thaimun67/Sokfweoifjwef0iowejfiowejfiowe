import os
import re

# Configurations
INPUT_ORCHESTRATOR = "QuantixMain.lua"
LIBRARY_FILE = "QuantixLibrary_v3.lua"
MODULES_DIR = "Modules"
OUTPUT_FILE = "Quantix_Bundled_Release.lua"

def bundle():
    print("[Quantix Bundler] Starting bundle build...")
    
    if not os.path.exists(INPUT_ORCHESTRATOR):
        print(f"Error: Orchestrator file '{INPUT_ORCHESTRATOR}' not found.")
        return
        
    if not os.path.exists(LIBRARY_FILE):
        print(f"Error: UI Library file '{LIBRARY_FILE}' not found.")
        return

    if not os.path.exists(MODULES_DIR):
        print(f"Error: Modules directory '{MODULES_DIR}' not found.")
        return

    # 1. Read the core orchestrator script
    with open(INPUT_ORCHESTRATOR, "r", encoding="utf-8") as f:
        orchestrator_code = f.read()

    # 2. Read the UI Library script
    with open(LIBRARY_FILE, "r", encoding="utf-8") as f:
        library_code = f.read()

    # 3. Gather all module files in the modules folder
    modules_code = []
    modules_code.append("-- // Inlined Modules Database\nlocal InlinedModules = {}\n")
    
    for filename in sorted(os.listdir(MODULES_DIR)):
        if filename.endswith(".lua"):
            module_name = os.path.splitext(filename)[0]
            module_path = os.path.join(MODULES_DIR, filename)
            
            print(f"[Quantix Bundler] Bundling module: {module_name}")
            with open(module_path, "r", encoding="utf-8") as f:
                content = f.read()
                
            # Wrap the module code inside a local factory function to avoid namespace pollution
            wrapped = f"InlinedModules['{module_name}'] = function()\n{content}\nend\n"
            modules_code.append(wrapped)

    modules_section = "\n".join(modules_code)

    # 4. Inline the UI Library
    # Create the inlined library string variable
    library_section = f"-- // Inlined UI Library\nlocal InlinedLibrary = [====[\n{library_code}\n]====]\n"

    # Replace the HTTP request loading the library with local loading
    # Matches: local Library = loadstring(game:HttpGet("..."))()
    lib_http_pattern = r"local Library = loadstring\(game:HttpGet\(.*?QuantixLibrary_v3\.lua.*?\)\)\(\)"
    modified_orchestrator, lib_count = re.subn(lib_http_pattern, "local Library = loadstring(InlinedLibrary)()", orchestrator_code)
    
    if lib_count == 0:
        print("[Quantix Bundler] Warning: Could not find dynamic HTTP UI library loader. Library will not be inlined automatically.")
    else:
        print("[Quantix Bundler] Successfully inlined dynamic HTTP UI library loader.")

    # 5. Replace the dynamic URL-fetching LoadModule function with local lookup
    pattern = r"local function LoadModule\(name\).*?return module\s*end\s*end"
    
    local_load_module_code = """local function LoadModule(name)
    local factory = InlinedModules[name]
    if not factory then
        warn("[Quantix Bundler] Inlined module not found: " .. name)
        return function()
            return setmetatable({}, {
                __index = function() return function() end end
            })
        end
    end
    
    local ok, result = pcall(factory)
    if not ok then
        warn("[Quantix Bundler] Failed to compile inlined " .. name .. ": " .. tostring(result))
        return function()
            return setmetatable({}, {
                __index = function() return function() end end
            })
        end
    end
    
    return function(...)
        local args = {...}
        local runOk, module = pcall(function()
            return result(unpack(args))
        end)
        if not runOk then
            warn("[Quantix Bundler] Failed to initialize " .. name .. ": " .. tostring(module))
            return setmetatable({}, {
                __index = function() return function() end end
            })
        end
        return module
    end
end"""

    # Replace LoadModule in orchestrator
    modified_orchestrator, count = re.subn(pattern, local_load_module_code, modified_orchestrator, flags=re.DOTALL)
    
    if count == 0:
        print("[Quantix Bundler] Warning: Regex replacement did not find default LoadModule function. Manual injection fallback...")
        sub_pattern = r"local ok, result = pcall\(function\(\).*?end\)"
        fallback_sub = """local ok, result = pcall(function()
        local factory = InlinedModules[name]
        if not factory then error("Module not found: " .. name) end
        return factory()
    end)"""
        modified_orchestrator, count = re.subn(sub_pattern, fallback_sub, modified_orchestrator, flags=re.DOTALL)

    # 6. Combine UI Library, Modules section, and Orchestrator code
    # We place the InlinedLibrary and InlinedModules right at the beginning after the State setup
    state_block_end = "getgenv().QuantixState = State\n"
    insertion_point = modified_orchestrator.find(state_block_end)
    
    if insertion_point != -1:
        split_pos = insertion_point + len(state_block_end)
        final_code = (
            modified_orchestrator[:split_pos] +
            "\n" + library_section + "\n" +
            modules_section + "\n" +
            modified_orchestrator[split_pos:]
        )
    else:
        # Prepend if state block not found
        final_code = library_section + "\n" + modules_section + "\n" + modified_orchestrator

    # 7. Write out the final single-file bundle
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(final_code)
        
    print(f"[Quantix Bundler] Successfully built single-file bundle: {OUTPUT_FILE} ({os.path.getsize(OUTPUT_FILE)} bytes)")
    print("[Quantix Bundler] This file is now ready for obfuscation (Centurion / Luraph).")

if __name__ == "__main__":
    bundle()
