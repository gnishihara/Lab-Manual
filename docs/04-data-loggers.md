# ロガーからの読み込み {#data-logger-input}

研究室のデータロガーは主に [Onset Computer Corporation (リンクは国内代理店に飛びます)](https://www.pacico.co.jp/) と [Dataflow Systems Inc. (リンクはメーカーに飛びます)](http://odysseydatarecording.com/) の商品を使っています。

* ティドビットV2 (TidBit V2, UTBI-001)
* ウォーターテンププロ V2 (U22-001)
* U20 ウォーターレベルロガー(標準型・9m) (U20-001-01)
* U26 溶存酸素ロガー (U26-001)
* USBマイクロステーションロガー (H21-USB)
  * 風速センサー (S-WSB-M003)
  * PAR 光量子センサー (S-LIA-M003)
  * 気圧センサー (S-BPB-CM50)
* Odyssey PAR Light logger (旧バージョン)

## 必要なパッケージ



```r
library(tidyverse)
library(lubridate)
library(gnnlab)
```

`gnnlab` は研究室用のパッケージです。
ここにデータロガー読み取り専用関数が入っています。
パッケージのURLは (https://github.com/gnishihara/gnnlab) です。
もちろん、研究室サーバの場合はインストール済みですが、
個人のパソコンにインストールしたいなら、`remote` のパッケージでできます。


```r
remotes::install_github("https://github.com/gnishihara/gnnlab")
```

Onsetのロガー用関数は `read_onset()` です。
これで、上で紹介したすべてのロガーのCSVファイルからデータの読み込みができます。
Microstation の場合は、風速、PAR、気圧センサーだけに対応しています。
他のセンサーを追加したい場合、データファイル送ってくれると追加できるとおもいます。
Dataflow systems のロガーは `read_odyssey()` です。


```r
read_onset()
```

この関数は `read_csv()` のラッパーなので、`tidyverse` パッケージも必要です。

## 使い方



```r
labdata = "~/Lab_Data/kawatea/Temperature/Temp_03_ecser_surface_210326.csv"
ecser = read_onset(labdata)
```


```r
ecser
#> # A tibble: 9,057 × 2
#>    datetime            temperature
#>    <dttm>                    <dbl>
#>  1 2021-03-26 18:00:00        21.2
#>  2 2021-03-26 18:10:00        20.3
#>  3 2021-03-26 18:20:00        19.1
#>  4 2021-03-26 18:30:00        17.5
#>  5 2021-03-26 18:40:00        16.2
#>  6 2021-03-26 18:50:00        15.3
#>  7 2021-03-26 19:00:00        14.9
#>  8 2021-03-26 19:10:00        14.5
#>  9 2021-03-26 19:20:00        14.0
#> 10 2021-03-26 19:30:00        14.0
#> # … with 9,047 more rows
```

`read_onset()` は読み込んだデータが負の値または、水温と溶存酸素濃度の値が 40 を超えた場合、`NA` とします。
不都合の場合は、次のように読み込んでくださし。


```r
ecser = read_csv(labdata, skip = 1)
ecser
#> # A tibble: 9,057 × 3
#>      `#` `日付 時間, GMT+09:00`   `温度, °C`
#>    <dbl> <chr>                         <dbl>
#>  1     1 03/26/2021 06:00:00 午後       21.2
#>  2     2 03/26/2021 06:10:00 午後       20.3
#>  3     3 03/26/2021 06:20:00 午後       19.1
#>  4     4 03/26/2021 06:30:00 午後       17.5
#>  5     5 03/26/2021 06:40:00 午後       16.2
#>  6     6 03/26/2021 06:50:00 午後       15.3
#>  7     7 03/26/2021 07:00:00 午後       14.9
#>  8     8 03/26/2021 07:10:00 午後       14.5
#>  9     9 03/26/2021 07:20:00 午後       14.0
#> 10    10 03/26/2021 07:30:00 午後       14.0
#> # … with 9,047 more rows
```

使いにくい列名なので、`select()` をつかって作り直します。


```r
ecser = ecser |> 
  select(datetime = matches("GMT"),
         temperature = matches("温度"))
ecser
#> # A tibble: 9,057 × 2
#>    datetime                 temperature
#>    <chr>                          <dbl>
#>  1 03/26/2021 06:00:00 午後        21.2
#>  2 03/26/2021 06:10:00 午後        20.3
#>  3 03/26/2021 06:20:00 午後        19.1
#>  4 03/26/2021 06:30:00 午後        17.5
#>  5 03/26/2021 06:40:00 午後        16.2
#>  6 03/26/2021 06:50:00 午後        15.3
#>  7 03/26/2021 07:00:00 午後        14.9
#>  8 03/26/2021 07:10:00 午後        14.5
#>  9 03/26/2021 07:20:00 午後        14.0
#> 10 03/26/2021 07:30:00 午後        14.0
#> # … with 9,047 more rows
```

次は、`datetime`  の修正です。
`chr` から `dttm` の変換します。
このとき、`lubridate` の `parse_date_time()` をつかいます。


```r
locale = Sys.setlocale("LC_TIME", "ja_JP.UTF-8")
ecser |> mutate(datetime = parse_date_time(datetime, "mdyT", locale = locale))
#> # A tibble: 9,057 × 2
#>    datetime            temperature
#>    <dttm>                    <dbl>
#>  1 2021-03-26 18:00:00        21.2
#>  2 2021-03-26 18:10:00        20.3
#>  3 2021-03-26 18:20:00        19.1
#>  4 2021-03-26 18:30:00        17.5
#>  5 2021-03-26 18:40:00        16.2
#>  6 2021-03-26 18:50:00        15.3
#>  7 2021-03-26 19:00:00        14.9
#>  8 2021-03-26 19:10:00        14.5
#>  9 2021-03-26 19:20:00        14.0
#> 10 2021-03-26 19:30:00        14.0
#> # … with 9,047 more rows
```

`locale`はパソコンの環境によって異なりますが、研究室のサーバの場合は
`locale = Sys.setlocale("LC_TIME", "ja_JP.UTF-8")` にしてください。

**研究室のサーバで解析をするなら、`read_onset()` を使うこと！**

## 複数データの読み込み

一度に複数の似たようなデータを読み込むなら、`map()`シリーズの関数でします。


```r
labfolder = "~/Lab_Data/kawatea/Temperature/"
fnames = dir(labfolder, pattern = "Temp_.*arikawa.*surface.*csv", full = TRUE)
```


データ読んで、一つの`tibble` として返す場合は `map_dfr()` をつかう。


```r
map_dfr(fnames, read_onset)
#> # A tibble: 186,608 × 2
#>    datetime            temperature
#>    <dttm>                    <dbl>
#>  1 2017-07-19 09:30:00        29.8
#>  2 2017-07-19 09:40:00        29.7
#>  3 2017-07-19 09:50:00        29.7
#>  4 2017-07-19 10:00:00        29.5
#>  5 2017-07-19 10:10:00        29.9
#>  6 2017-07-19 10:20:00        32.0
#>  7 2017-07-19 10:30:00        32.1
#>  8 2017-07-19 10:40:00        31.7
#>  9 2017-07-19 10:50:00        31.4
#> 10 2017-07-19 11:00:00        35.7
#> # … with 186,598 more rows
```


研究室のデータファイルは、次のように作っているので、ファイル名も`tibble` に残して読んだほうがいい。

`Temp_856_arikawaamamo_surface_200819.csv` は

`観測するデータの種類_ロガー番号_調査地点_場所_設置日.csv` として定義しています。


```r
dout = tibble(fnames) |> mutate(data = map(fnames, read_onset))
dout
#> # A tibble: 40 × 2
#>    fnames                                           data    
#>    <chr>                                            <list>  
#>  1 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  2 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  3 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  4 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  5 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  6 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  7 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  8 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#>  9 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#> 10 /home/gnishihara/Lab_Data/kawatea/Temperature//… <tibble>
#> # … with 30 more rows
```

あとはファイル名から情報を抜き出して、`data` をアンネストするだけです。


```r
dout = dout |> 
  mutate(fnames = basename(fnames)) |> 
  mutate(fnames = str_remove(fnames, ".csv")) |> 
  separate(fnames, 
           c("type", "id", "location", "position", "surveydate"),
           sep = "_") |> 
  unnest(data)
dout
#> # A tibble: 186,608 × 7
#>    type  id       location     position surveydate
#>    <chr> <chr>    <chr>        <chr>    <chr>     
#>  1 Temp  11000843 arikawaamamo surface  170819    
#>  2 Temp  11000843 arikawaamamo surface  170819    
#>  3 Temp  11000843 arikawaamamo surface  170819    
#>  4 Temp  11000843 arikawaamamo surface  170819    
#>  5 Temp  11000843 arikawaamamo surface  170819    
#>  6 Temp  11000843 arikawaamamo surface  170819    
#>  7 Temp  11000843 arikawaamamo surface  170819    
#>  8 Temp  11000843 arikawaamamo surface  170819    
#>  9 Temp  11000843 arikawaamamo surface  170819    
#> 10 Temp  11000843 arikawaamamo surface  170819    
#> # … with 186,598 more rows, and 2 more variables:
#> #   datetime <dttm>, temperature <dbl>
```

































