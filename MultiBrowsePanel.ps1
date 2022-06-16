Add-Type -AssemblyName PresentationFramework  # WPF 用
Add-Type -AssemblyName System.Windows.Forms   # Timer 用

<# WebView2 用アセンブリロード #>
[void][reflection.assembly]::LoadFile((Join-Path $PSScriptRoot "lib\Microsoft.Web.WebView2.Wpf.dll"))  # microsoft.web.webview2.1.0.1222-prerelease 想定
[void][reflection.assembly]::LoadFile((Join-Path $PSScriptRoot "lib\Microsoft.Web.WebView2.Core.dll")) # microsoft.web.webview2.1.0.1222-prerelease 想定

<# XAML にて Window 構築 #>
[xml]$xaml  = (Get-Content (Join-Path $PSScriptRoot .\ui01.xaml))
$nodeReader = (New-Object System.XML.XmlNodeReader $xaml)
$window     = [Windows.Markup.XamlReader]::Load($nodeReader)

<# Get Configuration #>
$panelConfigs = Get-Content (Join-Path $PSScriptRoot .\PanelConfig.json) | ConvertFrom-Json

$maxRow    = $panelConfigs.Length
$maxColumn = ($panelConfigs | %{ $_.Length} | Measure-Object -Maximum).Maximum

<# Contols #>
$grid = $window.findName("OverallGrid")

<# Controls Settings #>
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
        $webview2.Source = [uri]$config.url
        $webview2.CreationProperties = New-Object 'Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties'
        $webview2.CreationProperties.UserDataFolder = (Join-Path $PSScriptRoot "data")

        [System.Windows.Controls.Grid]::SetRow($webview2, $rowCount)
        [System.Windows.Controls.Grid]::SetColumn($webview2, $columnCount)

        $grid.Children.Add($webview2)

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
