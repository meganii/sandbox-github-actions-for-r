library(tidyverse)
library(lubridate)
library(ggimage)
library(ggtext)

# 前処理したdata.csvを読み取り、初期化
df <- read_csv(
  'data.csv',
  col_types = cols(
    Name = col_character(),
    Date = col_date(format = "%Y-%m-%d")
  )) %>%
  arrange(Date, Name) %>%
  group_by(Name) %>%
  mutate(
    End = dplyr::if_else((Date + months(1)) == lead(Date), lead(Date), ymd(NA)),
    Start = dplyr::if_else(is.na(End), ymd(NA), Date)
  )

# ラベルとして利用する名前リストを作成
orderedName <- df %>%
  group_by(Name) %>%
  top_n(-1, Date) %>%
  select(Name, Date) %>%
  mutate(Image = paste0("./icons/", Name, ".png"))

# 名前リストを軸として利用
df2 <- df %>%
  mutate(Name = factor(Name, levels = orderedName$Name))

# x軸の最小・最大を設定（全期間）
xmin <- min(df2$Date) - months(6) # 名前表示のための空白を確保
xmax <- max(df2$Date) + days(1) + months(1)

# 全期間のplot
p <- ggplot(df2, aes(Date, Name)) +
  geom_point(aes(x = Date, colour = Name)) +
  geom_linerange(aes(
    xmin = Start,
    xmax = End,
    colour = Name
  )) +
  geom_image(data = orderedName,
             aes(x = Date, y = Name, image = Image),
             size = 0.010) +
  geom_text(
    data = orderedName,
    aes(
      x = Date - 15,
      y = Name,
      vjust = 0.5,
      hjust = 1
    ),
    label = orderedName$Name,
    size = 3
  ) +
  scale_x_date(
    date_labels = "%Y/%m",
    breaks = "6 months",
    minor_breaks = "1 month",
    limits = c(xmin, xmax)
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank()
  )

ggsave(
  file = "./images/activeusers.png",
  plot = p,
  dpi = 300,
  width = 10,
  height = 10
)

ggsave(
  file = "./images/activeusers_thumb.png",
  plot = p,
  dpi = 72,
  width = 10,
  height = 10
)


# 半年前でフィルタ
six_months_ago = (floor_date(Sys.Date(), "month") - months(6))
df3 <- filter(df2, Date > six_months_ago)

orderedName2 <- df3 %>%
  group_by(Name) %>%
  top_n(-1, Date) %>%
  select(Name, Date) %>%
  mutate(Image = paste0("./icons/", Name, ".png"))


df4 <- df3 %>%
  mutate(Name = factor(Name, levels = orderedName2$Name))

xmin <- min(df4$Date) - months(2)
xmax <- max(df4$Date) + days(1) + months(1)

# 半年間のplot
p2 <- ggplot(df4, aes(Date, Name)) +
  geom_point(aes(x = Date, colour = Name)) +
  geom_linerange(aes(
    xmin = Start,
    xmax = End,
    colour = Name
  )) +
  geom_image(data = orderedName2,
             aes(x = Date, y = Name, image = Image),
             size = 0.025) +
  geom_text(
    data = orderedName2,
    aes(
      x = Date - 15,
      y = Name,
      vjust = 0.5,
      hjust = 1
    ),
    label = orderedName2$Name,
    size = 3
  ) +
  scale_x_date(
    date_labels = "%Y/%m",
    # breaks = "6 months",
    minor_breaks = "1 month",
    limits = c(xmin, xmax)
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank()
  )


ggsave(
  file = "./images/activeusers_half.png",
  plot = p2,
  dpi = 300,
  width = 4,
  height = 4
)

ggsave(
  file = "./images/activeusers_half_thumb.png",
  plot = p2,
  dpi = 72,
  width = 4,
  height = 4
)