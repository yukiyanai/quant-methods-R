## ch10.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第10章 回帰分析の基礎
##
## Created: 2018-11-22 Yuki Yanai
## Modified: 2018-11-23 YY
##           2018-11-24 YY

## tidyverse パッケージを読み込む
library("tidyverse")
if (capabilities("aqua")) { # Macかどうか判定し、Macの場合のみ実行
  theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))
}


####################################################
## 10.1  線形回帰：散布図への直線の当てはめ
####################################################

## --------
## 例10-1
## --------
## ビールの売り上げデータ beer2010.csv をダウンロード
download.file(url = "https://git.io/fA6Zk",
              destfile = "data/beer2010.csv")
## ダウンロードしたデータを読み込む
Beer <- read_csv("data/beer2010.csv")
glimpse(Beer)  # データの中身を確認


## 図10.1
## ビールの出荷量beerと気温tempの散布図
p1 <- ggplot(data = Beer, aes(x = temp, y = beer))+
  geom_point() +
  labs(x = "気温（℃）", y = "ビールの出荷量 (1,000kl)")
print(p1)
## 相関係数を求める
with(Beer, cor(temp, beer))

## 図10.2
## 散布図に、直線を当てはめる
p2 <- p1 + geom_smooth(method = "lm", se = FALSE)
print(p2)


####################################################
## 10.2  最小二乗法
####################################################

## beer を temp に回帰したときの、直線の傾きと切片を求める
fit_beer <- lm(beer ~ temp, data = Beer)
summary(fit_beer)  # 回帰分析の結果を表示
coef(fit_beer)     # 切片と傾きだけ取り出す


####################################################
## 10.3  単回帰と重回帰
####################################################

## ---------
## 例10-2
## ---------
HR <- read_rds("data/hr-data.Rds")  # データを読み込む
## Rds がうまく読めないときはcsvを使う
#LDP2009 <- read_csv("data/hr-data.csv") %>% 
#  filter(year == 2009, party == "LDP")
glimpse(HR)  # データの中身を確認

## 2009年衆院選の自民党候補だけ抜き出す
LDP2009 <- filter(HR, year == 2009, party == "LDP")

## 得票率 voteshare を選挙費用 exp と 年齢 age に回帰する
fit_1 <- lm(voteshare ~ exp + age, data = LDP2009)
summary(fit_1)  # 結果を表示
coef(fit_1)     # 係数だけ表示

## exp の代わりにexpm (= exp / 10^6) を使って回帰分析を行う
fit_2 <- lm(voteshare ~ expm + age, data = LDP2009)
coef(fit_2)     # 係数を表示


## 重回帰とは?
fit_01 <- lm(voteshare ~ expm, data = LDP2009)
fit_02 <- lm(voteshare ~ age, data = LDP2009)
coef(fit_2)
coef(fit_01)
coef(fit_02)

## ---------
## 回帰解剖
## ---------

## voteshare を age に回帰
fit_va <- lm(voteshare ~ age, data = LDP2009)
coef(fit_va)
e1 <- LDP2009$voteshare - (coef(fit_va)[1] + coef(fit_va)[2] * LDP2009$age)


## expm を age に回帰
fit_ea <- lm(expm ~ age, data = LDP2009)
coef(fit_ea)
e2 <- LDP2009$expm - (coef(fit_ea)[1] + coef(fit_ea)[2] * LDP2009$age)


## 残差 e1 を残差 e2 に回帰する
fit_ee <- lm(e1 ~ e2)
coef(fit_ee)
coef(fit_2)


####################################################
## 10.4  決定係数
####################################################

## fit_beer の決定係数は？
summary(fit_beer)
summary(fit_beer)$r.squared

## fit_2 の自由度調整済み決定係数は？
summary(fit_2)
summary(fit_2)$adj.r.squared
