# map 関数ってすごい {#map-function}

## 必要なパッケージ


```r
library(tidyverse)
library(readxl)
library(broom)
```

## データの準備

Rの `iris`^[iris: アヤメ] データで解析を紹介します。
`iris` は `data.frame` として定義されているので、`as_tibble()` を使って `tibble` のクラスを追加します。


```r
iris = iris |> as_tibble()
iris
#> # A tibble: 150 × 5
#>    Sepal.Length Sepal.Width Petal.Length Petal.Width Species
#>           <dbl>       <dbl>        <dbl>       <dbl> <fct>  
#>  1          5.1         3.5          1.4         0.2 setosa 
#>  2          4.9         3            1.4         0.2 setosa 
#>  3          4.7         3.2          1.3         0.2 setosa 
#>  4          4.6         3.1          1.5         0.2 setosa 
#>  5          5           3.6          1.4         0.2 setosa 
#>  6          5.4         3.9          1.7         0.4 setosa 
#>  7          4.6         3.4          1.4         0.3 setosa 
#>  8          5           3.4          1.5         0.2 setosa 
#>  9          4.4         2.9          1.4         0.2 setosa 
#> 10          4.9         3.1          1.5         0.1 setosa 
#> # … with 140 more rows
```

## 説明

`tidyverse` の開発によって、Rでのデータ処理はすこぶる楽になりました。
個人的には、Rでデータ処理するのはとても楽しいです。
そこで、もっともデータ処理を楽にしてくれたのは `map()` 関数です。
実は、数種類の`map()` があります。

* `map()`
* `map_lgl()`, `map_int()`, `map_dbl()`, `map_chr()`

そのほかにもありますが、研究室のコードでは上のものが多いです。
他によく使う関数は `pmap()` と `map2()` です。
`pmap()` は3変数以上を関数に渡したいときに使います。
`map2()` は2変数のバージョンです。

どの `map()` には `.x` と `.f` の引数を渡す必要があります。

* `.x` は list または vector のオブジェクトです。
* `.f` は list/vector のそれぞれの要素に適応したい関数です。

例えば、つぎの list を定義します。


```r
z = list(a = rnorm(10),
         b = rnorm(10),
         c = rnorm(5))
z
#> $a
#>  [1]  0.56070485 -1.04900532 -1.07188379 -1.35703257
#>  [5] -0.70073669  0.33400237 -0.03807663 -0.89896960
#>  [9] -0.28888791  1.00420927
#> 
#> $b
#>  [1] -0.19622921  0.15155366  0.01608215 -2.01419540
#>  [5] -0.88385345  0.25389852 -0.26949414 -1.24770762
#>  [9] -1.45640997 -0.05943824
#> 
#> $c
#> [1]  1.0954953 -0.7787291  1.6558844 -1.6672145  1.7596811
```

それぞれの要素の平均値を出したいなら、次のように `map()` を使います。


```r
map(z, mean)
#> $a
#> [1] -0.3505676
#> 
#> $b
#> [1] -0.5705794
#> 
#> $c
#> [1] 0.4130234
```

`map()`は必ず list として結果を返します。
ベース　(base) R`lapply()` と同じですね。


```r
lapply(z, mean)
#> $a
#> [1] -0.3505676
#> 
#> $b
#> [1] -0.5705794
#> 
#> $c
#> [1] 0.4130234
```

ベースRの `sapply()` のようにベクトルとして返してほしいなら、`map_dbl()` を使います。


```r
map_dbl(z, mean)
#>          a          b          c 
#> -0.3505676 -0.5705794  0.4130234
```

ベースRの `sapply()` の結果と同じです。


```r
sapply(z, mean)
#>          a          b          c 
#> -0.3505676 -0.5705794  0.4130234
```

ちなみに、for-loop でもできますが、研究室では使用を禁じます。


```r
# 良い子はループ使わない。
zout = vector("numeric", 3)
n = length(z)
for(i in 1:n) {
  zout[i] = mean(z[[i]])
}
zout
#> [1] -0.3505676 -0.5705794  0.4130234
```


## `map()` の魅力

`map()`の魅力は `tidyverse` のパイプラインに使えること、`map()` に複雑な関数を渡せること。
結果は `tibble` として返せることかな。
他にあるとおもいますが、使えるようになるとデータ処理は楽しいです。


たとえば、次のようことができます。
`iris` のデータを `tibble` に変換し、`pivot_longer()` に渡して縦長に変えます。
`pivot_longer()` には `Sepal` と `Petal` を含む列を `cols` 引数に渡すようにしています。
変換したあと、`pivot_longer()` が作った `name` の列は `separate()` によって `part` と `measurement` に分けます。


```r
iris_long = iris |> 
  as_tibble() |> 
  pivot_longer(cols = matches("Sepal|Petal")) |> 
  separate(name, c("part", "measurement"))
```

ここでは関数を定義していますが、この関数は複数の t 検定を実施し、その結果を一つの `tibble` にまとめています。
`t.test()` に渡すデータは `filter()` 関数に通しています。
`filter()` は `str_detect()` を使って、 `Species` 列から解析したいデータを抽出しています。
`str_detect()` で処理する列は `Species`、検索する文字列は `pattern` に渡しています。
たとえば、`pattern = "set|ver"` は `set` または `ver` を意味しています。
t 検定の結果を `t12`、`t13`、`t23`の入れます。
こんど、それらを `broom` パッケージの `tidy()` に渡し、`tibble`かします。
`bind_rows()` を使って、縦に結合し、結合した要素の名前を `comparison` にします。


```r
runmultttest = function(df) {
  #t12: setosa - versicolor
  #t13: setosa - virginica
  #t23: versicolor - virginica
   
  t12 = t.test(value ~ part, data = filter(df, str_detect(string = Species, pattern = "set|ver")))
  t13 = t.test(value ~ part, data = filter(df, str_detect(string = Species, pattern = "set|vir")))
  t23 = t.test(value ~ part, data = filter(df, str_detect(string = Species, pattern = "ver|vir")))
  bind_rows("setosa vs. versicolor"    = tidy(t12), 
            "setosa vs. virginica"     = tidy(t13), 
            "versicolor vs. virginica" = tidy(t23), .id = "comparison")
}
```

上のコードチャンクで定義した関数は `iris_long` に適応しますが、
`measurement` ごとに `data` の要素ごとに実施されます。


```r
iris_long = iris_long |> group_nest(measurement) 
iris_long
#> # A tibble: 2 × 2
#>   measurement               data
#>   <chr>       <list<tibble[,3]>>
#> 1 Length               [300 × 3]
#> 2 Width                [300 × 3]
```

つまり、`data` は `map()` を通して、 `runmultttest()` が適応されます。


```r
iris_long |> 
  mutate(tout = map(data, runmultttest)) |> 
  unnest(tout)
#> # A tibble: 6 × 13
#>   measurement             data comparison estimate estimate1
#>   <chr>       <list<tibble[,3> <chr>         <dbl>     <dbl>
#> 1 Length             [300 × 3] setosa vs…    -2.61     2.86 
#> 2 Length             [300 × 3] setosa vs…    -2.29     3.51 
#> 3 Length             [300 × 3] versicolo…    -1.36     4.91 
#> 4 Width              [300 × 3] setosa vs…    -2.31     0.786
#> 5 Width              [300 × 3] setosa vs…    -2.07     1.14 
#> 6 Width              [300 × 3] versicolo…    -1.20     1.68 
#> # … with 8 more variables: estimate2 <dbl>,
#> #   statistic <dbl>, p.value <dbl>, parameter <dbl>,
#> #   conf.low <dbl>, conf.high <dbl>, method <chr>,
#> #   alternative <chr>
```


## `map_dbl()` の使い方

`map_lgl()`, `map_int()`, `map_dbl()`, `map_chr()` シリーズの関数が返すものは N = 1 のベクトルです。
よって、適応する関数はベクトルを返すようにくみましょう。

`\(df) {...}` は無名関数と呼びます。
`\(df) {...}` は `function(df) {...}` の諸略です。
このとき、関数は `summarise()` を通して、`tibble()`を返すので、エラーが発生します。


```r
iris_long |> 
  mutate(out = map_dbl(data, \(df) {
    df |> 
      group_by(Species, part) |> 
      summarise(value = mean(value))
  }))
#> Error in `mutate()`:
#> ! Problem while computing `out = map_dbl(...)`.
#> Caused by error in `stop_bad_type()`:
#> ! Result 1 must be a single double, not a vector of class `grouped_df/tbl_df/tbl/data.frame` and of length 3
```

次のコードは `pull()` を使って、`mean` だけ返すようにしたが、
N > 1 のベクトルなので、エラーが発生した。

```r
iris_long |> 
  mutate(out = map_dbl(data, \(df) {
    df |> 
      group_by(Species, part) |> 
      summarise(value = mean(value)) |> pull(mean)
  }))
#> Error in `mutate()`:
#> ! Problem while computing `out = map_dbl(...)`.
#> Caused by error:
#> ! Must extract column with a single valid subscript.
#> ✖ Subscript `var` has the wrong type `function`.
#> ℹ It must be numeric or character.
```

`Species`, `measurement`, `part` ごとに `map_dbl()` で平均を求めたいので、
一旦 `iris_long` の `data` のネスティングを作り直します。


```r
iris_long |> 
  unnest(data) |> 
  group_nest(Species, measurement, part) |> 
  mutate(out = map_dbl(data, \(df) {
    # mean(df$value) # でもOK
    df |> summarise(value = mean(value)) |> pull(value)
  }))
#> # A tibble: 12 × 5
#>    Species    measurement part                data   out
#>    <fct>      <chr>       <chr> <list<tibble[,1]>> <dbl>
#>  1 setosa     Length      Petal           [50 × 1] 1.46 
#>  2 setosa     Length      Sepal           [50 × 1] 5.01 
#>  3 setosa     Width       Petal           [50 × 1] 0.246
#>  4 setosa     Width       Sepal           [50 × 1] 3.43 
#>  5 versicolor Length      Petal           [50 × 1] 4.26 
#>  6 versicolor Length      Sepal           [50 × 1] 5.94 
#>  7 versicolor Width       Petal           [50 × 1] 1.33 
#>  8 versicolor Width       Sepal           [50 × 1] 2.77 
#>  9 virginica  Length      Petal           [50 × 1] 5.55 
#> 10 virginica  Length      Sepal           [50 × 1] 6.59 
#> 11 virginica  Width       Petal           [50 × 1] 2.03 
#> 12 virginica  Width       Sepal           [50 × 1] 2.97
```

エラーがなくなりましたが、グループごとの平均値をもとめたいなら、`summarise()` のほうがいいですね。


```r
iris_long |> 
  unnest(data) |> 
  group_by(Species, measurement, part) |> 
  summarise(value = mean(value))
#> # A tibble: 12 × 4
#> # Groups:   Species, measurement [6]
#>    Species    measurement part  value
#>    <fct>      <chr>       <chr> <dbl>
#>  1 setosa     Length      Petal 1.46 
#>  2 setosa     Length      Sepal 5.01 
#>  3 setosa     Width       Petal 0.246
#>  4 setosa     Width       Sepal 3.43 
#>  5 versicolor Length      Petal 4.26 
#>  6 versicolor Length      Sepal 5.94 
#>  7 versicolor Width       Petal 1.33 
#>  8 versicolor Width       Sepal 2.77 
#>  9 virginica  Length      Petal 5.55 
#> 10 virginica  Length      Sepal 6.59 
#> 11 virginica  Width       Petal 2.03 
#> 12 virginica  Width       Sepal 2.97
```

`map2()` を使えば、 2変数渡せます。
ここでは `map2_dbl()` を使っています。


```r
iris |> 
  mutate(LW = map2_dbl(Petal.Length, Petal.Width, \(l,w) {
    (l * w)
  })) 
#> # A tibble: 150 × 6
#>    Sepal.Length Sepal.Width Petal.Length Petal.Width Species
#>           <dbl>       <dbl>        <dbl>       <dbl> <fct>  
#>  1          5.1         3.5          1.4         0.2 setosa 
#>  2          4.9         3            1.4         0.2 setosa 
#>  3          4.7         3.2          1.3         0.2 setosa 
#>  4          4.6         3.1          1.5         0.2 setosa 
#>  5          5           3.6          1.4         0.2 setosa 
#>  6          5.4         3.9          1.7         0.4 setosa 
#>  7          4.6         3.4          1.4         0.3 setosa 
#>  8          5           3.4          1.5         0.2 setosa 
#>  9          4.4         2.9          1.4         0.2 setosa 
#> 10          4.9         3.1          1.5         0.1 setosa 
#> # … with 140 more rows, and 1 more variable: LW <dbl>
```

`pmap()` の場合、渡す変数は list にまとめてから渡しましょう。


```r
iris |> 
  mutate(out = pmap_dbl(list(Petal.Length, Petal.Width, 
                             Sepal.Length, Sepal.Width), \(pl,pw, sl, sw) {
                               (pl * pw) / (sl * sw)
                             })) 
#> # A tibble: 150 × 6
#>    Sepal.Length Sepal.Width Petal.Length Petal.Width Species
#>           <dbl>       <dbl>        <dbl>       <dbl> <fct>  
#>  1          5.1         3.5          1.4         0.2 setosa 
#>  2          4.9         3            1.4         0.2 setosa 
#>  3          4.7         3.2          1.3         0.2 setosa 
#>  4          4.6         3.1          1.5         0.2 setosa 
#>  5          5           3.6          1.4         0.2 setosa 
#>  6          5.4         3.9          1.7         0.4 setosa 
#>  7          4.6         3.4          1.4         0.3 setosa 
#>  8          5           3.4          1.5         0.2 setosa 
#>  9          4.4         2.9          1.4         0.2 setosa 
#> 10          4.9         3.1          1.5         0.1 setosa 
#> # … with 140 more rows, and 1 more variable: out <dbl>
```

















