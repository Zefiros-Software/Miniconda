# Anaconda Installer
To use the [Anaconda](www.continuum.io) installer in [ZPM](zpm.zefiros.eu), just use:

## .package.json

```json
"modules": [
    "Zefiros-Software/Anaconda"
],
"install": "<your-installer>.lua"
```

## `<your-installer>.lua`
Install or update Anaconda:
```lua
local ana = require( "Zefiros-Software/Anaconda", "@head" ) -- or an other version
ana.install()
```

### pip
To install packages using pip:
```lua
ana.pip( "install mkdocs -U" )
```

# Installation Folder
By default this installs Anaconda in the following locations:

| OS        | Location                    |
|-----------|-----------------------------|
| Windows   |  %UserProfile%\zpm-anaconda |
| OSX       |  ~/zpm-anaconda/            |
| Linux     |  ~/zpm-anaconda/            |