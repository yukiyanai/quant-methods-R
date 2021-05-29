## ch09.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第9章 変数間の関連性
##
## Created:  2018-11-23 Yuki Yanai
## Modified: 2018-11-24 YY
##           2021-05-29 YY

## tidyverse パッケージを読み込む
library("tidyverse")
if (capabilities("aqua")) { # Macかどうか判定し、Macの場合のみ実行
  theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))
}


####################################################
## 9.1  カテゴリ変数間の関連
####################################################

## 第6章で保存した衆院選データを読み込む
HR <- read_rds("data/hr-data.Rds")
## Rdsファイルの読み込みがうまくいかない場合は以下を実行
#download.file(url = "https://git.io/fxhQU",
#              destfile = "data/hr-data.csv")
#HR <- read_csv("data/hr-data.csv")
glimpse(HR)  # 読み込んだデータの確認

## 2009年の衆院選の新人と現職（つまり元色を除外）だけを抜き出す
hr09 <- filter(HR,
               year == 2009,     # 2009年の総選挙のみ 
               status != "元職") # 元職を除く 

## 現職か新人かを表すstatusと小選挙区での勝敗を示すsmdのクロス表
(tbl_st_smd <- with(hr09, table(status, smd)))

## 現職候補であることを示す incという変数を作り、factor型にする
hr09 <- hr09 %>%
  mutate(inc = ifelse(status == "現職", 1, 0),
         inc = factor(inc, labels = c("新人", "現職")))

## incとsmdのクロス表を作り、周辺度数を加える
hr09 %>%
  with(table(inc, smd)) %>%
  addmargins()

## ----------------------
## 例9-1：行パーセント
## ----------------------
hr09 %>%
  with(table(inc, smd)) %>%
  # 列周辺度数を加える.  margin=1 で列周辺度数
  addmargins(margin = 1)  %>%
  # 度数を比率に変換する. margin=1 で行比率
  prop.table(margin = 1)  %>%
  # 小数第4位まで残す
  round(digits = 4) %>%
  # 行周辺度数を加え、%表示に. margin=2 で行周辺度数
  addmargins(margin = 2) * 100 

## ----------------------
## 例9-2：列パーセント
## ----------------------
hr09 %>%
  with(table(inc, smd)) %>%
  # 行周辺度数を加える. margin=2 で行周辺度数
  addmargins(margin = 2) %>%
  # 度数を比率に変換する. margin=2 で列比率
  prop.table(margin = 2) %>%
  # 小数第4位まで残す
  round(digits = 4) %>% 
  # 列周辺度数を加え、%表示に. margin=1 で列周辺度数
  addmargins(margin = 1) * 100 

## ----------------------
## 例9-3：全体パーセント
## ----------------------
hr09 %>%
  with(table(inc, smd)) %>%
  # 度数を比率に変換する
  prop.table() %>%
  # 周辺度数を加える
  addmargins() %>%
  # 小数第2位までの%表示にする
  round(digits = 4) * 100

## ----------------------
## 例9-4
## ----------------------

## 表9.2 を作る
tbl_cab <- matrix(c(30, 20, 20, 30), nrow = 2, byrow = TRUE)
row.names(tbl_cab) <- c("女性", "男性")   # 行に名前をつける
colnames(tbl_cab) <- c("不支持", "支持")  # 列にラベルを貼る   
addmargins(tbl_cab)                       # 周辺度数を加えて表示する
## カイ二乗検定を実行する
chisq.test(tbl_cab, correct = FALSE)

## 表9.4 を作る
tbl_sml <-  matrix(c(10, 2, 3, 7), nrow = 2, byrow = TRUE)
row.names(tbl_sml) <- c("女性", "男性")
colnames(tbl_sml) <- c("不支持", "支持")
addmargins(tbl_sml)
## フィッシャーの直接確率計算法
fisher.test(tbl_sml)


####################################################
## 9.2  量的変数間の関連
####################################################

## 標本サイズn=3のデータフレームxyを作る
xy <- data_frame(  # 古い方法
      #tibble(      # 新しい方法
  x = c(1, 5, 10),
  y = c(1, 2, 10))
## xy に含まれる二変数xとyの散布図を描く
scat1 <- ggplot(xy, aes(x = x, y = y)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) 
print(scat1)
## xy に含まれる二変数xとyの相関係数を求める
with(xy, cor(x, y))
## 統計的に有意な関係があるか検定する
with(xy, cor.test(x, y))

## 標本サイズn=300のデータフレームxy_largeを作る
xy_large <- data_frame(  # 古い方法
            #tibble(      # 新しい方法
  x = rep(c(1, 5, 10), 100),
  y = rep(c(1, 2, 10), 100))
nrow(xy_large)  # 標本サイズの確認
## xy_large に含まれる二変数xとyの散布図を描く（図9.6）
scat2 <- ggplot(xy_large, aes(x = x, y = y)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE)
print(scat2)
## xy_large に含まれる二変数xとyの相関係数を求める
with(xy_large, cor(x, y))
## 統計的に有意な関係があるか検定する
with(xy_large, cor.test(x, y))

## 相関関係があっても因果関係がない状況のシミュレーション
set.seed(2018-08-07)  # 乱数の種を指定する
comp <- sample(c("接戦", "無風"), size = 100, replace = TRUE)
money <- rnorm(100, 
               sd = 0.2,
               mean = 0.4 + 0.5 * as.numeric(comp == "接戦"))
turnout <- rnorm(100, 
                 sd = 0.1, 
                 mean = 0.4 + 0.3 * as.numeric(comp == "接戦"))
df <- data_frame(  # 古い方法
      #tibble(      # 新しい方法
  money = money,
  turnout = turnout,
  comp = comp)
head(df)

## 投票率 turnout と選挙費用の合計 money の散布図を描く
scat_turnout <- ggplot(df, aes(x = money, y = turnout)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "選挙費用 (1,000万円)", y = "投票率 (%)")
print(scat_turnout)
## 相関係数を求める
with(df, cor(turnout, money))

## 図9.10
## 接戦と無風の選挙区を分けて直線を当てはめる
blocking <- ggplot(df, aes(x = money, y = turnout)) +
  geom_point(aes(shape = comp)) +
  geom_smooth(aes(linetype = comp), method = "lm", se = FALSE) +
  labs(x = "選挙費用 (1,000万円)", y = "投票率 (%)") +
  scale_shape_discrete(name = "") +
  scale_linetype_discrete(name = "")
print(blocking)
