function Main
{
    $base = "$HOME\.local\lib\handle"
    $paths = & "$base\split.ps1" $args[0]
    & "$base\main.ps1" $paths
}
Main $args
