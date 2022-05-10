# example R options set globally
options(width = 60)

# example chunk options set globally
knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  echo = TRUE, 
  warning = FALSE, 
  message = FALSE, 
  fig.width = 8, 
  fig.height = 8, 
  fig.align = "center", 
  out.width = "90%",
  fig.pos = "H")


library(tidyverse)
library(lubridate)
library(showtext)
library(ggpubr)
library(lemon)
library(magick)
library(patchwork)


# やっぱり Noto Sans がきれい。
if(!any(str_detect(font_families(), "notosans"))) {
  font_add_google("Noto Sans JP","notosans")
}
# 図のフォントがからだったので、ここで修正した
# １）theme_set() をつかってデフォルトのフォントをかえる
# ２）ggplot() の theme() からとんとの指定をはずす。

theme_pubr(base_size = 12, base_family = "notosans") |> theme_set()
showtext_auto()

Sys.setlocale("LC_TIME", "en_US.UTF-8") # This is to set the server time locate to en_US.UTF-8


## RMarkdown formatting functions.

pm = function(x, y) {
  # プラスマイナスをつける
  sprintf("%0.2f ± %0.2f", x, y)
}

pval = function(x) {
  # P値のフォーマット
  if (x < 0.0001) {
    "P < 0.0001"
  } else {
    sprintf("P = %0.4f", x)
  }
}

