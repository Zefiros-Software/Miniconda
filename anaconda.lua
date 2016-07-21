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

local bin = "$HOME/zpm-anaconda/bin/"
if os.get() == "windows" then
    bin = "%UserProfile%\zpm-anaconda"
end


local result, errorCode = os.outputof( string.format( "%s/conda --version", bin ) )

-- check if installed
if result:gsub( "conda %d+%.%d+%.%d+", "" ) == result then

    if os.get() == "windows" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-Windows-x86_64.exe", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-Windows-x86_64.exe" )
        os.executef( "%s /InstallationType=JustMe /RegisterPython=0 /S /D=%%UserProfile%%\zpm-anaconda /S", file )

        os.remove( file )

    elseif os.get() == "osx" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-MacOSX-x86_64.sh", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-MacOSX-x86_64.sh" )
        os.executef( "%s -p $HOME/zpm-anaconda", file )
        os.execute( "export PATH=%"$HOME/zpm-anaconda/bin:$PATH%"" )

        os.remove( file )

    elseif os.get() == "linux" then

        zpm.util.download( "http://repo.continuum.io/archive/Anaconda3-4.1.1-Linux-x86_64.sh", zpm.temp, "*" )
        local file = string.format( "%s/%s", zpm.temp, "Anaconda3-4.1.1-Linux-x86_64.sh" )
        os.executef( "%s -p $HOME/zpm-anaconda", file )
        os.execute( "export PATH=%"$HOME/zpm-anaconda/bin:$PATH%"" )

        os.remove( file )

    else
        errorf( "This os '%s' is currently not supported!", os.get() ) 
    end

else
    os.executef( "%s/conda update conda -y", bin )
end