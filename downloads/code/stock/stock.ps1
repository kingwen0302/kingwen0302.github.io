## 使用powershell查看股票
## kingwen0302@msn.com
## www.mingilin.com

$cfgPath = Join-Path $PSScriptRoot "stock.json"

function loadStockCode() {
    $json = Get-Content $cfgPath | ConvertFrom-Json
    $json
}
## -1: 股票代码;
## 0:"大秦铁路",股票名字;
## 1:"27.55",今日开盘价;
## 2:"27.25",昨日收盘价;
## 3:"26.91",当前价格;
## 4:"27.55",今日最高价;
## 5:"26.20",今日最低价;
## 6:"26.91",竞买价,即“买一"报价;
## 7:"26.92",竞卖价,即“卖一"报价;
## 8:"22114263",成交的股票数,由于股票交易以一百股为基本单位,所以在使用时,通常把该值除以一百;
## 9:"589824680",成交金额,单位为“元",为了一目了然,通常以“万元"为成交金额的单位,所以通常把该值除以一万;
## 10:"4695",“买一"申请4695股,即47手;
## 11:"26.91",“买一"报价;
## 12:"57590",“买二"
## 13:"26.90",“买二"
## 14:"14700",“买三"
## 15:"26.89",“买三"
## 16:"14300",“买四"
## 17:"26.88",“买四"
## 18:"15100",“买五"
## 19:"26.87",“买五"
## 20:"3100",“卖一"申报3100股,即31手;
## 21:"26.92",“卖一"报价
## (22, 23), (24, 25), (26,27), (28, 29)分别为“卖二"至“卖四的情况"
## 30:"2008-01-11",日期;
## 31:"15:05:32",时间;

function ShowOne([string]$content){
    if ($content -match "^\n$") {
    } else{
        $str_splits = $content.Split(',');
        $stockName = $str_splits[0].split('"')

        $myStockId = $stockName[0].Split('=')[0].Split('_')[2]
        $myStock = $stockName[1]
        $lastPrice = $str_splits[2]
        $nowPrice = $str_splits[3]
        $higePrice = $str_splits[4]
        $lowPrice= $str_splits[5]

        $exchange = ($str_splits[9] / 10000) -as [int]

        $buy1Count = ($str_splits[10] / 100) -as [int]
        $buy1Price = $str_splits[11]
        $sale1Count = ($str_splits[20] / 100) -as [int]
        $sale1Price = $str_splits[21]

		$diffPrice = $nowPrice - $lastPrice
        $priceP = $diffPrice / $lastPrice
#        [double] $a="{0:0.####}" -f $priceP
#        $b="{0:p2}" -f $a

        $b = "{0:p2}" -f $priceP
        $dp="{0:0.####}" -f $diffPrice

        if([convert]::ToDouble($lastPrice) -gt [convert]::ToDouble($nowPrice) ) {
            $myColor="Green"
        } else {
            $myColor="Red"
        }

        if([convert]::ToDouble($sale1Count) -gt [convert]::ToDouble($buy1Count)) {
            $saleColor = "DarkGreen"
        } else {
            $saleColor = "DarkRed"
        }

        Write-Host -NoNewline -ForegroundColor $myColor ("$myStockId".PadRight(10))
        Write-Host -NoNewline -ForegroundColor $myColor "$myStock`t"
        Write-Host -NoNewline -ForegroundColor $myColor "N$nowPrice".PadRight(10) "(" "$dp".PadLeft(8) "$b".PadLeft(8) ") "
        Write-Host -NoNewline -ForegroundColor $myColor "H$higePrice".PadRight(10)
        Write-Host -NoNewline -ForegroundColor $myColor "L$lowPrice".PadRight(10)
        Write-Host -NoNewline -BackgroundColor $saleColor -ForegroundColor $myColor "S$sale1Price ($sale1Count)".PadRight(20)
        Write-Host -NoNewline -BackgroundColor $saleColor -ForegroundColor $myColor "B$buy1Price ($buy1Count)".PadRight(20)
        Write-Host -NoNewline -ForegroundColor $myColor ("E$exchange").PadRight(6)
        Write-Host ""
    }
}

function ShowOne2([string]$content){
    if ($content -match "^\n$")
    {
    }
    else
    {
        $str_splits = $content.Split(',');
        $stockName = $str_splits[0].split('"')
        $myStockId = $stockName[0].Split('=')[0].Split('_')[3]
        $myStock = $stockName[1]
        $nowPrice = $str_splits[1]
        $ricePrice = $str_splits[2]
        $ricePriceP = $str_splits[3]
        $mon=$str_splits[5].Replace('"','')

        if($ricePrice -match '^-') {
            $myColor="Green"
        } else {
            $myColor="Red"
        }

        Write-Host -NoNewline -ForegroundColor $myColor ("$myStockId".PadRight(10))
        Write-Host -NoNewline -ForegroundColor $myColor "$myStock`t"
        Write-Host -NoNewline -ForegroundColor $myColor "N$nowPrice".PadRight(10) "(" "$ricePrice".PadLeft(8) "$ricePriceP%".PadLeft(8) ") "
        Write-Host -NoNewline -ForegroundColor $myColor ("M$mon".PadRight(20))
        Write-Host ""
    }
}

function ShowOne4([string]$content){
    if ($content -match "^\n$")
    {
    }
    else
    {
        $str_splits = $content.Split(',');
        $stockName = $str_splits[0].split('"')
        $myStockId = $stockName[0].Split('=')[0].Split('_')[3]
        $myStock = $stockName[1]
        $nowPrice = $str_splits[1]
        $ricePrice = $str_splits[2]
        $ricePriceP = $str_splits[3].Replace('"','')

        if($ricePrice -match '^-') {
            $myColor="Green"
        } else {
            $myColor="Red"
        }

        Write-Host -NoNewline -ForegroundColor $myColor ("$myStockId".PadRight(10))
        Write-Host -NoNewline -ForegroundColor $myColor "$myStock`t"
        Write-Host -NoNewline -ForegroundColor $myColor "N$nowPrice".PadRight(10) "(" "$ricePrice".PadLeft(8) "$ricePriceP%".PadLeft(8) ") "
        Write-Host ""
    }
}

function ShowOne3($stockCode) {

    $date = Get-Date

    Write-Host -BackgroundColor Blue "配置文件: $cfgPath"
    Write-Host -BackgroundColor DarkRed "刷新时间: $date"

    "="*130
    Write-Host -ForegroundColor Yellow "N-当前价格; H-今日最高价格; L-今日最低价格 B-买1价格,买1数量 S-卖1价格,卖1数量 E-交易金额(万元)"
    Write-Host ""
    Write-Host -BackgroundColor DarkRed "`t`t`t`t`t`t`t`tPOWERED BY kingwen0302@msn.com(https://www.mingilin.com)"
    "-"*130

    ## 显示指数
    $sourceURL = "http://hq.sinajs.cn/list=s_sh000001,s_sz399001"
    $wc = New-Object system.net.webclient
    $content = $wc.downloadstring($sourceURL)
    $content.Split(';') | ForEach-Object {ShowOne2 $_ }

    ## 显示国外指数
    ## $sourceURL = "http://hq.sinajs.cn/list=int_dji,int_nasdaq,int_hangseng,int_nikkei,b_TWSE,b_FSSTI"
    ## $wc = New-Object system.net.webclient
    ## $content = $wc.downloadstring($sourceURL)
    ## $content.Split(';') | ForEach-Object {ShowOne4 $_ }

    "-"*130

    ## 显示个股
    $sourceURL = "http://hq.sinajs.cn/list=$stockCode"
    $wc = New-Object system.net.webclient
    $content = $wc.downloadstring($sourceURL)
    $content.Split(';') | ForEach-Object {ShowOne $_ }

    "="*130
}

while(1) {
    Clear-Host

    $json = loadStockCode

    $stockCode = $json.stock_list | ForEach-Object {$_.stock_id}
    $stockCode = $stockCode -Join ","
    ShowOne3 $stockCode

    $refreshTime = $json.refresh_time
    Start-Sleep $refreshTime
}
