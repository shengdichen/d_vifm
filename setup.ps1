function ConfigVifm
{
    $p = "$HOME\AppData\Roaming\Vifm"
    New-Item -ItemType Directory $p -ErrorAction SilentlyContinue

    Copy-Item ".\common\vifm\*" $p -Recurse -Force
    Copy-Item ".\windows\vifm\*" $p -Recurse -Force
}

function ConfigLf
{
    Copy-Item ".\windows\lf" "$env:LOCALAPPDATA\." -Recurse -Force

    $p = "$env:LOCALAPPDATA\lf\marks"
    if (-not (Test-Path $p))
    {
        Copy-Item ".\windows\lf-marks" $p
    }
}

ConfigVifm
ConfigLf
