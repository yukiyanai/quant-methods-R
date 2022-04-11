## ch11.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第11章 回帰分析による統計的推定
##
## Created: 2018-11-22 Yuki Yanai
## Modified: 2018-11-24 YY

## tidyverse パッケージを読み込む
library("tidyverse")
if (capabilities("aqua")) { # Macかどうか判定し、Macの場合のみ実行
  theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))
}


####################################################
## 11.1  単回帰による統計的推定
####################################################

## --------
## 例11-1
## --------
Beer <- read_csv("data/beer2010.csv")  # データを読み込む
glimpse(Beer)  # データの中身を確認

## ビールの売り上げを気温に回帰する
fit_beer <- lm(beer ~ temp, data = Beer)
summary(fit_beer)  # 結果を表示
confint(fit_beer)                # 回帰係数の95%信頼区間
confint(fit_beer, level = 0.97)  # 回帰係数の97%信頼区間

## 散布図に回帰直線と信頼区間を加える
p_beer <- ggplot(Beer, aes(x = temp, y = beer)) +
  geom_smooth(method = "lm") +
  geom_point() +
  labs(x = "気温（℃）", y = "ビールの出荷量 (1,000kl)")  
print(p_beer)


####################################################
## 11.2  重回帰による統計的推定
####################################################

## --------
## 例11-2
## --------

## 衆院選データを読み込んで2009年の自民党候補だけ抜き出す
LDP2009 <- read_rds("data/hr-data.Rds") %>% 
  filter(year == 2009, party == "LDP")
## Rds がうまく読めないときはcsvを使う
#LDP2009 <- read_csv("data/hr-data.csv") %>% 
#  filter(year == 2009, party == "LDP")
glimpse(LDP2009)  # データの中身を確認

## 得票率 voteshare を選挙費用 expm と 年齢 age に回帰する
fit_3 <- lm(voteshare ~ expm + age, data = LDP2009)
coef(fit_3)
summary(fit_3)
confint(fit_3, level = 0.92)  # 回帰係数の92%信頼区間
