library(tidyverse)
library(lubridate)
library(ggimage)
library(ggtext)

df <- read_csv('data.csv') %>%
  group_by(Name) %>%
  mutate(
    Date = as.Date(Date),
    End = dplyr::if_else((Date + months(1)) == lead(Date), lead(Date), ymd(NA)),
    Start = dplyr::if_else(is.na(End), ymd(NA), Date)
  )
df

orderedName <- df %>%
  group_by(Name) %>%
  top_n(-1, Date) %>%
  select(Name, Date) %>%
  mutate(Image = paste0("./icons/", Name, ".png"))
orderedName

df2 <- df %>%
  mutate(Name = factor(Name, levels = orderedName$Name))
df2

xmin <- min(df2$Date) - months(6)
xmax <- max(df2$Date) + days(1) + months(1)

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