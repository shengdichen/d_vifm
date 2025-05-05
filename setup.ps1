function CopyConfig
{
    $p = "$HOME\AppData\Roaming\Vifm"
    New-Item -ItemType Directory $p -ErrorAction SilentlyContinue

    Copy-Item ".\common\vifm\*" $p -Recurse -Force
    Copy-Item ".\windows\vifm\*" $p -Recurse -Force
}

CopyConfig
