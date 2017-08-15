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

miniconda = {}

function miniconda.getDir()
    return os.get() == "windows" and os.getenv("UserProfile") .. "/zpm-miniconda/Scripts/" or "~/zpm-miniconda/bin/"
end

function miniconda.isInstalled()

    local anaBin = miniconda.getDir()

    local check =  string.format("%sconda --version", anaBin) 
    local result, errorCode = os.outputof(check)

    return result:gsub("conda %d+%.%d+%.%d+", "") ~= result
end

function miniconda.install()
    if not miniconda.isInstalled() then

        if os.ishost("windows") then
            zpm.util.download("https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe", zpm.temp, "*")
            local file = path.join(zpm.temp, "Miniconda3-latest-Windows-x86_64.exe" ):gsub( "/", "\\")

            os.capturef("start /wait \"\" %s /RegisterPython=0 /AddToPath=0 /S /D=%s\\zpm-miniconda", file, os.getenv("UserProfile")))
            os.remove(file)

        elseif os.ishost("macosx") then

            zpm.util.download("https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh", zpm.temp, "*" )
            local file = string.format( "%s/%s", zpm.temp, "Miniconda3-latest-MacOSX-x86_64.sh" )
            os.executef("bash %s -b -p ~/zpm-miniconda", file)

            os.remove(file)

        elseif os.ishost("linux") then

            zpm.util.download("https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh", zpm.temp, "*")
            local file = string.format( "%s/%s", zpm.temp, "Miniconda3-latest-Linux-x86_64.sh" )
            os.executef("bash %s -b -p ~/zpm-miniconda", file)

            os.remove(file)

        else
            errorf("This os '%s' is currently not supported!", os.host()) 
        end
    end

    zpm.assert(miniconda.isInstalled(), "Failed to install miniconda!")

    local anaBin = miniconda.getDir()
    os.executef("%sconda config --set always_yes yes --set changeps1 no", anaBin)
    os.executef("%sconda update conda --yes", anaBin)
end

function miniconda.pip(comm)
    local anaBin = miniconda.getDir()

    if os.ishost("windows") then
        os.executef( "%spip %s", anaBin, comm )
    else
        os.executef( "%s/python3 %spip %s", anaBin, anaBin, comm )
    end
end

function miniconda.conda( comm )
    local anaBin = miniconda.getDir()

    if os.ishost("windows") then
        os.executef( "%sconda %s", anaBin, comm )
    else
        os.executef( "%spython3 %sconda %s", anaBin, anaBin, comm )
    end
end

return miniconda
