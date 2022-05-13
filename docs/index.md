--- 
title: "データ解析マニュアル"
author: "水圏植物生態学研究室 (greg nishihara)"
date: "2022-05-13"
site: bookdown::bookdown_site
documentclass: book
bibliography: [book.bib, packages.bib, windfetch.bib, multivariate.bib ]
# url: your book url like https://bookdown.org/yihui/bookdown
# cover-image: path to the social sharing image like images/cover.jpg
description: |
  研究室のデータ解析マニュアルです。一部は基礎統計学に使います。
biblio-style: apalike
csl: chicago-fullnote-bibliography.csl
---

# このマニュアルについて {-}

**【重要1】このマニュアルは水圏植物生態学研究室用に準備しましたが、
一部は水産学部の講義につかいます。**

**【重要2】R コードに自身あるが、日本語はチンプンカンプンかも。It is easier to explain this stuff in English.**

解析の背景については講義^[基礎統計学]の資料やレクチャーを参考にしてください。
解析は章ごとに紹介していて、コードはお互いに独立させたつもりです。
それにしても、そのままコピペすると動かないコードもあるので、コードをよく読んでから使ってください。
コードに使用したデータは研究室のサーバにあるが、公開するつもりはありません。

このマニュアルは統計学や解析についての詳細に説明するつもりはないです。
つまり、このマニュアルだけだと、コードをくめるようになるが、統計学の理解には不十分です！
解析の背景は十分理解してから、コードを使ってください。
さらに、コードは研究室のサーバ環境で動きますが、その他の環境で動くは確認していません。

最後に、マニュアルは随時更新するので、タイトルにあるバージョン番号を時々確認してね。
わからないことまたは間違いがあれば、[メール](greg@nagasaki-u.ac.jp)で連絡ください。 

**研究室の皆さん：**研究室用のデータは RStudio の `~/Lab_Data/` に入っています。

マニュアルの更新日：05/13/2022 11:39:16 JST

## サーバ環境 {-}


```r
Sys.info()[c(1:3,5)]
#>                                sysname 
#>                                "Linux" 
#>                                release 
#>                      "5.10.0-10-amd64" 
#>                                version 
#> "#1 SMP Debian 5.10.84-1 (2021-12-08)" 
#>                                machine 
#>                               "x86_64"
```

## マニュアルの作り方 {-}

このマニュアルは `bookdown` パッケージで作成しました。

HTMLバージョンのマニュアルは RStudio の **Build** パネルで組み立てます。

1. **Build** パネルに移動する
2. **Build Book** のアイコンをクリックして、`bookdown::bs4_book` を選択する

コンソールから組み立てる場合はつぎのコードを実行しましょう。


```r
bookdown::render_book()

```

作業しながら、マニュアルのプレビュー版はみれます。
複数人でのプレビューはまだしたことないので、うまくいくかはわからない。


```r
bookdown::serve_book()
```

## R, Rtools, RStudio のリンク先

* R は [CRANのサイト](https://cran.r-project.org/) からダウンロードしてください。
* [Rtools42](https://cran.r-project.org/bin/windows/Rtools/rtools42/files/rtools42-5168-5107.exe) もインストールしてください。直接ダウンロードリンクに飛びます。
* [RStudio](https://www.rstudio.com/products/rstudio/download/) のインストールも強くおすすめします。

<img src="index_files/figure-html/unnamed-chunk-4-1.png" width="90%" style="display: block; margin: auto;" />






