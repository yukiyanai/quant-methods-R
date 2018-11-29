## ch14.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第14章 交差項の使い方
##
## Created: 2018-11-23 Yuki Yanai
## Modified: 2018-11-24 YY
##           2018-11-26 YY

## tidyverse パッケージを読み込む
library("tidyverse")
library("interplot")
if (capabilities("aqua")) { # Macかどうか判定し、Macの場合のみ実行
  theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))
}


####################################################
## 14.1  交差項で何がわかるのか
####################################################

## Rコードなし

####################################################
## 14.2  交差項を入れた回帰分析の注意点
####################################################

## Rコードなし

####################################################
## 14.3  衆議院選挙結果を事例とした交差項の分析
####################################################

## --------
## 例14-1
## --------

## 衆院選データの読み込み
HR <- read_rds("data/hr-data.Rds")
#HR <- read_csv("data/hr-data.csv") # csv形式を使う場合
glimpse(HR)  # データの中身を確認する

## 2005年の衆院選について、voteshare, exppv, eligibleの3変数だけ残す
### select() という名前の関数は、dplyrパッケージ (tidyverseで読み込んだ)
### とinterplotパッケージの両者に含まれるので、dplyrを指定して使う
HR05 <- HR %>%
  filter(year == 2005) %>% 
  dplyr::select(voteshare, exppv, eligible)


summary(HR05)  # 記述統計の確認

## 3変数の標準偏差を一度に計算する
apply(HR05, MARGIN = 2, FUN = sd, na.rm = TRUE)

## 図14.5
## 得票率 voteshare と 一人当たり選挙費用 exppv の散布図
plt_vs_ex <- ggplot(HR05, aes(x = exppv, y = voteshare)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(x = "有権者一人当たり選挙費用", y = "得票率")
print(plt_vs_ex)

## 図14.6
## 有権者数 elgible と exppv の散布図
plt_vs_el <- ggplot(HR05, aes(x = eligible, y = voteshare)) +
  geom_point() +
  geom_smooth(method = "lm") + 
  labs(x = "有権者数", y = "得票率")
print(plt_vs_el)

## 交差項を使った回帰分析
model_1 <- lm(voteshare ~ exppv * eligible, data = HR05)
summary(model_1)

## 中心化した説明変数を使った回帰分析
HR05 <- HR05 %>% 
  mutate(exppv_c = exppv - mean(exppv, na.rm = TRUE),
         eligible_c = eligible - mean(eligible))
model_2 <- lm(voteshare ~ exppv_c * eligible_c, data = HR05)
summary(model_2)


## 二つの有権数を設定して影響力を可視化する
mean(HR05$eligible)
sd(HR05$eligible)
## 図14.7
## 二つの異なる有権者数を設定して回帰直線を描く
## Macの場合
plt_int <- ggplot(HR05, aes(x = exppv, y = voteshare)) + 
  geom_point(pch = 16) +
  geom_abline(intercept = 9.22, slope = 0.72,
              linetype = "dashed") +
  geom_abline(intercept = 9.03, slope = 1.06) + 
  ylim(0, 100) +
  labs(x = "選挙費用（有権者一人当たり：円）", y = "得票率 (%)") + 
  geom_text(label = "得票率 = 9.22 + 0.72・選挙費用\n(有権者数 = 280802)", 
            x = 65, y = 8, family = "HiraginoSans-W3") +
  geom_text(label = "得票率 = 9.03 + 1.06・選挙費用\n(有権者数 = 408598)", 
            x = 40, y = 90, family = "HiraginoSans-W3")
## Windowsの場合
#plt_int <- ggplot(HR05, aes(x = exppv, y = voteshare)) + 
#  geom_point(pch = 16) +
#  geom_abline(intercept = 9.22, slope = 0.72,
#              linetype = "dashed") +
#  geom_abline(intercept = 9.03, slope = 1.06) + 
#  ylim(0, 100) +
#  labs(x = "選挙費用（有権者一人当たり：円）", y = "得票率 (%)") + 
#  geom_text(label = "得票率 = 9.22 + 0.72・選挙費用\n(有権者数 = 280802)", 
#            x = 65, y = 8) +
#  geom_text(label = "得票率 = 9.03 + 1.06・選挙費用\n(有権者数 = 408598)", 
#            x = 40, y = 90)
print(plt_int)


## 図14.8
## 限界効果の可視化
int_1 <- interplot(m = model_1, var1 = "exppv", var2 = "eligible") +
  labs(x = "有権者数", 
       y = "選挙費用が得票率に与える影響")
print(int_1)
