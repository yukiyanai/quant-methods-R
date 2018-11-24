## ch13.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第13章 回帰分析の応用
##
## Created: 2018-11-22 Yuki Yanai
## Modified: 2018-11-24 YY

## tidyverse パッケージを読み込む
library("tidyverse")
library("makedummies")
if (capabilities("aqua")) { # Macかどうか判定し、Macの場合のみ実行
  theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))
}


####################################################
## 13.1  ダミー変数の利用
####################################################

## 衆院選データを読み込む
HR <- read_rds("data/hr-data.Rds")
#HR <- read_csv("data/hr-data.csv") # csv形式を使う場合
glimpse(HR)  # データの中身を確認する

## 変数status の中身を把握する
with(HR, table(status))

## 新人ダミーと元職ダミーを作り、HRに加える
HR <- HR %>%
  mutate(new = ifelse(status == "新人", 1, 0), 
         old = ifelse(status == "元職", 1, 0))

## ダミー変数と元の変数を比べる
with(HR, table(status, new))
with(HR, table(status, old))

## 各政党のダミー変数を一挙に作る
party_dummies <- HR %>%
  mutate(party = factor(party)) %>%
  makedummies(col = "party")
length(party_dummies)  # ダミー変数の数を確認
names(party_dummies)   # ダミー変数の名前を確認
## ダミー変数を HR に追加する
HR <- bind_cols(HR, party_dummies)


## --------
## 例13-1
## --------

## 分析対象を2009年衆院選に限定する
HR2009 <- filter(HR, year == 2009)

## 得票率 voteshare を選挙費用 expm と民主党ダミー party_DPJ に回帰する
fit_dpj <- lm(voteshare ~ expm + party_DPJ, data = HR2009)
summary(fit_dpj)

## 図13.1
## ダミー変数によって切片が異なる平行な回帰直線を描く
pred <- HR2009 %>%
  with(expand.grid(expm = seq(min(expm, na.rm = TRUE), 
                              max(expm, na.rm = TRUE),
                              length.out = 100),
                   party_DPJ = 0:1))
pred$voteshare = predict(fit_dpj, newdata = pred)
## Macの場合
plt_dpj <- ggplot(HR2009, aes(x = expm, y = voteshare,
                              shape = as.factor(party_DPJ),
                              linetype = as.factor(party_DPJ))) +
  geom_point() +
  geom_line(data = pred) +
  labs(x = "選挙費用（100万円）", y = "得票率 (%)") +
  scale_linetype_discrete(guide = FALSE) +
  scale_shape_discrete(name = "所属政党", 
                       labels = c("その他", "民主党")) +
  guides(shape = guide_legend(reverse = TRUE)) +
  geom_label(aes(x = 20, y = 95, label = "民主党"),
             family = "HiraginoSans-W3") +
  geom_label(aes(x = 22.5, y = 73, label = "その他"),
             family = "HiraginoSans-W3")
## Windowsの場合
#plt_dpj <- ggplot(HR2009, aes(x = expm, y = voteshare,
#                              shape = as.factor(party_DPJ),
#                              linetype = as.factor(party_DPJ))) +
#  geom_point() +
#  geom_line(data = pred) +
#  labs(x = "選挙費用（100万円）", y = "得票率 (%)") +
#  scale_linetype_discrete(guide = FALSE) +
#  scale_shape_discrete(name = "所属政党", 
#                       labels = c("その他", "民主党")) +
#  guides(shape = guide_legend(reverse = TRUE)) +
#  geom_label(aes(x = 20, y = 95, label = "民主党")) +
#  geom_label(aes(x = 22.5, y = 73, label = "その他"))
print(plt_dpj)

## 信頼区間の下限と上限を計算する
## まず、予測値の標準誤差を求める
err <- predict(fit_dpj, newdata = pred, se.fit = TRUE)
## 予測値と標準誤差を使って信頼区間を求める
pred <- pred %>%
  mutate(lower = err$fit + 
           qt(0.025, df = err$df) * err$se.fit,
         upper = err$fit + 
           qt(0.975, df = err$df) * err$se.fit)

## 図13.2
plt_dpj_ci <- plt_dpj +
  geom_ribbon(data = pred, aes(ymin = lower, ymax = upper),
              fill = "gray", alpha = 0.6)
print(plt_dpj_ci)


## --------
## 例13-2
## --------

## partyのclass を確認する
class(HR2009$party)

## party を facotr型に変換する
HR2009 <- mutate(HR2009, party = factor(party))

## 再びpartyのclass を確認する
class(HR2009$party)

## 得票率 voteshare を選挙費用 expm と 所属政党に回帰する
fit_parties <- lm(voteshare ~ expm + party, data = HR2009)
summary(fit_parties)

## party変数をcharacter型に変換する
HR2009 <- mutate(HR2009, party = as.character(party)) 

## 候補者のいる政党を確認する
(party_names <- unique(HR2009$party))
## 自民党 (party_names で2番目）を先頭にしたfactor型に変換する
HR2009 <- HR2009 %>%
  mutate(party = factor(party, 
                        levels = c(party_names[2], party_names[-2])))
## 政党名を表にして、自民党が先頭になっていることを確認する
with(HR2009, table(party))

## 得票率 voteshare を選挙費用 expm と 所属政党に回帰する
fit_parties2 <- lm(voteshare ~ expm + party, data = HR2009)
summary(fit_parties2)


## --------
## 例13-3
## -------

## 選挙費用が得票率に与える影響は、民主党候補とその他で異なる？
fit_int <- lm(voteshare ~ expm * party_DPJ, data = HR2009)
summary(fit_int)

## 図13.3
## 民主党候補とその他で切片も傾きも異なる回帰直線を描く
## Macの場合
plt_int <- ggplot(HR2009, aes(x = expm, y = voteshare)) +
  geom_point(aes(shape = as.factor(party_DPJ))) +
  geom_smooth(method = "lm", aes(linetype = as.factor(party_DPJ))) +
  labs(x = "選挙費用（100万円）", y = "得票率 (%)") +
  scale_linetype_discrete(guide = FALSE) +
  scale_shape_discrete(name = "所属政党", 
                       labels = c("その他", "民主党")) +
  guides(shape = guide_legend(reverse = TRUE)) +
  geom_label(aes(x = 0.8, y = 50, label = "民主党"),
             family = "HiraginoSans-W3") +
  geom_label(aes(x = 23, y = 86, label = "その他"),
             family = "HiraginoSans-W3")
## Windowsの場合
#plt_int <- ggplot(HR2009, aes(x = expm, y = voteshare)) +
#  geom_point(aes(shape = as.factor(party_DPJ))) +
#  geom_smooth(method = "lm", aes(linetype = as.factor(party_DPJ))) +
#  labs(x = "選挙費用（100万円）", y = "得票率 (%)") +
#  scale_linetype_discrete(guide = FALSE) +
#  scale_shape_discrete(name = "所属政党", 
#                       labels = c("その他", "民主党")) +
#  guides(shape = guide_legend(reverse = TRUE)) +
#  geom_label(aes(x = 0.8, y = 50, label = "民主党")) +
#  geom_label(aes(x = 23, y = 86, label = "その他"))
print(plt_int)

## 切片を固定して、傾きだけをダミー変数によって変えるモデル
fit_dpj3 <- lm(voteshare ~ expm + expm:party_DPJ, data = HR2009)

## 図13.4
## 切片を共有し、傾きだけが異なる回帰直線を描く
pred3 <- HR2009 %>%
  with(expand.grid(expm = seq(min(expm, na.rm = TRUE), 
                              max(expm, na.rm = TRUE),
                              length.out  = 100),
                   party_DPJ = 0:1)) %>%
  mutate(voteshare = predict(fit_dpj3, newdata = pred))
## Macの場合
plt_dpj3 <- ggplot(HR2009, aes(x = expm, y = voteshare,
                               shape = as.factor(party_DPJ),
                               linetype = as.factor(party_DPJ))) +
  ylim(0, 100) +
  geom_point(size = 1.5) +
  geom_line(data = pred3) +
  labs(x = "選挙費用（100万円）", y = "得票率 (%)") +
  scale_linetype_discrete(guide = FALSE) +
  scale_shape_discrete(name = "所属政党", labels = c("その他", "民主党")) +
  guides(shape = guide_legend(reverse = TRUE)) +
  geom_label(aes(x = 21, y = 95, label = "民主党"),
             family = "HiraginoSans-W3") +
  geom_label(aes(x = 22.5, y = 73, label = "その他"),
             family = "HiraginoSans-W3")
## Windowsの場合
#plt_dpj3 <- ggplot(HR2009, aes(x = expm, y = voteshare,
#                               shape = as.factor(party_DPJ),
#                               linetype = as.factor(party_DPJ))) +
#  ylim(0, 100) +
#  geom_point(size = 1.5) +
#  geom_line(data = pred3) +
#  labs(x = "選挙費用（100万円）", y = "得票率 (%)") +
#  scale_linetype_discrete(guide = FALSE) +
#  scale_shape_discrete(name = "所属政党", labels = c("その他", "民主党")) +
#  guides(shape = guide_legend(reverse = TRUE)) +
#  geom_label(aes(x = 21, y = 95, label = "民主党")) +
#  geom_label(aes(x = 22.5, y = 73, label = "その他")) 
print(plt_dpj3)


####################################################
## 13.2  変数変換
####################################################

## --------
## 例13-4
## --------

HT <- read_csv("data/height.csv")  # データを読み込む
glimpse(HT)  # 中身を確認

## 子（本人）の身長 ht を、父親の身長 father と女性ダミー female に回帰
fit_ht <- lm(ht ~ father + female, data = HT)
summary(fit_ht)

## 線形変換：単位を変える
fit_cm <- lm(ht ~ father + female, data = HT)
fit_met <- lm(ht ~ metfather + female, data = HT)
fit_in <- lm(ht ~ infather + female, data = HT)
summary(fit_cm)
summary(fit_met)
summary(fit_in)

## 中心化
HT <- mutate(HT, c_father = father - mean(father))
HT <- mutate(HT, c_female = female - mean(female))
summary(HT$c_father)
summary(HT$c_female)
fit_ht_c <- lm(ht ~ c_father + c_female, data = HT)
summary(fit_ht_c)

## 説明変数を中心化した回帰分析の切片
coef(fit_ht_c)[1]
## データにおける応答変数の平均値
mean(HT$ht)
