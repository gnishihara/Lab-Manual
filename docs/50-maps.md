# 地図の作り方 {#maps}



## 必要なパッケージ


```r
library(tidyverse)　# Essential package
library(ggpubr)     # Publication-oriented figures
library(kableExtra) # Tables
library(magick)     # Imagemagick R API
library(patchwork)  # Simplified figure tiling
library(showtext)   # I want to use google fonts in the figures
```


次の2つは地図専用のパッケージです。

```r
library(ggspatial)  # Essential for map-making with ggplot
library(sf)         # Essential for map data manipulation
```

Noto Sans のフォントが好きなので、ここで [Google Fonts](https://fonts.google.com/) からアクセスします。


```r
font_add_google("Noto Sans","notosans")
```

`ggplot` のデフォルトテーマも設定し、フォント埋め込みも可能にします。
ここでデフォルトを設定すると、毎回 `theme_pubr()` を `ggplot`のチェインにたさなくていい。


```r
theme_pubr(base_size = 10, base_family = "notosans") |> theme_set()
showtext_auto() # Automatically embed the Noto Sans fonts into the ggplots.
```

## シェープファイルの読み込み

シェープファイル (shapefile) は地図データのことです。
基本的の拡張子は `shp`, `shx`, `dbf`　ですが、その他に `prj` と `xml` もあります。

研究室用にダウンロードした [国土交通省・国土数値情報ダウンロードサービス](https://nlftp.mlit.go.jp/ksj/index.html) のシェープファイルは `~/Lab_Data/Japan_map_data/Japan` に入っています。


```r
mlit = read_sf("~/Lab_Data/Japan_map_data/Japan/N03-20210101_GML/")
```

`mlit` に読み込んだシェープファイルは[ここへ](https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N03-v3_0.html)。

シェープファイルの 座標参照系 (CRS: Coordinate Reference System) を確認しましょう。


```r
st_crs(mlit)
#> Coordinate Reference System:
#>   User input: JGD2011 
#>   wkt:
#> GEOGCRS["JGD2011",
#>     DATUM["Japanese Geodetic Datum 2011",
#>         ELLIPSOID["GRS 1980",6378137,298.257222101,
#>             LENGTHUNIT["metre",1]]],
#>     PRIMEM["Greenwich",0,
#>         ANGLEUNIT["degree",0.0174532925199433]],
#>     CS[ellipsoidal,2],
#>         AXIS["geodetic latitude (Lat)",north,
#>             ORDER[1],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>         AXIS["geodetic longitude (Lon)",east,
#>             ORDER[2],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>     USAGE[
#>         SCOPE["Horizontal component of 3D system."],
#>         AREA["Japan - onshore and offshore."],
#>         BBOX[17.09,122.38,46.05,157.65]],
#>     ID["EPSG",6668]]
```

CRSには **地理座標系** と **投影座標系** の2種類があります。
座標系にはEPSGコードもつけられています。


```r
# HTML 用テーブル
tibble(`EPSG Code` = c(4326,6668,6677),
       `CRS` = c("WGS84", "JGD2011", "JGD2011 / Japan Plane Rectangular CS IX"),
       `Units` = c("degrees", "degrees", "meters")) |> 
  kbl() |> 
  kable_styling(bootstrap_options = c("hover"))
```

<table class="table table-hover" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> EPSG Code </th>
   <th style="text-align:left;"> CRS </th>
   <th style="text-align:left;"> Units </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 4326 </td>
   <td style="text-align:left;"> WGS84 </td>
   <td style="text-align:left;"> degrees </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6668 </td>
   <td style="text-align:left;"> JGD2011 </td>
   <td style="text-align:left;"> degrees </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6677 </td>
   <td style="text-align:left;"> JGD2011 / Japan Plane Rectangular CS IX </td>
   <td style="text-align:left;"> meters </td>
  </tr>
</tbody>
</table>

このデータは政策区域のデータなので、とても重いです。
まずは、都道府県ごとにまとめた `RDS` ファイルを作って保存します。
都道府県ごとに `st_union()` を使って `polgyon` データを結合します。
結合したデータを unnest して、simple feature に戻してかた保存します。
121158 features もあるので、数時間もかります。

沿岸のデータだけなら軽いですので、`C23` シリーズのファイルを読み込みます。


```r
mlit = tibble(folder = dir("~/Lab_Data/Japan_map_data/Coastline/", full = TRUE)) |> 
  mutate(data = map(folder, read_sf)) |> select(data) |> 
  unnest(data) |> 
  st_as_sf(crs = st_crs(6668))
```

では、ここで地図の確認をします。


```r
mlit |> ggplot() + geom_sf()
```

<img src="50-maps_files/figure-html/unnamed-chunk-9-1.png" width="672" style="display: block; margin: auto;" />

`mlit` のデータは細かい政策区域まで分けられているので、全国スケールの図には向いていません。
`st_union()` をつかって、都道府県ごとに polygon を結合したファイルは、`~/Lab_Data/Japan_map_data/Japan/todofuken.rds` に保存しています。
次のコードで、都道府県ごとにまとめましたが、並列処理でも５時間以上もかかったので、`RDS` ファイルを使いましょう。


```r
# Takes 5.5 hours to complete with 30 cores!
library(furrr)
plan(multisession, workers = 30)
# Group by prefecture
mlit1 = mlit |> group_nest(N03_001) |> 
  mutate(data = future_map(data, st_union)) |> 
  unnest(data) |> st_as_sf() 
mlit1 |> write_rds("~/Lab_Data/Japan_map_data/Japan/todofuken.rds")
```


```r
mlit1 = read_rds("~/Lab_Data/Japan_map_data/Japan/todofuken.rds")
```


```r
mlit1 |> ggplot() + geom_sf()
```

<img src="50-maps_files/figure-html/unnamed-chunk-12-1.png" width="672" style="display: block; margin: auto;" />

## 調査地点のデータを準備する

形上湾アマモ場調査のステーションの GPS `tibble` を準備する。


```r
zostera = read_csv("~/Lab_Data/matsumuro/Katagami_Bay/longlat_info.csv")
zostera |> print(n = 3)
#> # A tibble: 105 × 6
#>    Name   lat  long datetime            eelgrass
#>   <dbl> <dbl> <dbl> <dttm>              <chr>   
#> 1     1  33.0  130. 2021-05-25 09:14:48 absent  
#> 2     2  33.0  130. 2021-05-25 09:30:32 absent  
#> 3     3  33.0  130. 2021-05-25 09:37:16 present 
#> # … with 102 more rows, and 1 more variable:
#> #   `coverage(%)` <dbl>
```

`zostera` に緯度経度を設定する。
CRS は `mlit` と同じにします。


```r
zostera = zostera |> st_as_sf(coords = c("long", "lat"), crs = st_crs(mlit))
zostera |> print(n = 3)
#> Simple feature collection with 105 features and 4 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 129.7845 ymin: 32.90032 xmax: 129.806 ymax: 32.95375
#> Geodetic CRS:  JGD2011
#> # A tibble: 105 × 5
#>    Name datetime            eelgrass `coverage(%)`
#> * <dbl> <dttm>              <chr>            <dbl>
#> 1     1 2021-05-25 09:14:48 absent               0
#> 2     2 2021-05-25 09:30:32 absent               0
#> 3     3 2021-05-25 09:37:16 present              5
#> # … with 102 more rows, and 1 more variable:
#> #   geometry <POINT [°]>
```

## 九州データの抽出

九州のデータと長崎のデータを抽出します。
**重要：長崎の名前が誤っています。`Nagasaki` のはずが、`Naoasaki` として記録されています。**


```r
toget = "長崎|福岡|大分|佐賀|熊本|鹿児島|宮崎"
kyushu = mlit1 |> filter(str_detect(N03_001, toget))
```

海岸線のデータ (`mlit`) から長崎の情報を抽出したいが、このデータの位置情報はコードで記述されています。


```r
admincode = readxl::read_xlsx("~/Lab_Data/Japan_map_data/AdminiBoundary_CD.xlsx", skip = 2)
admincode = admincode |> select(code = matches("行政"), N03_001 = matches("都道府県*.*漢字"))
codes = admincode |> filter(str_detect(N03_001, "長崎")) |> pull(code)
```


```r
nagasaki = mlit |> filter(str_detect(C23_001, str_c(codes, collapse = "|"))) 
```

長崎の海岸線は次のようになります。


```r
ggplot() + geom_sf(data = nagasaki)
```

<img src="50-maps_files/figure-html/unnamed-chunk-18-1.png" width="672" style="display: block; margin: auto;" />

九州は `mlit1` から抽出したので、都道府県政策区域として作図されます。


```r
ggplot() + geom_sf(data = kyushu)
```

<img src="50-maps_files/figure-html/unnamed-chunk-19-1.png" width="672" style="display: block; margin: auto;" />

長崎をハイライトしましょう。


```r
kyushu |> 
  mutate(fillme = str_detect(N03_001, "長崎")) |> 
  ggplot() + geom_sf(aes(fill = fillme), color = NA) +
  guides(fill = "none") +
  scale_fill_viridis_d() +
  theme(panel.background = element_rect(fill = "lightblue", color = "black"),
        axis.line = element_blank())
```

<img src="50-maps_files/figure-html/unnamed-chunk-20-1.png" width="672" style="display: block; margin: auto;" />

この図には、違和感を感じるので、山口、島根、愛媛、広島と高知も追加します。
そしれ、最初に作った `kyushu` の範囲を抽出しておきます。


```r
kbbox = kyushu |> st_bbox()
```



```r
toget = "長崎|福岡|大分|佐賀|熊本|鹿児島|宮崎|山口|島根|愛媛|高知|広島"
kyushu = mlit1 |> filter(str_detect(N03_001, toget))
```


長崎、九州、その他の色分けをして、 `kyushu` をクロップします。
クロップ範囲は `kbbox` です。


```r
kyushu = kyushu |>
  mutate(fillme = case_when(str_detect(N03_001, "長崎") ~ "Nagasaki",
                            str_detect(N03_001, "福岡|大分|佐賀|熊本|鹿児島|宮崎") ~ "Kyushu",
                            TRUE ~ "Honshu")) |> 
  st_crop(kbbox)
```

この地図は次のようになりました。


```r
ggplot(kyushu) + 
  geom_sf(aes(fill = fillme), color = NA) +
  guides(fill = "none") +
  coord_sf(expand = FALSE) +
  scale_fill_viridis_d() +
  theme(panel.background = element_rect(fill = "lightblue", color = "black"),
        axis.line = element_blank())
```

<img src="50-maps_files/figure-html/unnamed-chunk-24-1.png" width="672" style="display: block; margin: auto;" />


## 調査地点の図

形上湾と大村湾の図を作ります。
形上湾の方には、調査地点と結果ものせます。
まずは形上湾と大村湾の範囲を決めます。
範囲は Google Map で選びました。


```r
katagami = rbind(rev(c(32.95809069048365, 129.7669185309373)),
                 rev(c(32.89802000729197, 129.82832411747583))) |>
  as_tibble(.name_repair = \(x) c("long", "lat")) |>
  st_as_sf(coords = c("long", "lat"), crs = st_crs(kyushu))

omurabay = rbind(rev(c(33.103196388120104, 129.67183787501082)),
                 rev(c(32.817013859622804, 130.03298144413574))) |> 
  as_tibble(.name_repair = \(x) c("long", "lat")) |>
  st_as_sf(coords = c("long", "lat"), crs = st_crs(kyushu))
```

ここで、それぞれの湾のデータを `kyushu` からぬきます。

```r
omurabay_area = kyushu |> filter(str_detect(N03_001, "長崎")) |> st_crop(st_bbox(omurabay)) 
katagami_area = kyushu |> filter(str_detect(N03_001, "長崎")) |> st_crop(st_bbox(katagami)) 
```

アマモの被度データの simple features データを準備します。

```r
zostera = zostera |>
  st_as_sf(coords = c("long", "lat"), crs = st_crs(kyushu)) |> 
  rename(coverage = matches("cover")) |> 
  mutate(rank = cut(coverage, 
                    c(-Inf, 1, 10, 40, 70, Inf),
                    labels = c("E", "D", "C", "B", "A"))) |> 
  mutate(rank = factor(rank, 
                       levels = LETTERS[1:5],
                       labels = LETTERS[1:5]))
```

九州の図を先につくります。

```r
# The main plot of kyushu
pmain = ggplot(kyushu) + 
  geom_sf(aes(fill = fillme), color = NA) +
  guides(fill = "none") +
  coord_sf(expand = FALSE) +
  scale_fill_viridis_d() +
  theme(panel.grid = element_blank(),
        panel.background = element_rect(fill = "lightblue", color ="black"),
        panel.border  = element_rect(fill = NA, color ="black"),
        plot.background =  element_rect(fill = NA, color =NA),
        axis.title = element_blank(),
        axis.line = element_blank())
```

大村湾と形上湾の図を次に作りますが、先にラベルの tibble を準備します。
`tibble` の `long` と `lat` のデータは試行錯誤で来ました。
もっといい方法はあるはずです。


```r
# Build plots for Omura Bay and Katagami Bay.
tmp1 = omurabay_area |> st_transform(crs = st_crs(6677)) |> st_bbox()
tmp2 = katagami_area |> st_transform(crs = st_crs(6677)) |> st_bbox()
# tibble for labeling figures. The long and lat are by trial-and-error.
# Need to find a better method.
label1 = tibble(long = tmp1[3] -2500,
                lat = tmp1[2] +1700,
                label = "Omura Bay, Nagasaki, Japan") |> 
  st_as_sf(coords = c("long", "lat"), crs = st_crs(6677), agr = "constant") |> 
  st_transform(crs = st_crs(omurabay_area))

label2 = tibble(long = tmp2[1] +800,
                lat = tmp2[4] -150,
                label = "Katagami Bay, Nagasaki, Japan") |> 
  st_as_sf(coords = c("long", "lat"), crs = st_crs(6677), agr = "constant") |> 
  st_transform(crs = st_crs(omurabay_area))
```

では、大村湾と形上湾の地図をつくります。

```r
pomura = ggplot() +
  geom_sf(fill = "grey50", data = omurabay_area, size = 0) +
  geom_sf_text(aes(label = label), 
               data = label1,
               color = "white",
               family = "notosans", 
               fontface = "bold",
               vjust = 1, hjust = 1,
               size = 5)  + 
  coord_sf(expand = FALSE) +
  annotation_north_arrow(style = north_arrow_minimal(text_family = "notosans", 
                                                     text_face = "bold",
                                                     line_width = 2,
                                                     text_size = 20),
                         pad_y = unit(0.3, "npc")) + 
  theme(panel.background = element_rect(fill = "lightblue", color ="black"),
        panel.border  = element_rect(fill = NA, color ="black"),
        plot.background =  element_rect(fill = "white", color =NA),
        axis.title = element_blank(),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank())

pkatagami = ggplot() +
  geom_sf(fill = "grey50", data = katagami_area, size = 0) +
  geom_sf(aes(fill = rank), data = zostera,
          pch = 21, size = 3,
          color = "white", stroke = 1) +
  geom_sf_text(aes(label = label), 
               data = label2,
               color = "white",
               family = "notosans", 
               fontface = "bold",
               vjust = 1.0, hjust = 0.0,
               size = 5)  + 
  annotation_north_arrow(style = north_arrow_minimal(text_family = "notosans", 
                                                     text_face = "bold",
                                                     line_width = 2,
                                                     text_size = 20)) + 
  coord_sf(expand = FALSE, crs = st_crs(katagami_area)) +
  scale_fill_viridis_d(end = 0.8) +
  theme(panel.grid = element_blank(),
        panel.background = element_rect(fill = "lightblue", color ="black"),
        panel.border  = element_rect(fill = NA, color ="black"),
        plot.background =  element_rect(fill = "white", color =NA),
        axis.title = element_blank(),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank())
```

`patchwork` のパッケージをつかって、図を組み立てます。
図は PDF に保存したら、`magick` を使って、PNGにも変換します。


```r
pout = pmain + (pomura / pkatagami)
pdfname = "katagami-map-v1.pdf"
pngname = str_replace(pdfname, "pdf", "png")
ggsave(pdfname, plot= pout, width = 300, height = 300, units = "mm")
image_read_pdf(pdfname, density = 600) |> image_write(pngname)
```


```r
knitr::include_graphics(str_c("./", pngname))
```

<img src="./katagami-map-v1.png" width="50%" style="display: block; margin: auto;" />

## Sesssion information


```r
sessionInfo()
#> R version 4.1.3 (2022-03-10)
#> Platform: x86_64-pc-linux-gnu (64-bit)
#> Running under: Debian GNU/Linux 11 (bullseye)
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/atlas/libblas.so.3.10.3
#> LAPACK: /usr/lib/x86_64-linux-gnu/atlas/liblapack.so.3.10.3
#> 
#> locale:
#>  [1] LC_CTYPE=en_US.utf8        LC_NUMERIC=C              
#>  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.utf8     
#>  [5] LC_MONETARY=ja_JP.UTF-8    LC_MESSAGES=en_US.utf8    
#>  [7] LC_PAPER=ja_JP.UTF-8       LC_NAME=C                 
#>  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
#> [11] LC_MEASUREMENT=ja_JP.UTF-8 LC_IDENTIFICATION=C       
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets 
#> [6] methods   base     
#> 
#> other attached packages:
#>  [1] sf_1.0-7         ggspatial_1.1.5  kableExtra_1.3.4
#>  [4] patchwork_1.1.1  magick_2.7.3     ggpubr_0.4.0    
#>  [7] showtext_0.9-5   showtextdb_3.0   sysfonts_0.8.5  
#> [10] forcats_0.5.1    stringr_1.4.0    dplyr_1.0.8     
#> [13] purrr_0.3.4      readr_2.1.2      tidyr_1.2.0     
#> [16] tibble_3.1.6     ggplot2_3.3.5    tidyverse_1.3.1 
#> 
#> loaded via a namespace (and not attached):
#>  [1] fs_1.5.2           bit64_4.0.5       
#>  [3] lubridate_1.8.0    webshot_0.5.2     
#>  [5] httr_1.4.2         tools_4.1.3       
#>  [7] backports_1.4.1    bslib_0.3.1       
#>  [9] utf8_1.2.2         R6_2.5.1          
#> [11] KernSmooth_2.23-20 DBI_1.1.2         
#> [13] colorspace_2.0-3   withr_2.5.0       
#> [15] tidyselect_1.1.2   downlit_0.4.0     
#> [17] bit_4.0.4          curl_4.3.2        
#> [19] compiler_4.1.3     textshaping_0.3.6 
#> [21] cli_3.2.0          rvest_1.0.2       
#> [23] xml2_1.3.3         bookdown_0.24     
#> [25] sass_0.4.0         scales_1.1.1      
#> [27] classInt_0.4-3     askpass_1.1       
#> [29] proxy_0.4-26       systemfonts_1.0.4 
#> [31] digest_0.6.29      rmarkdown_2.12    
#> [33] svglite_2.1.0      pkgconfig_2.0.3   
#> [35] htmltools_0.5.2    highr_0.9         
#> [37] dbplyr_2.1.1       fastmap_1.1.0     
#> [39] rlang_1.0.2        readxl_1.3.1      
#> [41] rstudioapi_0.13    farver_2.1.0      
#> [43] jquerylib_0.1.4    generics_0.1.2    
#> [45] jsonlite_1.8.0     vroom_1.5.7       
#> [47] car_3.0-12         magrittr_2.0.2    
#> [49] s2_1.0.7           Rcpp_1.0.8        
#> [51] munsell_0.5.0      fansi_1.0.2       
#> [53] abind_1.4-5        lifecycle_1.0.1   
#> [55] stringi_1.7.6      yaml_2.3.5        
#> [57] carData_3.0-5      grid_4.1.3        
#> [59] parallel_4.1.3     crayon_1.5.0      
#> [61] haven_2.4.3        hms_1.1.1         
#> [63] knitr_1.37         pillar_1.7.0      
#> [65] ggsignif_0.6.3     codetools_0.2-18  
#> [67] wk_0.6.0           reprex_2.0.1      
#> [69] glue_1.6.2         evaluate_0.15     
#> [71] pdftools_3.1.1     qpdf_1.1          
#> [73] modelr_0.1.8       vctrs_0.3.8       
#> [75] tzdb_0.2.0         cellranger_1.1.0  
#> [77] gtable_0.3.0       assertthat_0.2.1  
#> [79] cachem_1.0.6       xfun_0.30         
#> [81] broom_0.7.12       e1071_1.7-9       
#> [83] rstatix_0.7.0      ragg_1.2.2        
#> [85] class_7.3-20       viridisLite_0.4.0 
#> [87] memoise_2.0.1      units_0.8-0       
#> [89] ellipsis_0.3.2
```

