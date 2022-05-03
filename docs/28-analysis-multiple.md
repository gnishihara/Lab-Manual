# モデル選択 {#model-selection}

## 必要なパッケージ


```r
library(tidyverse)
```


## AIC: Akaike's Information Criterion

**AIC（赤池情報量規準, Akaike's Information Criterion）**はモデルの良さを評価するために開発された指標です。

$$
\text{AIC} = -2 \log(\mathcal{L}) + 2(K+1) \approx -2 \log(\mathcal{L}) + 2K
$$

$\mathcal{L}$ は**尤度 (likelihood)**，$K$ はパラメータの数です。

AICは尤度が存在する複数のモデルを比較するために使いますが，帰無仮設を棄却するような作業はありません。

## 尤度

統計解析で考える尤度とは，あるモデルの**尤もらしさの度合い**を意味します。
尤度 $(\mathcal{L})$ を求めるためには，誤差項の確率分布を指定する必要があります。ベクトル $x$ の平均値は 4.6 です。

$$
x = \{5, 3, 6, 3, 6\}
$$
平均値の尤度は次の正規分布確率密度関数の総乗で求められます。

$$
\mathcal{L}(x|\mu, \sigma^2) = \prod_i^5\frac{1}{\sqrt{2\pi\sigma^2}}\exp\left(-\frac{(x_i - \mu)^2}{2\sigma^2}\right)
$$

## 総乗について

総和は $\Sigma$ （$\sigma$の大文字）と示すが，総乗は$\Pi$ （$\pi$の大文字）です。

$$
\begin{aligned}
\sum_{i=1}^3 &= x_1 + x_2 + x_3 \\
\prod_{i=1}^3 &= x_1 \times x_2 \times x_3 \\
\end{aligned}
$$

## 尤度の算出

$x$ の尤度は次のように算出できますが。


```r
x = tibble(x = c(5, 3, 6, 3, 6))

nll = function(x, mean, sd) {
  # 負の対数尤度関数
  -sum(dnorm(x, mean, sd, log = TRUE)) 
}
# bbmle パッケージの mle2() 関数
bbmle::mle2(nll, data = x, start = list(mean = 5, sd = 1))
#> 
#> Call:
#> bbmle::mle2(minuslogl = nll, start = list(mean = 5, sd = 1), 
#>     data = x)
#> 
#> Coefficients:
#>     mean       sd 
#> 4.599997 1.356469 
#> 
#> Log-likelihood: -8.62
```


対数尤度は -8.6191，尤度は 2\times 10^{-4} です。

このときのAICは 
$$
AIC = -2\times -8.62 + 2\times2=21.24
$$

他のモデルと比較しないかぎり, AICに意味はありません。

## AIC による t 検定

アヤメのデータをつかった例です。
 

```r
X = iris %>% as_tibble() %>% 
  filter(str_detect(Species, "setosa|versicolor")) %>% 
  select(Petal.Length, Species) 

# 帰無仮設の関数・種間の平均値は等しい
nll0 = function(m,s) {
    # 負の対数尤度関数
  -sum(dnorm(X$Petal.Length, m, s, log = TRUE)) 
}

# 対立仮説の関数・種間平均値は違う
nll1 = function(m1, s1, m2, s2, x) {
  m = c(m1, m2)[as.numeric(X$Species)]
  s = c(s1, s2)[as.numeric(x$Species)]
  # 負の対数尤度関数
  -sum(dnorm(x$Petal.Length, m, s, log = TRUE))
}
# 対数尤度を求める
out0 = bbmle::mle2(nll0, start = list(m = 3, s = 1.5))
out1 = bbmle::mle2(nll1, data = list(x = X), 
                   start = list(m1 = 1, m2 = 5, 
                                s1 = 0.5, s2 = 0.5))
```

**対数尤度**


```r
bbmle::logLik(out0)
#> 'log Lik.' -178.5166 (df=2)
bbmle::logLik(out1)
#> 'log Lik.' -15.59147 (df=4)
```

**AIC**


```r
AIC(out0, out1)
#>      df       AIC
#> out0  2 361.03310
#> out1  4  39.18294
```

**もっとも小さいAICのモデルを採択する**ので，`out1`（独立した平均値と分散のモデル）を採択します。
AICのとき，帰無仮設を棄却することはしません。帰無仮設の有意性検定とフィッシャーの有意性検定とは全く違う考え方です。AICのとき，検討している複数のモデルの中からもっともありえるモデルを採択します。最もありうるモデルは尤度の高いモデル，つまりAICの低いモデルです。

## ガラパゴス諸島の解析・モデル選択の結果

ガラパゴス諸島のデータを解析しているなかで，次のモデルが検討されました。

$$
\begin{alignedat}{2}
\text{H0:}\qquad & E(\text{Species}) = b_0\\
\text{HF:}\qquad & E(\text{Species}) = b_0 + b_1\text{Area}+b_2\text{Elevation}+b_3\text{Nearest}+b_4\text{Scruz}+b_5\text{Adjacent} \\
\text{logHF:}\qquad & E(\log(\text{Species})) = b_0 + b_1\text{Area}+b_2\text{Nearest}+b_3\text{Adjacent} \\
\text{logHF2:}\qquad & E(\log(\text{Species})) = b_0 + b_1\log(\text{Area})+b_2\text{Nearest}+b_3\log(\text{Adjacent}) \\
\end{alignedat}
$$


```r
data(gala, package = "faraway")
gala = gala %>% as_tibble() # tibble に変換
gala = gala |> mutate(logSpecies = log(Species), logArea = log(Area), logAdjacent = log(Adjacent))
H0     = lm(Species ~ 1, data = gala)
HF     = lm(Species ~ Area + Elevation + Nearest + Scruz + Adjacent, data = gala)
logHF  = lm(Species ~ Area + Nearest + Adjacent, data = gala)
logHF2 = lm(Species ~ logArea + Nearest + logAdjacent, data = gala)
```



```r
AIC(H0, HF, logHF, logHF2) |> as_tibble(rownames = "model") |> arrange(AIC)
#> # A tibble: 4 × 3
#>   model     df   AIC
#>   <chr>  <dbl> <dbl>
#> 1 HF         7  339.
#> 2 logHF2     5  342.
#> 3 logHF      5  364.
#> 4 H0         2  373.
```

`HF` のAICがもっとも低いですね。
ところが，`HF`のクックの距離に問題があったので，その次に低い `logHF2` を採択します。

