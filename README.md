水圏植物学生態学研究室のRコード集

ここでは、よく使うRコードと解析を紹介します。

この資料は `bookdown::bs4_book` で作成したので、[bookdown.org][https://bookdown.org/yihui/bookdown/] を参考にしてください。

RMarkdown ファイル名の先頭に数字を入れてください。
各章は数字の順で組み立てられます。


* `_common.R` にはデフォルトのコードが入っている。
* `style.css` は HTML のカスタム CSS 要ファイルです。
* `_bookdown.yml`
* `_output.yml`

`_common.R` で `ggplot` のデフォルト書式を設定しているので、`... + theme_pubr()` をする必要はない。
それぞれの Rmd ファイルはお互いに独立しているので、必要なパッケージは必ずファイル先頭にいれましょう。
