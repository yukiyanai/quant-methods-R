## ch07.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第7章 統計的推定
##
## Created: 2018-11-22 Yuki Yanai

## tidyverse パッケージを読み込む
library("tidyverse")
## 次の行はMacユーザのみ実行する（Windowsユーザは削除するかコメントアウトする）
theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))


####################################################
## 7.1  母集団と標本
####################################################

## Rコードなし

####################################################
## 7.2  標本分布
####################################################

## 10万人の母集団の身長を設定する
## 身長の母平均は170cm、母標準偏差は6とする
set.seed(2018-11-20)  # 乱数の種を設定する。
population <- rnorm(100000, mean = 170, sd = 6)
mean(population)
sd(population)

## 図7.3 母集団の分布
hist_pop <- data_frame(pop = population) %>% 
  ggplot(aes(x = pop, y = ..density..)) +
    geom_histogram(binwidth = 1, color = "black") +
    xlim(140, 200) + ylim(0, 0.6) +
    labs(x = "身長 (cm)", y = "確率密度")
print(hist_pop)

## 上で定義した母集団から、サイズ10の標本を500個抽出する
## 結果を保存するために、10行x500列の空の行列を用意する
size10 <- matrix(NA, nrow = 10, ncol = 500)
for (i in 1:500) { # 標本抽出を500回繰り返す
  size10[, i] <- sample(population, size = 10, replace = FALSE)
}
## それぞれの標本での平均値を計算し、データフレームの1変数として保存する
df <- data_frame(means_s10 = colMeans(size10))

## 図7.4
## 標本平均の標本分布をヒストグラムにする
hist_size10 <- ggplot(df, aes(x = means_s10, y = ..density.. )) +
  geom_histogram(binwidth = 1, color = "black") +
  xlim(140, 200) + ylim(0, 0.6) +
  labs(x = expression(paste("身長の標本平均 ", bar(x), " (cm)")),
       y = "確率密度")
print(hist_size10)

## 標本サイズ10の場合の標本平均のばらつき（標準誤差）を計算する
sd(df$means_s10)

## 上で定義した母集団から、サイズ90の標本を500個抽出する
## 結果を保存するために、90行x500列の空の行列を用意する
size90 <- matrix(NA, nrow = 90, ncol = 500)
for (i in 1:500) { # 標本抽出を500回繰り返す
  size90[, i] <- sample(population, size = 90, replace = FALSE)
}
## それぞれの標本での平均値を計算し、データフレームの1変数として保存する
df <- mutate(df, means_s90 = colMeans(size90))

## 図7.5
## 標本平均の標本分布をヒストグラムにする
hist_size90 <- ggplot(df, aes(x = means_s90, y = ..density.. )) +
  geom_histogram(binwidth = 1, color = "black") +
  xlim(140, 200) + ylim(0, 0.6) +
  labs(x = expression(paste("身長の標本平均 ", bar(x), " (cm)")),
       y = "確率密度")
print(hist_size90)

## 標本サイズ90の場合の標本平均のばらつき（標準誤差）を計算する
sd(df$means_s90)

## 標本サイズ10の場合と90の場合の標本のばらつきの比
sd(df$means_s10) / sd(df$means_s90)


####################################################
## 7.3  母平均の推定と信頼区間
####################################################

## 図7.6 t分布
df_t <- data_frame(x = seq(-3, 3, length.out = 100)) %>% 
  mutate(`1` = dt(x, df = 1),
         `5` = dt(x, df = 5),
         `99` = dt(x, df = 99)) %>% 
  gather(key = "df", value = "density", `1`:`99`)
t_dist <- ggplot(df_t, aes(x = x, y = density,
                           color = df, linetype = df)) +
  geom_line() +
  labs(x = "", y = "確率密度") +
  scale_x_continuous(breaks = -3:3) +
  scale_color_discrete(name = "自由度") + 
  scale_linetype_discrete(name = "自由度") +
  guides(shape = guide_legend(reverse = TRUE)) 
print(t_dist)


## 自由度99のt分布で、データの95%が収まる範囲の上限値を求める
qt(p = 0.025, df = 99, lower.tail = FALSE)
# または、
qt(p = 0.975, df = 99, lower.tail = TRUE)
## 同様に、下限値を求める
qt(p = 0.025, df = 99, lower.tail = TRUE)


## 上で定義した母集団（身長の母平均が約170）から
## 標本サイズ100の標本を1,000個抽出し、
## それぞれの標本について信頼区間を求める
n <- 100
res <- matrix(NA, nrow = n, ncol = 1000)
for (i in 1:1000) {
  res[, i] <- sample(population, size = n, replace = FALSE)
}
## それぞれの標本の平均と標準偏差を求めてデータフレームの変数にする。
## その後、標準誤差 se と95%信頼区間の下限 lb、上限ub を計算するn
df_ci <- data_frame(id = 1:1000,
                    means = colMeans(res),
                    sds = apply(res, MARGIN = 2, FUN = sd)) %>% 
  mutate(se = sds / sqrt(n),
         lb = means + qt(p = 0.025, df = 99, lower.tail = TRUE) * se,
         ub = means + qt(p = 0.025, df = 99, lower.tail = FALSE) * se)
## 結果の一部を見てみる
head(df_ci)

## 信頼区間の中に真の母平均が含まれているかどうか判定する変数を作る
(pop_mean <- mean(population)) # 真の母平均
df_ci <- mutate(df_ci,
                success = (lb <= pop_mean & ub >= pop_mean))
## 母平均を区間内に捉えた95%信頼区間の割合を計算する
mean(df_ci$success)

## 1000個の標本から50個をランダムに選び、95%信頼区間を図示する。
set.seed(2018-11-22)
ci_plt <- sample_n(df_ci, size = 50) %>% 
  ggplot(aes(x = reorder(id, means), y = means, 
             ymin = lb, ymax = ub, color = success)) +
  geom_hline(yintercept = pop_mean, color = "dodgerblue") +
  geom_linerange() +
  geom_point() +
  scale_color_discrete(name = "母数を含む?") +
  labs(x = "", y = "標本平均と95%信頼区間") +
  coord_flip()
print(ci_plt)


## 例7.4：衆院データを使って信頼区間を求める
HR <- read_rds("data/hr-data.Rds")
## Rdsファイルの読み込みがうまくいかない場合は以下を実行
#download.file(url = "https://git.io/fxhQU",
#              destfile = "data/hr-data.csv")
#HR <- read_csv("data/hr-data.csv")

## 候補者の年齢ageの50%信頼区間を求める
age_ci50 <- t.test(HR$age, conf.level = 0.5)
age_ci50$conf.int

## 候補者の年齢ageの95%信頼区間を求める
age_ci95 <- t.test(HR$age)
age_ci95$conf.int
