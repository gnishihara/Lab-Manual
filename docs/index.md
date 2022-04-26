--- 
title: "データ解析マニュアル"
author: "水圏植物生態学研究室"
date: "2022-04-26"
site: bookdown::bookdown_site
documentclass: book
bibliography: [book.bib, packages.bib]
# url: your book url like https://bookdown.org/yihui/bookdown
# cover-image: path to the social sharing image like images/cover.jpg
description: |
  研究室のデータ解析マニュアルです。一部は基礎統計学に使います。
biblio-style: apalike
csl: chicago-fullnote-bibliography.csl
---

# このマニュアルについて {-}


解析の背景については講義^[基礎統計学]で紹介した内容を参考にしてください。
章ごとに解析を紹介しています。
R コードが記述されている部分はコードブロックまたはコードチャンクと呼びます。

章ごとのコードは独立していないので、注意してください。
コードをそのままコピー・ペーストすると、うまく動かないことがあります^[バグ、bug]。

また、このマニュアルは R 環境における解析のコードを説明するためです^[いつか、説明も加えるつもりです]。
このマニュアルだけだと、統計解析はできるが、統計学の理解には不十分です。
最後に、マニュアルは随時更新するので、タイトルにあるバージョン番号を時々確認してね。
わからないことまたは間違いがあれば、[メール](greg@nagasaki-u.ac.jp)で連絡ください。 

研究室用のデータは RStudio の `~/Lab_Data/` に入っています。

## マニュアルの作り方 {-}

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
