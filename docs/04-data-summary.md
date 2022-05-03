# データの集計 {#data-summary}

## 必要なパッケージ


```r
library(tidyverse)
library(readxl)
```

## データの準備

データの読み込みは章\@ref(data-input) を参考にしてください。


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

データの処理は章\@ref(data-wrangling) を参考にしてください。


```r
seaweed = seaweed |> pivot_longer(cols = everything())
seagrass = seagrass |> pivot_longer(cols = everything())

d20 = bind_rows(seaweed = seaweed, seagrass = seagrass, .id = "type")
d20 = d20 |> pivot_wider(id_cols = name,
                   names_from = type, values_from = value, 
                   values_fn = "list")
d20 = d20 |> unnest(c(seaweed, seagrass)) |> rename(site = name) |> drop_na()


d19 = d19 |> 
  rename(site = 調査海域, seaweed = 海藻, seagrass = 海草) |> 
  mutate(site = factor(site, levels = c('東部', '中部', '西部')))
d20 = d20 |> 
  mutate(site = factor(site, levels = c('東部', '中部', '西部')))
```

## 記述統計量

一般的には、数値データは2つの値にまとめられます。

1. Measures of central tendency: 位置の尺度（平均値、中央値、最頻値） 
1. Measures of dispersion: ばらつきの尺度（四分位数間範囲、平均絶対偏差、中央絶対偏差、範囲、標準偏差、分散）


まず、サイコロの関数を定義してから、位置のの尺度とばらつきの尺度を求めましょう。


```r
# n: サイコロの数
# s: サイコロの面の数
roll_dice = function(n = 1, s = 6) {
  face = 1:s
  sum(sample(x = face, size = n, replace = TRUE))
}
```

2つのサイコロを10回投げます。


```r
set.seed(2022) #疑似乱数を固定することで、再現性のあるシミュレーションができる。
x = replicate(10, roll_dice(n = 2, s = 6))
```

サイコロの結果は次のとおりです。


```r
x
#>  [1]  7  9 10 10  4 11  8  6  4  4
```

**平均値, mean, average**


```r
mean(x)
#> [1] 7.3
```

**中央値, メディアン, median**


```r
median(x)
#> [1] 7.5
```

**最頻値, モード, mode**

再頻値を求める。専用の関数がないので、ここで定義して使用します。


```r
mode = function(x) {
  u = unique(x)
  matched = tabulate(match(x,u))
  u[near(matched, max(matched))]
}
mode(x)
#> [1] 4
```


**分散, variance**

分散と標準偏差はもっとも使われるばらつきの尺度です。

$$
Var(x) = \frac{1}{N-1}\sum_{n = 1}^N(x_n - \overline{x})^2
$$


```r
var(x)
#> [1] 7.344444
```

**標準偏差, standard deviation**

標準偏差は分散の平方根です。


```r
sd(x)
#> [1] 2.710064
```

**四分位数間範囲, inter-quantile range, IQR**

四分位数間範囲は第2四分位数と第3四分位数の距離です。
箱ひげ図の箱の高さが四分位数間範囲です。


```r
diff(quantile(x, c(0.25, 0.75)))
#>  75% 
#> 5.25
```

**範囲, range**

範囲はデータを最大値と最小値の距離です。


```r
diff(range(x))
#> [1] 7
```

**平均絶対偏差, mean absolute deviation**

平均絶対偏差は、データと平均値との距離の平均値です。

$$
\text{MAD} = \frac{1}{N} \sum_{n = 1}^N |x_n - \overline{x}|
$$
$\overline{x}$ は平均値、$N$はデータ数です。
専用の関数がないので、これも定義します。


```r
mean_absolute_deviation = function(x) {
  xbar = mean(x)
  xout = abs(x - xbar)
  mean(xout)
}
mean_absolute_deviation(x)
#> [1] 2.3
```

**中央絶対偏差, median absolute deviation, MAD**

中央絶対偏差は、データと中央値との距離の中央値です。

$$
\text{MAD} = median(|x_i - \tilde{x}|)
$$
$\tilde{x}$ は $x$ の中央値です。


```r
mad(x, constant = 1)
#> [1] 2.5
```

標準偏差として使う場合は、

$$
\hat{\sigma}\equiv s = k \cdot \text{MAD} = \frac{1}{\Phi^{-1}(3/4)}\cdot \text{MAD}
$$
この積は標準偏差のロバスト推定量 (robust estimator) といいます。
ロバスト推定量は外れ値に強く影響されないのが特徴です。


```r
mad(x)
#> [1] 3.7065
```

`tibble`データの集計は次のようにします。
全データの集計の場合は、`tibble`　を `summarise` 関数に渡します。

ここでは`seaweed` と `seagrass` の平均値を求めています。


```r
d19 |> 
  summarise(seaweed = mean(seaweed),
            seagrass = mean(seagrass))
#> # A tibble: 1 × 2
#>   seaweed seagrass
#>     <dbl>    <dbl>
#> 1    312.     127.
```

`across()` 関数を使えば、コードは諸略できます。
`across()` に渡したそれぞれのベクトル（列）に `mean` 関数を適応しています。


```r
d19 |> summarise(across(c(seaweed, seagrass), mean))
#> # A tibble: 1 × 2
#>   seaweed seagrass
#>     <dbl>    <dbl>
#> 1    312.     127.
```

`mean()` と `sd()` を同時に適応できます。


```r
d19 |> summarise(across(c(seaweed, seagrass), list(mean, sd)))
#> # A tibble: 1 × 4
#>   seaweed_1 seaweed_2 seagrass_1 seagrass_2
#>       <dbl>     <dbl>      <dbl>      <dbl>
#> 1      312.      439.       127.       227.
```

ところが帰ってくる結果をみて、平均値と標準偏差の区別ができないので、次のようにコードをくみましょう。


```r
d19 |> summarise(across(c(seaweed, seagrass), list(mean = mean, sd = sd)))
#> # A tibble: 1 × 4
#>   seaweed_mean seaweed_sd seagrass_mean seagrass_sd
#>          <dbl>      <dbl>         <dbl>       <dbl>
#> 1         312.       439.          127.        227.
```

では、平均値、標準偏差、平均絶対偏差を求めています。


```r
d19 |> 
  summarise(across(c(seaweed, seagrass),
                   list(mean = mean, sd = sd,
                        mad = mean_absolute_deviation)))
#> # A tibble: 1 × 6
#>   seaweed_mean seaweed_sd seaweed_mad seagrass_mean
#>          <dbl>      <dbl>       <dbl>         <dbl>
#> 1         312.       439.        266.          127.
#> # … with 2 more variables: seagrass_sd <dbl>,
#> #   seagrass_mad <dbl>
```

`site` ごとに集計したいとき、`group_by()` 関数を使って、データのグループ化してから、それぞれの関数を適応します。


```r
d19 |>
  group_by(site) |> 
  summarise(across(c(seaweed, seagrass),
                   list(mean = mean, sd = sd,
                        mad = mean_absolute_deviation)))
#> # A tibble: 3 × 7
#>   site  seaweed_mean seaweed_sd seaweed_mad seagrass_mean
#>   <fct>        <dbl>      <dbl>       <dbl>         <dbl>
#> 1 東部          118.       56.1        42.3          32.5
#> 2 中部          205.      195.        160.          276. 
#> 3 西部          578.      658.        486.           29.2
#> # … with 2 more variables: seagrass_sd <dbl>,
#> #   seagrass_mad <dbl>
```



