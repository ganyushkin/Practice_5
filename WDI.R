# Загрузка данных WDI
# Показатель: Labor force, total
# Год: 2020
library('WDI')

# Индикатор показателя
indicator.code <- 'SL.TLF.TOTL.IN'

# Парсим данные с WDI
data <- data.table(WDI(indicator = indicator.code, start = 2020, end = 2020))

# Загружаем данные в csv файл
write.csv(data, file = './data/WDI.csv', row.names = F)
