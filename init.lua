--[[ @cond ___LICENSE___
-- Copyright (c) 2017 Zefiros Software.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @endcond
--]]
miniconda = {
    path = "",
    virtualenvs = {},
    dirs = {},
    virtualenv = {}
}

function miniconda.installDir()
    return path.join(zpm.env.getToolsDirectory(), "miniconda")
end

function miniconda.getDir()
    return path.join(miniconda.installDir(), iif(os.ishost("windows"), "Scripts/", "bin"))
end

function miniconda.isInstalled()
    
    local anaBin = miniconda.getDir()
    local result, errorCode = os.outputoff("%s/conda --version", anaBin)
    return result and result:gsub("conda %d+%.%d+%.%d+", "") ~= result
end

function miniconda.install()
    
    if not miniconda.isInstalled() then
        
        noticef("Downloading miniconda...")
        if os.ishost("windows") then
            local file = path.join(zpm.env.getTempDirectory(), "Miniconda3-latest-Windows-x86_64.exe"):gsub("/", "\\")
            http.download("https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe", file)
            
            os.executef("start /wait \"\" %s /RegisterPython=0 /AddToPath=0 /S /D=%s", file, miniconda.installDir():gsub("/", "\\"))
            os.remove(file)
        
        elseif os.ishost("macosx") then
            
            local file = path.join(zpm.env.getTempDirectory(), "Miniconda3-latest-MacOSX-x86_64.sh")
            http.download("https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh", file)
            os.executef("bash %s -b -f -p %s", file, miniconda.installDir())
            
            os.remove(file)
        
        elseif os.ishost("linux") then
            
            local file = path.join(zpm.env.getTempDirectory(), "Miniconda3-latest-Linux-x86_64.sh")
            http.download("https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh", file)
            os.executef("bash %s -b -f -p %s", file, miniconda.installDir())
            
            os.remove(file)
        
        else
            errorf("This os '%s' is currently not supported!", os.host())
        end
        
        -- Do not show conda environment string
        miniconda.conda("config --set always_yes yes --set changeps1 no")
        
        miniconda.conda("update setuptools conda", os.outputoff)
    end
    
    zpm.assert(miniconda.isInstalled(), "Failed to install miniconda!")
end

function miniconda.run(comm, exec)
    exec = iif(exec ~= nil, exec, os.executef)
    local result, code
    local anaBin = miniconda.getDir()
    if os.ishost("windows") then
        result, code = exec("set PATH=%s;%%PATH%%; && %s", anaBin, comm)
    else
        result, code = exec("PATH=%s:$PATH && %s", anaBin, comm)
    end
    return result, code
end

function miniconda.pip(comm, exec)
    
    return miniconda.run(("pip %s"):format(comm), exec)
end

function miniconda.conda(comm, exec)

    return miniconda.run(("conda %s"):format(comm), exec)
end

function miniconda.virtualenv.run(comm, exec)
    exec = iif(exec ~= nil, exec, os.executef)
    
    local result, code
    
    if os.ishost("windows") then
        result, code = exec("set PATH=%s;%%PATH%%; && activate %s && %s", miniconda.getDir(), miniconda.virtualenv.name(), comm)
    else
        result, code = exec("PATH=%s:$PATH && source activate %s && %s", miniconda.getDir(), miniconda.virtualenv.name(), comm)
    end
    
    return result, code
end

function miniconda._isPythonEnabledDirectory(dir)
    
    return os.isfile(path.join(dir, "environment.yml"))
end

function miniconda.installProject()
    
    local name = miniconda.virtualenv.name()
    if miniconda.dirs[name] == nil then
        miniconda.dirs[name] = true

        local envFile = path.join(zpm.meta.package.location, 'environment.yml')
        
        local exists = miniconda.virtualenv.exists()
        if exists and zpm.cli.force() then
            miniconda.conda(("env remove -n %s"):format(miniconda.virtualenv.name()))         
            exists = false
        end

        if not exists then
            if os.isfile(envFile) then
            
                miniconda.conda(("env create -n %s -f %s"):format(miniconda.virtualenv.name(), envFile))
            else
                miniconda.conda(("env create -n %s"):format(miniconda.virtualenv.name()))
            end
        end
    end
end

function miniconda.virtualenv.name()


    if not zpm.meta.package['name'] or zpm.meta.package['hash'] == "LOCAL" then
        local location = path.getabsolute(zpm.meta.package.location, _MAIN_SCRIPT_DIR)
        if location:endswith("/") then
            location = location:sub(1, -2)
        end

        return string.format("%s-%s", path.getname(location), string.sha1(location):sub(1, 6))
    end

    print(table.tostring(zpm.meta.package))

    return string.format("%s-%s", zpm.meta.package.name, zpm.meta.package.tag)
end

function miniconda.virtualenv.exists()

    local output = miniconda.conda("env list", os.outputoff)
    return output:contains(miniconda.virtualenv.name())
end

function miniconda.virtualenv.location()

    local name = miniconda.virtualenv.name()
    local output = miniconda.conda("env list", os.outputoff)
    print(name, output, "$$$$$$$$$")
    for line in output:gmatch("([^\n]*)\n?") do
        if not line:startswith("#") then
            words = {}
            for word in line:gmatch("%S+") do 
                table.insert(words, word)
            end
            if words[1] == name then
                return words[2]
            end
        end
    end
end

-- events
function miniconda.onLoad()
    
    miniconda.install()
end

-- override
premake.override(_G, "project", function(base, name)
        
    local rvalue = base(name)
    if miniconda.virtualenvs[name] == nil and miniconda._isPythonEnabledDirectory(zpm.meta.package.location) then
        miniconda.virtualenvs[name] = true

        miniconda.installProject()
        local result = miniconda.virtualenv.location()
        local python_install = iif(os.ishost('windows'), 'python.exe', 'bin/python')
        
        result = result:gsub("\\", "/")
        print("MINICONDA_PYTHON_PATH=\"" .. result .. "/" .. python_install .. "\"", "@@@@@@@@@@@@@@")
        defines {
            "MINICONDA_PATH=\"" .. miniconda.virtualenv.location() .. "\"",
            "MINICONDA_PYTHON_PATH=\"" .. result .. "/" .. python_install .. "\"",
        }
    end
    return rvalue
end)

return miniconda
