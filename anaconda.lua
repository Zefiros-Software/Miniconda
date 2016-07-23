--[[ @cond ___LICENSE___
-- Copyright (c) 2016 Koen Visscher, Paul Visscher and individual contributors.
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

local anaBin = os.get() == "windows" and os.getenv("UserProfile") .. "/zpm-anaconda/Scripts/" or "~/zpm-anaconda/bin/"

local check =  string.format( "%sconda --version", anaBin ) 
local result, errorCode = os.outputof( check )

print( "Conda status ----------------", check, result )

-- check if installed
if result:gsub( "conda %d+%.%d+%.%d+", "" ) == result then

    if os.get() == "windows" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-Windows-x86_64.exe", zpm.temp, "*" )
        local file = path.join( zpm.temp, "Anaconda3-4.1.1-Windows-x86_64.exe" )
        zpm.assert( os.isfile(file), "Failed to download anaconda!" )
        print( file, string.format("start /wait \"\" %s /InstallationType=JustMe /RegisterPython=0 /S /D=%s\\zpm-anaconda", file, os.getenv("UserProfile")) )
        os.executef( "start /wait \"\" %s /InstallationType=JustMe /RegisterPython=0 /S /D=%s\\zpm-anaconda", file, os.getenv("UserProfile") )
        os.remove( file )

    elseif os.get() == "macosx" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-MacOSX-x86_64.sh", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-MacOSX-x86_64.sh" )
        os.executef( "bash %s -b -p ~/zpm-anaconda", file )

        os.remove( file )

    elseif os.get() == "linux" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-Linux-x86_64.sh", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-Linux-x86_64.sh" )
        os.executef( "bash %s -b -p ~/zpm-anaconda", file )

        os.remove( file )

    else
        errorf( "This os '%s' is currently not supported!", os.get() ) 
    end
end

os.executef( "conda config --set always_yes yes --set changeps1 no", anaBin )
os.executef( "%sconda update conda --yes", anaBin )