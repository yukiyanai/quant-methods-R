## ch15.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第15章 ロジスティック回帰分析
##
## Created:  2018-11-23 Yuki Yanai
## Modified: 2018-11-24 YY
##           2021-05-29 YY

## 利用するパッケージを読み込む
library("tidyverse")
library("ROCR")
library("margins")
library("patchwork")
if (capabilities("aqua")) { # Macかどうか判定し、Macの場合のみ実行
  theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))
}

  
####################################################
## 15.1  ロジスティック関数
####################################################

## ロジスティック関数（ロジットの逆関数）を定義する
inv_logit <- function(x) {
  return(1 / (1 + exp(-x)))
}

## 図15.1 の左
curve(inv_logit, from = -6, to = 6, yaxp = c(0, 1, 4),
      xlab = "x", ylab = "logistic(x)")
abline(v = 0, lty = 2)
abline(h = 0.5, lty = 3)

## 図15.1 の右
curve(inv_logit(-2 + 0.5 * x), from = -8, to = 16, 
      xaxp = c(-8, 16, 2), yaxp = c(0, 1, 4), 
      xlab = "x", ylab = "logistic(-2 + 0.5x)")
abline(v = 4, lty = 2)
abline(h = 0.5, lty = 3)


####################################################
## 15.2  ロジスティック回帰分析の手順
####################################################

## --------
## 例15-1
## --------

## logit.csv をダウンロードして保存
download.file(url = "https://git.io/fxqzo",
              destfile = "data/logit.csv")
Fake <- read_csv("data/logit.csv")  # データの読み込み
glimpse(Fake)                       # 中身の確認

## id を除外し、wlsmdにラベルをつけてfactor型にする
Fake <- Fake %>% 
  select(-id) %>% 
  mutate(smd = factor(wlsmd, levels = 0:1,
                      labels = c("落選", "当選")))

summary(Fake)  # 記述統計の確認

## 各ペアの相関係数を求める
Fake %>% 
  select(-smd) %>% 
  cor()

## 図15.3
## 当落 wlsmd と当選回数 previous の散布図
fk_1 <- ggplot(Fake, aes(x = previous, y = wlsmd)) + 
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "当選回数", y = "選挙での当落") +
  geom_hline(yintercept = c(0, 1), color = "gray") +
  geom_jitter(width = 0.05, height = 0.05) 
print(fk_1)

## 図15.4
## 当落 wlsmd と選挙費用expm の散布図
fk_2 <- ggplot(Fake, aes(x = expm, y = wlsmd)) + 
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "選挙費用（100万円）", y = "選挙での当落") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.25)) +
  geom_hline(yintercept = c(0, 1), color = "gray") +
  geom_jitter(width = 0.05, height = 0.05)
print(fk_2)

## ロジスティック回帰式の推定
model_1 <- glm(wlsmd ~ previous + expm,
               data = Fake,
               family = binomial(link = "logit"))
summary(model_1)


## 図15.5
## 過去の当選回数に応じた当選の予測確率を図示する
## 選挙費用は標本平均に固定する
pred_prev <-  tibble(     # 新しい書き方
              #data_frame( # 古い書き方
  previous = min(Fake$previous):max(Fake$previous),
  expm = mean(Fake$expm))
pred_prev$fit <- predict(model_1, 
                         type = "response",
                         newdata = pred_prev)
plt_prev <- ggplot(Fake, aes(x = previous)) +
  geom_hline(yintercept = c(0, 1), color = "gray") +
  geom_jitter(aes(y = wlsmd), pch = 16,
              width = 0.05, height = 0.05) +
  geom_line(data = pred_prev, aes(y = fit)) +
  geom_point(data = pred_prev, aes(y = fit), pch = 15) +
  labs(x = "過去の当選回数", y = "当選確率")
print(plt_prev)  

## 図15.5
## 選挙費用に応じた当選の予測確率を図示する
## 当選回数は標本平均に固定する
pred_expm <-  tibble(     # 新しい書き方
              #data_frame( # 古い書き方
  expm = seq(0, max(Fake$expm), length.out = 100),
  previous = mean(Fake$previous))
pred_expm$fit <- predict(model_1, 
                         type = "response",
                         newdata = pred_expm)
plt_expm <- ggplot(Fake, aes(x = expm)) +
  geom_hline(yintercept = c(0, 1), color = "gray") +
  geom_jitter(aes(y = wlsmd), pch = 16,
              width = 0.05, height = 0.05) +
  geom_line(data = pred_expm, aes(y = fit)) +
  labs(x = "選挙費用（100万円）", y = "当選確率")
print(plt_expm)  

## 予測の的中率
Pred <- (fitted(model_1) >= 0.5) %>% 
  factor(levels = c(FALSE, TRUE),
         labels = c("落選予測", "当選予測"))
table(Pred, Fake$smd) %>% addmargins()


## ROC曲線とAUC
pi_hat <- predict(model_1, type = "response")
## margins パッケージにも prediction() があるので、ROCR::prediction() と書く
pr <- ROCR::prediction(pi_hat, labels = Fake$wlsmd)
roc <- performance(pr, measure = "tpr", x.measure = "fpr")
df_roc <- tibble(fpr = roc@x.values[[1]],
                 tpr = roc@y.values[[1]])
#df_roc <- data_frame(fpr = roc@x.values[[1]],
#                     tpr = roc@y.values[[1]])  # 古い書き方

## 図15.7：ROC曲線
plt_roc <- ggplot(df_roc, aes(x = fpr, y = tpr)) +
  geom_line() +
  geom_abline(intercept = 0, slope = 1, 
              linetype = "dashed") +
  coord_fixed() +
  labs(x = "偽陽性率（1 - 特異度）",
       y = "真陽性率（感度）")
print(plt_roc)  
## AUC
auc <- performance(pr, measure = "auc")
auc@y.values[[1]]

## 統計的検定
summary(model_1)

## 推定結果を解釈する
## 過去の当選回数が3回で、選挙費用0の候補者の予測当選率
p_0 <- predict(model_1, type = "response",
               newdata  = data_frame(previous = 3,
                                     expm = 0))
## 過去の当選回数が3回で、選挙費用100万円の候補者の予測当選率
p_1 <- predict(model_1, type = "response",
               newdata = data_frame(previous = 3,
                                    expm = 1))
## 過去の当選回数が3回の候補者が、選挙費用を0から100万円に増やす効果
p_1 - p_0

## 過去の当選回数が3回で、選挙費用200万円の候補者の予測当選率
p_2 <- predict(model_1, type = "response",
               newdata = data_frame(previous = 3,
                                    expm = 2))
## 過去の当選回数が3回の候補者が、選挙費用を100万円から200万円に増やす効果
p_2 - p_1

## 過去の当選回数が5、選挙費用が400万円の場合の選挙費用の限界効果
margins(model_1, variables = "expm",
        at = list(previous = 5,
                  expm = 4))

## 過去の当選回数が5で、
## 選挙費用が400万円と580万円の場合の選挙費用の限界効果
margins(model_1, variables = "expm",
        at = list(previous = 5,
                  expm = c(4, 5.8)))

## 図15.8
## 選挙費用の平均限界効果
mplt <- cplot(model_1, x = "expm", what = "effect",
              draw = FALSE) %>%
  as_data_frame() %>% 
  ggplot(aes(x = xvals, y = yvals,
             ymin = lower, ymax = upper)) +
  geom_ribbon(fill = "gray") +
  geom_line() +
  labs(x = "選挙費用 (100万円）",
       y = "選挙費用の平均限界効果")
print(mplt)

## 図15.9
## 選挙費用に応じた予測当選確率の変化
pplot <- cplot(model_1, x = "expm", what = "prediction",
               draw = FALSE) %>%
  as_data_frame() %>% 
  ggplot(aes(x = xvals, y = yvals,
             ymin = lower, ymax = upper)) +
  geom_ribbon(fill = "gray") +
  geom_line() +
  labs(x = "選挙費用（100万円）",
       y = "当選確率の予測値")
print(pplot)


####################################################
## 15.3 衆院選データの分析
####################################################
## 衆院選データの読み込み
HR <- read_rds("data/hr-data.Rds")
#HR <- read_csv("data/hr-data.csv") # csv形式を使う場合
glimpse(HR)  # データの中身を確認する

## 2005年の選挙だけ抜き出し、分析に使う変数のみ残す
HR05 <- HR %>% 
  filter(year == 2005) %>%
  select(smd, previous, expm)
summary(HR05)  # 記述統計の確認

## 欠測のない観測 (complete observations) のみ残す
HR05 <- na.omit(HR05)

## 交差項のないモデルを推定する
model_2 <- glm(smd ~ previous + expm, 
               data = HR05,
               family = binomial(link = "logit"))
summary(model_2)

## 交差項のあるモデルを推定する
model_3 <- glm(smd ~ previous * expm, data = HR05,
               family = binomial(link = "logit"))
summary(model_3)

## 二つのモデルの当てはまり具合を評価する
## 図15.10 ROC曲線
pi2 <- predict(model_2, type = "response")
pi3 <- predict(model_3, type = "response")
pr2 <- ROCR::prediction(pi2, labels = HR05$smd == "当選")
pr3 <- ROCR::prediction(pi3, labels = HR05$smd == "当選")
roc2 <- ROCR::performance(pr2, measure = "tpr", x.measure = "fpr")
roc3 <- ROCR::performance(pr3, measure = "tpr", x.measure = "fpr")
df_roc2 <- data_frame(fpr2 = roc2@x.values[[1]],
                      tpr2 = roc2@y.values[[1]],
                      fpr3 = roc3@x.values[[1]],
                      tpr3 = roc3@y.values[[1]])
roc <- ggplot(df_roc2) +
  geom_line(aes(x = fpr2, y = tpr2), color = "tomato") +
  geom_line(aes(x = fpr3, y = tpr3), 
            linetype = "dashed", color = "dodgerblue") +
  coord_fixed() +
  labs(x = "偽陽性率（1 - 特異度）",
       y = "真陽性率（感度）")
print(roc)  
## AUC
auc2 <- performance(pr2, measure = "auc")
auc2@y.values[[1]]   # model_2 のAUC
auc3 <- performance(pr3, measure = "auc")
auc3@y.values[[1]]   # model_3 のAUC


## 限界効果
margins(model_2, at = list(previous = seq(0, 8, by = 2),
                           expm = seq(5, 20, by = 5)))


## 図15.11 
## 限界効果を図示する
mplt1 <- cplot(model_2, x = "expm", dx = "expm", 
               what = "effect", draw = FALSE) %>% 
  #as_data_frame() %>%  # 古い方法
  as_tibble() %>%      # 新しい方法
  ggplot(aes(x = xvals, y = yvals,
             ymin = lower, ymax = upper)) +
  geom_ribbon(fill = "gray") +
  geom_line() +
  labs(x = "選挙費用 (100万円）",
       y = "選挙費用の平均限界効果") 

mplt2 <- cplot(model_2, x = "previous", dx = "expm",
                what = "effect", draw = FALSE) %>% 
  #as_data_frame() %>%  # 古い方法
  as_tibble() %>%      # 新しい方法
  ggplot(aes(x = xvals, y = yvals,
             ymin = lower, ymax = upper)) +
  geom_ribbon(fill = "gray") +
  geom_line() +
  labs(x = "過去の当選回数",
       y = "選挙費用の平均限界効果") 

mplt3 <- cplot(model_2, x = "expm", dx = "previous",
               what = "effect", draw = FALSE) %>% 
  #as_data_frame() %>%  # 古い方法
  as_tibble() %>%      # 新しい方法
  ggplot(aes(x = xvals, y = yvals,
             ymin = lower, ymax = upper)) +
  geom_ribbon(fill = "gray") +
  geom_line() +
  labs(x = "選挙費用 (100万円）",
       y = "当選回数の平均限界効果") 

mplt4 <- cplot(model_2, x = "previous", dx = "previous",
               what = "effect", draw = FALSE) %>% 
  #as_data_frame() %>%  # 古い方法
  as_tibble() %>%      # 新しい方法
  ggplot(aes(x = xvals, y = yvals,
             ymin = lower, ymax = upper)) +
  geom_ribbon(fill = "gray") +
  geom_line() +
  labs(x = "過去の当選回数",
       y = "当選回数の平均限界効果") 
## 四つの図を2行2列に並べて表示する: patchwork パッケージを利用
mplt1 + mplt2 + mplt3 + mplt4 + plot_layout(ncol = 2, nrow = 2)
## 一つずつ表示したいときは以下を実行
#print(mplt1)
#print(mplt2)
#print(mplt3)
#print(mplt4)

## 15.12
## 選挙費用に応じて予測当選確率が変わる様子を、当選回数別に図示
df_pre <- expand.grid(previous = seq(0, 16, by = 2),
                      expm = seq(0, 24, by = 0.1)) %>%
  #as_data_frame() %>%  # 古い方法
  as_tibble()          # 新しい方法
pred <- predict(model_2, type = "response",
                newdata = df_pre, se.fit = TRUE)
df_pre$fit <- pred$fit
df_pre$lower <- with(pred, fit - 2 * se.fit)
df_pre$upper <- with(pred, fit + 2 * se.fit)
df_pre <- df_pre %>% 
  mutate(lower = ifelse(lower < 0, 0, lower),
         upper = ifelse(upper > 1, 1, upper))
plt_prob  <- ggplot(df_pre, aes(x = expm, y = fit)) +
  geom_ribbon(aes(ymin = lower, ymax = upper),
              fill = "gray") +
  geom_line() +
  facet_wrap(. ~ previous) +
  labs(x = "選挙費用（100万円）", y = "当選確率の予測値")
print(plt_prob)
