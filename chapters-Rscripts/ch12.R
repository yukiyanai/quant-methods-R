## ch12.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第12章 回帰分析の前提と妥当性の診断
##
## Created:  2018-11-22 Yuki Yanai
## Modified: 2018-11-24 YY
##           2021-05-29 YY

## tidyverse パッケージを読み込む
library("tidyverse")
if (capabilities("aqua")) { # Macかどうか判定し、Macの場合のみ実行
  theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))
}


####################################################
## 12.1  回帰分析の前提
####################################################

## Rコードなし


####################################################
## 12.2  Rによる回帰診断
####################################################

## 衆院選データを読み込んで2009年の自民党候補だけ抜き出す
LDP2009 <- read_rds("data/hr-data.Rds") %>% 
  filter(year == 2009, party == "LDP")
## Rds がうまく読めないときはcsvを使う
#LDP2009 <- read_csv("data/hr-data.csv") %>% 
#  filter(year == 2009, party == "LDP")
glimpse(LDP2009)  # データの中身を確認

## 得票率 voteshare を選挙費用 expm と 年齢 age に回帰する
fit <- lm(voteshare ~ expm + age, data = LDP2009)

## 残差と予測値の関係を散布図に描く
#res_plt <- data_frame(res = fit$residuals,
#                      fitted = fit$fitted.values) %>%  # 古い方法
res_plt <- tibble(res = fit$residuals,
                  fitted = fit$fitted.values) %>% # 新しい方法
  ggplot(aes(x = fitted, y = res)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  labs(x = "予測値", y = "残差")
print(res_plt)

## 標準化残差を計算する
res <- fit$residuals
#df <- data_frame(z_res = (res - mean(res)) / sd(res)) # 古い方法
df <- tibble(z_res = (res - mean(res)) / sd(res)) # 新しい方法

## 残差の正規QQプロットを描く
qqplt <- ggplot(df, aes(sample = z_res)) +
  geom_abline(intercept = 0, slope = 1,            # 45度線
              linetype = "dashed", color = "gray") +
  geom_qq(pch = 16, size = 1) +
  labs(x = "標準正規分布", y = "標準化した残差の分布") +
  xlim(-4, 4) + ylim(-4, 4) +
  coord_fixed()  # 横軸と縦軸を1:1にする
print(qqplt)
