Param(
    [switch]$Init,
    [string]$PanelConfigFile
)

Add-Type -AssemblyName PresentationFramework  # WPF 用
Add-Type -AssemblyName System.Windows.Forms   # Timer 用

$libWebView2Wpf    = (Join-Path $PSScriptRoot "lib\Microsoft.Web.WebView2.Wpf.dll")
$libWebView2Core   = (Join-Path $PSScriptRoot "lib\Microsoft.Web.WebView2.Core.dll")
$libWebview2Loader = (Join-Path $PSScriptRoot "lib\WebView2Loader.dll")

if ($Init) {
    # 初期セットアップ用の処理
    Write-Host "WebView2 ライブラリ取得を行います。既に取得している場合は一度削除し再取得します。"

    if (Test-Path "lib") {
        Remove-Item "lib" -Recurse
    }

    Find-Package -Name  Microsoft.Web.WebView2 -Source https://www.nuget.org/api/v2 | Save-Package -Path $PSScriptRoot
    $nugetFile    = Get-Item *.nupkg
    $nugetZipFile = $nugetFile.FullName + ".zip"
    Rename-Item $nugetFile $nugetZipFile
    Expand-Archive $nugetZipFile

    if (-not (Test-Path "lib")) {
        New-Item -type Directory "lib"
    }
    Copy-Item (Join-Path $nugetFile "\lib\net45\Microsoft.Web.WebView2.Core.dll") "lib"
    Copy-Item (Join-Path $nugetFile "\lib\net45\Microsoft.Web.WebView2.Wpf.dll") "lib"
    Copy-Item (Join-Path $nugetFile "\runtimes\win-x64\native\WebView2Loader.dll") "lib"

    Remove-Item $nugetFile -Recurse
    Remove-Item $nugetZipFile

    if ((Test-Path $libWebView2Wpf) -and (Test-Path $libWebView2Core) -and (Test-Path $libWebview2Loader)) {
        Read-Host "取得に成功しました[Enter]"
        exit 0
    }
    else {
        Read-Host "取得に失敗しました[Enter]"
        exit 1
    }
}


if ($PanelConfigFile.Length -eq 0) {
    $PanelConfigFile = (Join-Path $PSScriptRoot "PanelConfig.json")
}

<# WebView2 用アセンブリロード #>
[void][reflection.assembly]::LoadFile($libWebView2Wpf)
[void][reflection.assembly]::LoadFile($libWebView2Core)

<# XAML にて Window 構築 #>
[xml]$xaml  = (Get-Content (Join-Path $PSScriptRoot "ui01.xaml"))
$nodeReader = (New-Object System.XML.XmlNodeReader $xaml)
$window     = [Windows.Markup.XamlReader]::Load($nodeReader)

<# Get Configuration #>
$panelConfigRoot = Get-Content $PanelConfigFile | ConvertFrom-Json
$panelConfigs = $panelConfigRoot.PanelConfig

$maxRow    = $panelConfigs.Length
$maxColumn = ($panelConfigs | %{ $_.Length} | Measure-Object -Maximum).Maximum

<# Contols #>
$grid = $window.findName("OverallGrid")

<# Controls Settings #>
if ($panelConfigRoot.Title) {
    $window.title = $panelConfigRoot.Title
}
if ($panelConfigRoot.Icon) {
    $window.icon  = $panelConfigRoot.Icon
}

for ($i = 0; $i -lt $maxColumn; $i++) {
    $columDef = New-Object System.Windows.Controls.ColumnDefinition
    $grid.ColumnDefinitions.add($columDef)
}
for ($i = 0; $i -lt $maxRow; $i++) {
    $rowDef = New-Object System.Windows.Controls.RowDefinition
    $grid.RowDefinitions.add($rowDef)
}

<# webView2 Settings #>
$panelConfigs | ForEach-Object {$rowCount = 0}{
    $panelConfigsRow = $_
    $panelConfigsRow | ForEach-Object {$columnCount = 0}{
        $config = $_

        $webview2 = New-Object Microsoft.Web.WebView2.Wpf.WebView2
        $webview2.CreationProperties = New-Object 'Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties'
        $webview2.CreationProperties.UserDataFolder = (Join-Path $PSScriptRoot "data")

        [System.Windows.Controls.Grid]::SetRow($webview2, $rowCount)
        [System.Windows.Controls.Grid]::SetColumn($webview2, $columnCount)

        $grid.Children.Add($webview2)
        $webview2.Source = [uri]$config.url

        <# リロード処理 #>
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 1000 * $config.RefreshRate
        $timer.add_Tick((&{
            Param($w)
            return {
                $w.Reload()
            }.GetNewClosure()
        } $webview2))
        $timer.Start()

        <# リロード後のスクロール処理 #>
        [void]$webview2.Add_ContentLoading((&{
            Param($p)
            $w = $p[0]
            $c = $p[1]
            return {
                $st = $c.ScrollTo;
                $w.ExecuteScriptAsync(
@"
                console.log('${st}');
                window.addEventListener('DOMContentLoaded', (event) => {
                    document.querySelector('${st}').scrollIntoView()
                });
"@
                )
            }.GetNewClosure()
        } ($webview2,$config)))

        $columnCount++
    }
    $rowCount++
}

<# for Events ScriptBlock #>
# nothing

<# add Event Listeners #>
# nothing

<# Window の表示 #>
[void]$window.ShowDialog()
$window.Close()
