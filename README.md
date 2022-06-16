# PSMultiBrowsePanel
Microsoft Edge を利用した定期的なリロードを行いながら複数ページをパネル表示するツール。

# ライセンス
MIT ライセンス

# 準備
init.bat を起動する。

init.bat がうまく動作しない場合は、下記の内容より手動で設定を行う。

外部ライブラリとして WebView2 ライブラリを必要とする。
下記にアクセスしてライブラリを取得する。

* NuGet Gallery | Microsoft.Web.WebView2 1.0.1245.22<br />
  https://www.nuget.org/packages/Microsoft.Web.WebView2

取得したファイルが下記のディレクトリ構造になるように配置する。
1.0.1245.22　以上で動作することを確認している。

```
PSMultiBrowsePanel\
  + MultiBrowsePanel.ps1
  + boot.bat
  + ui01.xaml
  + PanelConfig.json
  + README.md
  + lib\
    + Microsoft.Web.WebView2.Core.dll  …  \lib\net45 より取得
    + Microsoft.Web.WebView2.Wpf.dll  …  \lib\net45　より取得
    + WebView2Loader.dll  … runtimes\win-x64\native より取得
  + data\  … スクリプト側で自動生成
```

# 利用方法
boot.bat を起動する。
また、個別の PanelConfig.json を利用したい場合は、boot.bat に対象の設定ファイルをドラッグ&ドロップでかぶせて起動する。


# 設定方法
PanelConfig.json は下記の構造となっている。2次元配列で各 PanelConfig を記載している。1つ目の配列が行、2つ目の配列が列に該当する。
下記で言えば、PanelConfig2は1行目の2列目という事になる。

```
[
  [
    {
        PanelConfig1
    },
    {
        PanelConfig2
    },
    ...
  ],
  [
     ...
  ]
]
```

各 PanelConfig は下記の設定を行う。現在空欄には対応していないので、何かしら値を入れる事。
* URL: 表示させたい　URL の文字列を記載する。
* ScrollTo: 表示後にスクロール位置を調整するが、その表示する要素の Query Selector を指定する(なければ "" で良い)。
* RefreashRate: ページリロードのインターバル期間を [秒] で指定する。

```
        {
            "URL": URL as string,
            "ScrollTo": query selector as string,
            "RefreshRate": seconds as integer
        }
```


