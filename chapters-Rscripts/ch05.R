## ch05.R
##
## 浅野正彦・矢内勇生. 2018. 『Rによる計量政治学』オーム社
## 第5章 Rによるデータ操作
##
## Created:  2018-11-22 Yuki Yanai
## Modified: 2021-05-27 Yuki Yanai


####################################################
## 5.1  データセットの読み込み
####################################################

## プロジェクト（現在の作業ディレクトリ）内に data ディレクトリ（フォルダ）を作る
dir.create("data")

## 衆院選データ hr96-17.csv をダウンロードし、dataディレクトリに保存する
download.file(url = "https://git.io/fAnI2",
              destfile = "data/hr96-17.csv")

## ダウンロードしたデータを読み込み、データフレームを作る
HR <- readr::read_csv("data/hr96-17.csv", na = ".")


####################################################
## 5.2  読み込んだデータの確認
####################################################

## 身長データ height.csv をダウンロードし、dataディレクトリに保存する
download.file(url = "https://git.io/fAnIr",
              destfile = "data/height.csv")

## 身長データを読み込み、データフレームを作る
myd <- readr::read_csv("data/height.csv")

names(myd)  # 変数名の確認
head(myd)   # 冒頭部分の確認

## dplyr パッケージを読み込む。本当は、Rスクリプトの冒頭で読み込むべき
library("dplyr")

glimpse(myd)  # myd の中身を確認する


####################################################
## 5.3  データの整形
####################################################

## 衆院選データを読み込んで、中身を確認する
HR <- readr::read_csv("data/hr96-17.csv", na = ".")
glimpse(HR)

## expm という新しい変数を作る
HR <- mutate(HR, expm = exp / 10^6)

## vs と exppv という新しい変数を作る
HR <- mutate(HR,
             vs = voteshare / 100,
             exppv = exp / eligible)

## 2017年選挙に立候補した自民党以外の候補者だけ抜き出す
HR07_nonLDP <- filter(HR, year == 2017, party != "LDP")

## 小選挙区での勝利を示す変数 smd を作る
HR <- mutate(HR, smd = ifelse(wl == 1, 1, 0))
with(HR, table(smd, wl))  # 正しくできたか確認

## 特定の変数だけ抜き出す
HR_sml_1 <- select(HR, party, voteshare, exp)
HR_sml_2 <- select(HR, -voteshare, -expm)
HR_sml_3 <- select(HR, party:status)
HR_sml_4 <- select(HR, starts_with("v"))

## データの並べ替え
HR_sorted_1 <- arrange(HR, voteshare)
HR_sorted_2 <- arrange(HR, desc(voteshare))

## 変数の名前を変更する
HR_sorted_3 <- rename(HR_sorted_2, district = ku)


## パイプ演算子
(10 - 6) %>% sqrt()
sqrt(10 - 6)  # 上の行と同じ

HR09 <- HR %>% 
  filter(year == 2009) %>% 
  arrange(desc(voteshare)) %>% 
  mutate(order =1 :n()) %>% 
  arrange(ku, kun, party) %>% 
  filter(age > 40) %>% 
  select(ku, kun, party, name, order)

(10 - 2) %>% seq(from = 2, to = ., by = 2)
seq(from = 2, to = (10 - 2), by = 2)  # 上の行と同じ


## 横長データ wide-table.csv をダウンロードし、dataディレクトリに保存
download.file(url = "https://git.io/fAnmx",
              destfile = "data/wide-table.csv")
## データを読み込む
GDP <- readr::read_csv("data/wide-table.csv")
GDP  # 小規模データなので全部表示

## 横長データを縦長に変換する (1)： 教科書で説明した方法（古い方法）
long <- tidyr::gather(data = GDP, key = "year",
                      value = "gdp", starts_with("gdp"))
long  # 小規模データなので全部表示


## 横長データを縦長に変換する (2)：  教科書で説明した方法（古い方法）
long <- GDP %>%
  rename(`2000` = gdp2000,
         `2005` = gdp2005,
         `2010` = gdp2010) %>%
  tidyr::gather(key = "year", value = "gdp", `2000`:`2010`) %>%
  arrange(country)
long  # 小規模データなので全部表示


## 横長データを縦長に変換する新しい方法：教科書出版後に登場した方法
long_new <- GDP %>% 
  tidyr::pivot_longer(
    cols = gdp2000:gdp2010,
    names_to = "year",
    names_prefix = "gdp",
    values_to = "gdp")
long_new  # 小規模データなので全部表示


# 縦長を横長にする： 教科書で説明した方法（古い方法）
wide <- long %>%
  tidyr::spread(key = "year", value = "gdp") %>%
  rename(gdp2000 = `2000`,
         gdp2005 = `2005`,
         gdp2010 = `2010`)
wide  # 小規模データなので全部表示


# 縦長を横長にする：教科書出版後に登場した方法
wide_new <- long_new %>% 
  tidyr::pivot_wider(
    names_from = "year",
    names_prefix = "gdp",
    names_sep = "",
    values_from = "gdp")
wide_new


## 表5.3, 5.4, 5.5 と同内容の表を作る： 教科書で説明した方法（古い方法：警告が出る）
A <- data_frame(country = c("Japan", "USA"),
                presidential = c(FALSE, TRUE),
                federal = c(FALSE, TRUE))
A 
B <- data_frame(country = c("France", "Germany"),
                presidential = c(TRUE, FALSE),
                federal = c(FALSE, TRUE))
B
C <- data_frame(country = c("Japan", "USA"),
                two_party = c(FALSE, TRUE),
                EU = c(FALSE, FALSE))
C


## 表5.3, 5.4, 5.5 と同内容の表を作る： 教科書出版後に登場した新しい方法
A <- tibble(country = c("Japan", "USA"),
            presidential = c(FALSE, TRUE),
            federal = c(FALSE, TRUE))
A 
B <- tibble(country = c("France", "Germany"),
            presidential = c(TRUE, FALSE),
            federal = c(FALSE, TRUE))
B
C <- tibble(country = c("Japan", "USA"),
            two_party = c(FALSE, TRUE),
            EU = c(FALSE, FALSE))
C


## AとBを縦に結合する
(AB <- bind_rows(A, B))

## AとCを横に結合する
(AC <- full_join(A, C, by = "country"))

## AB にCを横から結合する (1)
left_join(AB, C, by = "country")
full_join(AB, C, by = "country")
## 欠測値を手作業で埋める
full_join(AB, C, by = "country") %>%
  mutate(EU = ifelse(country %in% c("France", "Germany"),
                     TRUE, EU),
         two_party = ifelse(country %in% c("France", "Germany"),
                            FALSE, two_party))

## AB にCを横から結合する (2)
inner_join(AB, C, by = "country")
right_join(AB, C, by = "country")
left_join(C, AB, by = "country")  # 上と同じ


## 日本語政党名が記されたファイルをダウンロードして保存
download.file(url = "https://git.io/fAwuk",
              destfile = "data/parties.csv")
## 政党名データを読み込んで中身を確認する
Pty <- readr::read_csv("data/parties.csv")
glimpse(Pty)

## 衆院選データに日本語の政党名を加える
HR <- full_join(HR, Pty, by = "party")

## 結果を確認する
HR %>%
  select(party, party_jpn) %>%
  unique()

with(HR, table(party, party_jpn))


####################################################
## 5.4  データの保存
####################################################

## 衆院選データに変更を加えたものを、新しいRdsファイルとして保存する
## 教科書で説明した方法（古い方法：警告が出る）
readr::write_rds(HR, path = "data/hr96-17.Rds")

## 衆院選データに変更を加えたものを、新しいRdsファイルとして保存する
## 教科書出版後に登場した新しい方法
readr::write_rds(HR, file = "data/hr96-17.Rds")
