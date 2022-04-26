# データの処理 {#data-wrangling}

## 必要なパッケージ


```r
library(tidyverse)
library(readxl)
```

## データの読み込み

データの読み込みを参考に：\@ref(data-input) 。


```r
rootdatafolder = rprojroot::find_rstudio_root_file("Data/")
filename = '瀬戸内海藻場データ.xlsx'
path = str_c(rootdatafolder, filename)

# fy1990 の処理
RNG = "A4:C27"   # セルの範囲
SHEET = "FY1990" # シート名
d19 = read_xlsx(path, sheet = SHEET, range = RNG)

# fy2018の処理
RNG = "A6:C15"   # 海藻データのセル範囲
SHEET = "FY2018" # シート名
seaweed = read_xlsx(path, sheet = SHEET, range = RNG)
RNG = "E6:G15"   # 海草データのセル範囲
seagrass = read_xlsx(path, sheet = SHEET, range = RNG)
```

## データの処理

データの形（横長から縦長）を変えたいとき、`tidyverse` の `pivot_wider()` と `pivot_longer()` を使うと楽です。

では、FY2018シートの構造をFY1990シートと同じようにします。
横長のデータを縦長に変換するには、`pivot_longer()` を使います。
これは MS Excel の ピボットテーブル (pivot table) の機能とにています。

::: {.rmdnote}


```r
# %>% と |> はパイプ演算子とよびます。
# |> はR 4.1.0 から追加された、ネーティブのパイプ演算子です。
# RStudio の設定を変えなければ、CTRL+SHIFT+M をしたら、%>% が入力されるとおもいます。
# ネーティブパイプを使いたいなら、Tools -> Global Options -> Code に
#   いって、Use native pipe operator のボックスにチェックを入れてください。
# seaweed = seaweed %>% pivot_longer(cols = everything())
seaweed = seaweed |> pivot_longer(cols = everything())
```

:::

ここでの重要なポイントは、必ずピボットしたい列を指定することです。
このとき、すべての列をピボットしたいので、`pivot_longer()` には `cols = everything()` をわたします。
ピボットされた `seaweed` は次のとおりです。
` |> print(n = Inf)` をすると、`tibble` 内容をすべて表示できます^[ちなみに R バージョン 4.1.0 (2021-05-18) からは `|>` が追加されました。これは R のネーティブパイプ演算子です。使い方は tidyverse の `%>%` とほとんど同じです。]。


```r
seaweed |> print(n = Inf)
#> # A tibble: 27 × 2
#>    name  value
#>    <chr> <dbl>
#>  1 東部     14
#>  2 中部     62
#>  3 西部    108
#>  4 東部     93
#>  5 中部    838
#>  6 西部      0
#>  7 東部     12
#>  8 中部    933
#>  9 西部      0
#> 10 東部      8
#> 11 中部    193
#> 12 西部      0
#> 13 東部    444
#> 14 中部    235
#> 15 西部      0
#> 16 東部     85
#> 17 中部    150
#> 18 西部    126
#> 19 東部     NA
#> 20 中部    283
#> 21 西部      0
#> 22 東部     NA
#> 23 中部      3
#> 24 西部      0
#> 25 東部     NA
#> 26 中部     12
#> 27 西部     NA
```

`seagrass` も同じように処理しました。


```r
seagrass = seagrass |> pivot_longer(cols = everything())
```

では、次は `seaweed` と `seagrass` を縦に結合することです。
複数の `tibble` を縦に結合するための関数は `bind_rows()` です。


```r
d20 = bind_rows(seaweed = seaweed, seagrass = seagrass, .id = "type")
```

`seaweed` に `seaweed`、`seagrass` に `seagrass` を渡します。
さらに、`seaweed` と `seagrass` を `type` 変数に書き込みます。


```r
d20　# FY2018 データ
#> # A tibble: 54 × 3
#>    type    name  value
#>    <chr>   <chr> <dbl>
#>  1 seaweed 東部     14
#>  2 seaweed 中部     62
#>  3 seaweed 西部    108
#>  4 seaweed 東部     93
#>  5 seaweed 中部    838
#>  6 seaweed 西部      0
#>  7 seaweed 東部     12
#>  8 seaweed 中部    933
#>  9 seaweed 西部      0
#> 10 seaweed 東部      8
#> # … with 44 more rows
```

実は、次のように `bind_rows()` を実行できますが、データの構造は不都合になります。
どちらも 2つの `tibble` を縦に結合してくれますが、結果は全く違います。
コードと結果の違いをよく確認して、その違いを理解しましょう。


```r
bind_rows(seaweed, seagrass)
#> # A tibble: 54 × 2
#>    name  value
#>    <chr> <dbl>
#>  1 東部     14
#>  2 中部     62
#>  3 西部    108
#>  4 東部     93
#>  5 中部    838
#>  6 西部      0
#>  7 東部     12
#>  8 中部    933
#>  9 西部      0
#> 10 東部      8
#> # … with 44 more rows
```

では、`d20` の `type` ごとの `value` 変数を横にならべたら、`d19` と全く同じ構造になります。


```r
d20 = d20 |> pivot_wider(id_cols = name,
                   names_from = type,
                   values_from = value)
```

このように処理したら、`Warning message` がでます。
`Warning` (ウォーニング) は `Error` (エラー) ほどの問題ではないので、コードは実行されています。
`Error` の場合はコードは実行されません。
この `Warning` で `values are not uniquely identified` と返ってきました。
つまり、各サンプルの値は、区別することができないと意味します。
このデータの場合は、区別しなくても問題ないので、このまま解析を続きます。
それにしても、`seaweed` と `seagrass` の変数 type は `<list>` です。
それぞれの変数の要素に `<dbl [9]>` と記述されています。
各要素に 9つの値が入力されていると意味します。
研究室では、`seaweed` と `seagrass` 変数は nested (ネスト) または、「たたまれている」といいます。
では、この２つの変数を unnest (アンネスト) します。



```r
d20 = d20 |> unnest(c(seaweed, seagrass))
d20
#> # A tibble: 27 × 3
#>    name  seaweed seagrass
#>    <chr>   <dbl>    <dbl>
#>  1 東部       14       71
#>  2 東部       93      145
#>  3 東部       12       94
#>  4 東部        8       82
#>  5 東部      444       49
#>  6 東部       85      100
#>  7 東部       NA       NA
#>  8 東部       NA       NA
#>  9 東部       NA       NA
#> 10 中部       62       63
#> # … with 17 more rows
```

さらに、`name` を `site` (調査海域) に変更します。


```r
d20 = d20 |> rename(site = name)
d20
#> # A tibble: 27 × 3
#>    site  seaweed seagrass
#>    <chr>   <dbl>    <dbl>
#>  1 東部       14       71
#>  2 東部       93      145
#>  3 東部       12       94
#>  4 東部        8       82
#>  5 東部      444       49
#>  6 東部       85      100
#>  7 東部       NA       NA
#>  8 東部       NA       NA
#>  9 東部       NA       NA
#> 10 中部       62       63
#> # … with 17 more rows
```

最後に、`d20` の `NA` データを外します。


```r
d20 = d20 |> drop_na() # NAを外す
d20
#> # A tibble: 23 × 3
#>    site  seaweed seagrass
#>    <chr>   <dbl>    <dbl>
#>  1 東部       14       71
#>  2 東部       93      145
#>  3 東部       12       94
#>  4 東部        8       82
#>  5 東部      444       49
#>  6 東部       85      100
#>  7 中部       62       63
#>  8 中部      838        5
#>  9 中部      933      674
#> 10 中部      193       69
#> # … with 13 more rows
```


これで、`d20` と `d19` はほぼ同じ構造です。
次のコードブロックで、`d19` の変数名を`rename()` を用いて英語に変えます。
日本語の変数名は使いづらくて、バグの原因になることが多いので名前を変更します。

解析をするまえに、`site` を要因 (因子) として設定します。
`levels = c('東部', '中部', '西部')` は因子の順序を指定するためです。
指定しなかった場合、アルファベット順やあいうえお順になります。


```r
d19 = d19 |> 
  rename(site = 調査海域, seaweed = 海藻, seagrass = 海草) |> 
  mutate(site = factor(site, levels = c('東部', '中部', '西部')))
d20 = d20 |> 
  mutate(site = factor(site, levels = c('東部', '中部', '西部')))
```

