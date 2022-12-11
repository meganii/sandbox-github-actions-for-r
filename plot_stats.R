if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,
  jsonlite,
  lubridate,
  ggpubr,
  patchwork
)
as_datetime(1500000000, tz = "Asia/Tokyo")

# Get Stats
df <-
  fromJSON(
    "https://raw.githubusercontent.com/meganii/sandbox-github-actions-scheduler/main/villagepump/stats/pages.json"
  ) %>%
  as_tibble %>%
  tibble::rownames_to_column("page_num") %>%
  unnest_wider(pages) %>% 
  mutate(created = as.Date(as_datetime(created)),
         updated = as.Date(as_datetime(updated)),
         page_num = as.numeric(page_num))


weekly_counts <- df %>% 
  mutate(week = floor_date(created, unit = "week")) %>% 
  count(week) %>% 
  complete(
    week = seq.Date(
      from = min(week, na.rm=T),
      to = max(week, na.rm=T),
      by = "week"),
    fill = list(n = 0))
weekly_counts


month_counts <- df %>% 
  mutate(month = floor_date(created, unit = "month")) %>% 
  count(month) %>% 
  complete(
    month = seq.Date(
      from = min(month, na.rm=T),
      to = max(month, na.rm=T),
      by = "month"),
    fill = list(n = 0))
month_counts


# Calc diff
page_unit <- 1000
df2 <- df %>%
  filter(page_num %% page_unit == 0) %>%
  mutate(
    prev_val = dplyr::if_else(is.na(lag(created)), as.Date('2020-01-19'), lag(created)),
    days = as.numeric(ymd(created) - ymd(prev_val)),
    "Δpages/days" = round(page_unit / days, 1)
  ) %>% 
  select(1, 6, 9:10)
df2

# Created pages by Month
Grid_Fig2 <- ggplot(month_counts, aes(month, n)) +
  geom_bar(stat="identity") + 
  scale_x_date(
    expand = c(0,0),             # 両端の余分なスペースを削除
    # 1ヶ月ごとに軸ラベルを表示する
    date_breaks = "1 months",
    # 月・日をラベルとして表示する
    date_labels = "%y-%m"
  ) +
  theme(axis.text.x = element_text(angle=45, hjust=1)) +
  labs(title = "Pages per month") +
  xlab("Created Month") +
  ylab("page_num")

Grid_Fig1 <- ggplot(df, aes(created, page_num)) +
  geom_line() +
  geom_point(data= df2, aes(x = created, y = page_num), colour = "red3") +
  scale_y_continuous(breaks = seq(from=0, to=13000, by=1000)) +
  scale_x_date(
    expand = c(0,0),            # 両端の余分なスペースを削除
    date_breaks = "1 month",    # 1ヶ月ごとに軸ラベルを表示する
    date_labels = "%m"          # 月をラベルとして表示する
  ) + 
  xlab("") +
  labs(title = "Total pages")

xlimits <- coord_cartesian(xlim = c(ymd('2020-01-01'), ymd('2023-01-01'))) # xlim() はNG
p <- wrap_plots(Grid_Fig1 + xlimits, Grid_Fig2 + xlimits, nrow = 2)

## Save to png
ggsave(file = "./images/stats.png", plot = p)
