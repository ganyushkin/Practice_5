# Загрузка данных с сайта Data.gov.ru

library('httr')
library('jsonlite')
library('XML')
library('RCurl')
library('data.table')

# Портал открытых данные РФ

# API ключ для работы с порталом
API.key <- '03d84fb52730b8176c67276b94ea302e'
# Ссылка для работы с API
URL.base <- 'http://data.gov.ru/api/'

# работа с API портала открытых данных РФ
getOpenDataRF <- function(api.params, url.base = URL.base, api.key = API.key){
  par <- paste0(api.params, collapse = '/')
  url <- paste0(url.base, par, '/?access_token=', api.key)
  message(paste0('Загружаем ', url, ' ...'))
  resp <- GET(url)
  fromJSON(content(resp, 'text'))
}

# id показателя
dataset_id <- '4401168294-oknkosobl'

# Задаем параметры и получаем данные
params <- c('dataset', dataset_id)
dataset <- getOpenDataRF(params)

# Количество версий таблицы
params <- c(params, 'version')
versions <- getOpenDataRF(params)

nrow(versions)

# Загружаем последнюю версию в объект doc
mrv <- versions[nrow(versions), 1]
params <- c(params, mrv)
content <- c(params, 'content')
doc <- getOpenDataRF(content)

# Оставляем только те данные в которых присутствует поселок Пурпе
doc <- doc[grep('г. Кострома', doc$Адрес), ]
doc <- doc[c(-80), ]
# Яндекс карды для получения координат
API.key <- '334fd061-f946-494c-8a4d-1b0d74da1764'
URL.base <- 'https://geocode-maps.yandex.ru/1.x/'

# работа с API Yandex Карт
getYandexMaps <- function(api.params, url.base = URL.base, api.key = API.key){
  par <- paste0(api.params, collapse = '&')
  url <- paste0(url.base, '?format=xml&apikey=', api.key, par)
  message(paste0('Загружаем ', url, ' ...'))
  doc.ya <- content(GET(url), 'text', encoding = 'UTF-8')
  
  rootNode <- xmlRoot(xmlTreeParse(doc.ya, useInternalNodes = TRUE))
  coords <- xpathSApply(rootNode, "//*[name()='Envelope']/*", xmlValue)
  coords <- lapply(strsplit(coords, ' '), as.numeric)
  coords <- c((coords[[1]][1] + coords[[2]][1])/2, (coords[[1]][2] + coords[[2]][2])/2)
  names(coords) <-c('lat', 'long')
  coords
}

params <-paste0('&geocode=', gsub(pattern =' ', replacement ='+',
                                  curlEscape(doc$Адрес[1])))

# Парсим координаты
coords <- sapply(as.list(doc$Адрес), function(x){
  params <- paste0('&geocode=', gsub(curlEscape(x), pattern = ' ',
                                     replacement = '+'))
  try(getYandexMaps(params))
})

df.coords <- as.data.frame(t(coords))
colnames(df.coords) <- c('long', 'lat')

#Добавляем координаты в основной фрейм данных
doc <- cbind(doc, df.coords)
colnames(doc)[2] <- 'name'
doc
# Сохраняем данные в файл
write.csv2(doc, file = './data/Data_gov_ru.csv', row.names = F)
