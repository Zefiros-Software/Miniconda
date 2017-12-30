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
    virtualenv = {},
    WORKING_DIR = _WORKING_DIR
}

function miniconda.installDir()
    return path.join(zpm.env.getToolsDirectory(), "miniconda")
end

function miniconda.getDir()
    return path.join(miniconda.installDir(), iif(os.ishost("windows"), "Scripts/", "bin"))
end

function miniconda.getPython()
    
    return string.format("%s/python%s", miniconda.getPythonDir(), iif(os.ishost("windows"), ".exe", ""))
end


function miniconda.getPythonDir()
    
    return path.join(miniconda.installDir(), iif(os.ishost("windows"), "", "bin"))
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
        
        miniconda.conda("config --set always_yes yes --set changeps1 no")
        miniconda.conda("update setuptools conda", os.outputoff)
        miniconda.pip("install --upgrade pipenv", os.outputoff)
    end
    
    zpm.assert(miniconda.isInstalled(), "Failed to install miniconda!")
end


function miniconda.pipenv(comm, exec)
    exec = iif(exec ~= nil, exec, os.executef)
    local result, code
    local anaBin = miniconda.getDir()
    if os.ishost("windows") then
        result, code = exec("set PATH=%%PATH%%;%s; && pipenv %s", anaBin, comm)
    else
        result, code = exec("PATH=$PATH:%s && pipenv %s", anaBin, comm)
    end
    return result, code
end

function miniconda.opipenv(comm)
    
    return miniconda.pipenv(comm, os.outputoff)
end

miniconda._venvCache = {}
function miniconda.venv()
    local cdir = os.getcwd()
    if miniconda._venvCache[cdir] then
        return miniconda._venvCache[cdir][1], miniconda._venvCache[cdir][2]
    end

    local dir, code = miniconda.opipenv("--venv")
    if code == 0 then
        miniconda._venvCache[cdir] = {dir, code}
    end
    return dir, code
end

function miniconda.pip(comm, exec)
    exec = iif(exec ~= nil, exec, os.executef)
    local anaBin = miniconda.getDir()
    
    if os.ishost("windows") then
        exec("set PATH=%%PATH%%;%s; && %s/pip %s", anaBin, anaBin, comm)
    else
        exec("PATH=$PATH:%s && %s/python %s/pip %s", anaBin, anaBin, anaBin, comm)
    end
end

function miniconda.conda(comm, exec)
    exec = iif(exec ~= nil, exec, os.executef)
    local anaBin = miniconda.getDir()
    
    if os.ishost("windows") then
        exec("set PATH=%%PATH%%;%s; && %s/conda %s", anaBin, anaBin, comm)
    else
        exec("PATH=$PATH:%s && %s/python %s/conda %s", anaBin, anaBin, anaBin, comm)
    end
end

function miniconda.virtualenv.pipenv(comm, exec)
    exec = iif(exec ~= nil, exec, os.executef)
    
    local result, code
    local current = os.getcwd()
    os.chdir(miniconda.WORKING_DIR)
    
    if os.ishost("windows") then
        result, code = exec("set PATH=%%PATH%%;%s; && pipenv %s", miniconda.getDir(), comm)
    else
        result, code = exec("PATH=$PATH:%s && pipenv %s", miniconda.getDir(), comm)
    end
    
    os.chdir(current)
    
    return result, code
end

function miniconda.virtualenv.opipenv(comm)
    
    return miniconda.virtualenv.pipenv(comm, os.outputoff)
end

function miniconda.virtualenv.pip(comm)
    
    miniconda.virtualenv.pipenv(("run pip %s"):format(comm))
end

function miniconda.virtualenv.conda(comm)
    
    miniconda.virtualenv.pipenv(("run conda %s"):format(comm))
end

function miniconda._isPythonEnabledDirectory(dir)
    
    return os.isfile(path.join(dir, "Pipfile")) or
        os.isfile(path.join(dir, "requirements.txt")) or
        os.isfile(path.join(dir, "conda-requirements"))
end


function miniconda._venvExists(dir)
    local vdir, code = miniconda.opipenv("--venv")
    return code == 0 and os.isdir(vdir)
end

function miniconda._getCondaRequirements(dir)
    
    return path.join(dir, "conda-requirements.txt")
end

function miniconda._installDirectory(dir)
    
    if miniconda.dirs[dir] == nil then
        miniconda.dirs[dir] = true
        
        local current = os.getcwd()
        miniconda.WORKING_DIR = dir
        os.chdir(dir)
        
        
        local dev = iif(dir == _MAIN_SCRIPT_DIR, "--dev", "")
        local installCondaPackages = false
        if not miniconda._venvExists(dir) or zpm.cli.force() then
            miniconda.pipenv(string.format("install --python=\"%s\" %s", miniconda.getPythonDir(), dev))
            
            installCondaPackages = true
        elseif zpm.cli.update() then
            miniconda.pipenv(string.format("update --python=\"%s\" %s", miniconda.getPythonDir(), dev))
            
            installCondaPackages = true
        end
        
        if installCondaPackages and os.isfile(miniconda._getCondaRequirements(dir)) then
            miniconda.virtualenv.pip("install auxlib ruamel_yaml requests pycosat")
            miniconda.virtualenv.pip("install conda==4.2.7")
            miniconda.virtualenv.conda("install -f conda")
            for s in io.lines(miniconda._getCondaRequirements(dir)) do
                miniconda.virtualenv.conda(("install --yes %s"):format(s))
            end
        end
        
        os.chdir(current)
        miniconda.WORKING_DIR = _WORKING_DIR
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
            
            local current = os.getcwd()
            os.chdir(zpm.meta.package.location)
            local result, code = miniconda.venv()
            
            miniconda._installDirectory(zpm.util.getRelativeOrAbsoluteDir(_WORKING_DIR, zpm.meta.package.location))
            
            local python_install = iif(os.ishost("windows") and not os.isfile(miniconda._getCondaRequirements(zpm.meta.package.location)), "Scripts/python", "bin/python")
            if os.ishost("windows") then
                python_install = python_install .. ".exe"
            end
            
            os.chdir(current)
            if code == 0 then
                result = result:gsub("\\", "/")
                defines{
                    "MINICONDA_PATH=\"" .. result .. "\"",
                    "MINICONDA_PYTHON_PATH=\"" .. result .. "/" .. python_install .. "\"",
                }
            end
        end
        return rvalue
end)

return miniconda
