## ch06.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第6章 記述統計とデータの可視化・視覚化
##
## Created: 2018-11-22 Yuki Yanai


## tidyverseパッケージをインストール済みでない場合はインストール
if(!requireNamespace("tidyverse")) install.packages("tidyverse")

## tidyverse パッケージを読み込む
library("tidyverse")
## 次の行はMacユーザのみ実行する（Windowsユーザは削除するかコメントアウトする）
theme_set(theme_gray(base_size = 10, base_family = "HiraginoSans-W3"))


####################################################
## 6.1  変数の種類と記述統計
####################################################

## hr96-17.Rds を読み込む
## 持っていない場合はまずダウンロード（4章で保存した場合はダウンロード不要）
#download.file(url = "https://git.io/fACk6",
#             destfile = "data/hr96-17.Rds")
HR <- read_rds("data/hr96-17.Rds")

## hr96-17.Rds の読み込みに失敗する場合は、hr96-17.csv を使う
#download.file(url = "https://git.io/fAnI2",
#              destfile = "data/hr96-17.csv")
#HR <- read_csv("data/hr96-17.csv", na = ".")

## データフレームの中身を確認する
glimpse(HR)

summary(HR)  # 基本的な統計量を確認

## voteshare の標準偏差
sd(HR$voteshare)

## ageの平均値、中央値、標準偏差
mean(HR$age, na.rm = TRUE)
median(HR$age, na.rm = TRUE)
sd(HR$age, na.rm = TRUE)

## カテゴリ変数の特徴を掴むために表を作る
table(HR$wl)
with(HR, table(wl))  # 上の行とほぼ同じ

class(HR$wl)  # class属性の確認

## wl を factor型に変換する
HR <- mutate(HR, wl = factor(wl, levels = 0:2,
                             labels = c("落選", "当選", "復活当選")))
class(HR$wl)         # class属性の確認
with(HR, table(wl))  # もう1度表を!

## status をfactor型に
HR <- HR %>% 
  mutate(status = factor(status, levels = 0:2,
                         labels = c("新人", "現職", "元職")))
with(HR, table(status))

## smd をfactor 型に
HR <- HR %>% 
  mutate(smd = factor(smd, levels = 0:1,
                      labels = c("落選", "当選")))
with(HR, table(smd))

## このデータを新しいRdsファイルに保存する
write_rds(HR, path = "data/hr-data.Rds")


## 2変数のクロス表を作る
with(HR, table(status, wl))

## 対象を2009年の衆院選に限定する
HR %>% 
  filter(year == 2009) %>% 
  with(table(status, wl))

## statusのカテゴリ別にvoteshareの統計量を調べる
HR %>% 
  group_by(status) %>% 
  summarize(mean = mean(voteshare),
            median = median(voteshare),
            sd = sd(voteshare))

## statusのカテゴリ別にage, voteshare, exp の平均値を求める
HR %>% 
  group_by(status) %>% 
  summarize(age = mean(age, na.rm = TRUE),
            voteshare = mean(voteshare),
            exp = mean(mean(exp, na.rm  = TRUE)))


####################################################
## 6.2  変数の可視化・視覚化
####################################################

## 図6.1
## 4ステップで得票率voteshareと選挙費用expmの散布図を作る
## 1. ggplot オブジェクトを作る
scat1 <- ggplot(data = HR, mapping = aes(x = expm, y = voteshare))
## 2. 散布図の層 (layer) を加える
scat1 <- scat1 + geom_point()
## 3. 軸ラベルとタイトルを加える
scat1 <- scat1 + 
  labs(x  = "選挙費用（100万円）", y = "得票率 (%)",
       title = "散布図の例1：衆院選挙, 1996-2014")
## 4. 図を表示 (print) する
print(scat1)

## 図6.2
## 対象を1996年選挙に限定し、上の4ステップの最初の三つを一挙に実行する
scat2 <- HR %>%
  filter(year == 1996) %>%
  ggplot(aes(x = expm, y = voteshare)) +
  geom_point() +
  labs(x  = "選挙費用（100万円）", y = "得票率 (%)",
       title = "散布図の例2：1996衆院選")
print(scat2)

## 図6.3
## 選挙費用expmのヒストグラムを作る
hist1 <- ggplot(HR, aes(x = expm)) +
  geom_histogram(color = "black") + 
  labs(x = "選挙費用（100万円）", y = "度数")
print(hist1)

## ヒストグラムの縦軸を確率密度 (density) に変える
hist2 <- ggplot(HR, aes(x = expm, y = ..density..)) +
  geom_histogram(color = "black") + 
  labs(x = "選挙費用（100万円）", y = "確率密度")
print(hist2)


## 年齢ageの五数要約
fivenum(HR$age)

## 図6.5
## 政党party_jpn別に2009年衆院選の選挙費用expmの箱ひげ図を作る
box1 <- HR %>%
  filter(year == 2009) %>%
  filter(party_jpn %in% c("自民党", "民主党", "公明党", 
                          "社民党", "共産党")) %>%
  ggplot(aes(x = party_jpn, y = expm)) +
  geom_boxplot() +
  labs(x = "政党", y = "選挙費用 (100万円)")
print(box1)

## 図6.6
## 上の図にバイオリンプロットを加える
vln1 <- HR %>% 
  filter(year == 2009) %>% 
  filter(party %in% c("LDP", "DPJ", "CGP", "SDP", "JCP")) %>% 
  ggplot(aes(x = party_jpn, y = expm)) +
    geom_violin() +
  geom_boxplot(fill = "gray", width = 0.1) +
  labs(x = "政党", y = "選挙費用（100万円）")
print(vln1)


## 図を保存するために figs ディレクトリを作る
dir.create("figs")

## 得票率のヒストグラムを作る
hist3 <- ggplot(HR, aes(x = age)) +
  geom_histogram( binwidth = 5, color = "black")
print(hist3)

## 得票率のヒストグラムをPDFファイルに保存する
## ただし、上で theme_set() を使った場合、この方法は使えない
ggsave(filename = "figs/hist-age.pdf", plot = hist3,
       width = 10, height = 5, units = "cm")


## Mac で日本語を含む図を保存する方法
## 上で作った hist1 をPDFファイルに保存する
quartz(file = "figs/hist-exp.pdf", type = "pdf", family = "sans",
       width = 3, height = 2, pointsize = 10)
print(hist1)
dev.off()


## Windows で日本語を含む図を保存する方法
## 上で作った hist1 をPDFファイルに保存する
#pdf(file = "figs/hist-exp.pdf", family = "Japan1GothicBBB", width = 3, height = 2)
#print(hist1)
#dev.off()
