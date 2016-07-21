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

local anaBin = os.get() == "windows" and os.getenv("UserProfile") .. "/zpm-anaconda/Scripts/" or os.getenv("HOME") .. "/zpm-anaconda/Scripts/"

local check =  string.format( "%sconda.exe --version", anaBin ) 
local result, errorCode = os.outputof( check )

print( "Conda status ----------------", check, result )

-- check if installed
if result:gsub( "conda %d+%.%d+%.%d+", "" ) == result then

    if os.get() == "windows" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-Windows-x86_64.exe", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-Windows-x86_64.exe" )
        os.executef( "%s /InstallationType=JustMe /RegisterPython=0 /S /D=%%UserProfile%%/zpm-anaconda", file )

        os.remove( file )

    elseif os.get() == "osx" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-MacOSX-x86_64.sh", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-MacOSX-x86_64.sh" )
        os.executef( "%s -p $(HOME)/zpm-anaconda", file )

        os.remove( file )

    elseif os.get() == "linux" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-Linux-x86_64.sh", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-Linux-x86_64.sh" )
        os.executef( "%s -p $(HOME)/zpm-anaconda", file )

        os.remove( file )

    else
        errorf( "This os '%s' is currently not supported!", os.get() ) 
    end
end

os.executef( "%sconda update conda --yes", anaBin )