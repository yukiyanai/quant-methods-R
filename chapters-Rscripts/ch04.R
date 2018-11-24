## ch04.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第4章 Rの使い方
##
## Created: 2018-11-22 Yuki Yanai

## 最小値と最大値を並べて表示する関数を作る
mm <- function(x) {
  c(min(x), max(x))
}

a <- c(1, 5, 100, 2, -8, 7)
mm(a)


## 本書で使うパッケージをまとめてインストールする
install.packages(c("tidyverse", "devtools", "haven", "readxl",
                   "coefplot", "interplot", "ROCR", "margins"))
devtools::install_github("toshi-ara/makedummies")
