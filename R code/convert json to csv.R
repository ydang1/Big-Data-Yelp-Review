rm(list=ls())
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#library(data.table)
yelp <- fread("yelp_academic_dataset_review.csv", sep = ",", header = TRUE, stringsAsFactors = TRUE, nrow=100000)
yelp_business <- fread("yelp_academic_dataset_business.csv", sep = ",", header = TRUE, stringsAsFactors = TRUE)
colnames <- as.factor(c("business_id","categories"))
business <- yelp_business[,..colnames]


business$categories<-tolower(business$categories)
business_dentist <- grep("dental|dentist|dentistry|denture|dent",business$categories)
business_dentist2 <- grep("dental|dentist|dentistry|denture",business$categories)


business_id <- as.data.table(business[unique(business_dentist),])
business_id2 <- as.data.table(business[unique(business_dentist2),])

setkey(business_id, categories)
setkey(business_id2, categories)

business_id12 <- merge(x=business_id, y=business_id2, by="business_id", all.x = TRUE)
miss <- which(is.na(business_id12$categories.y))
business_missing <- business_id12[miss,]

business_id_2<- unique(business_id2[,1])
fwrite(business_id_2, file = "business_id_2.csv")

fwrite(business_id, file="business_id.csv")
dentist_review <-merge(yelp, business_id)

## text mining
library(RTextTools)
library(data.table)
library(ggplot2)
dentist <-fread("dentist.csv", sep = ",", header = TRUE, stringsAsFactors = TRUE)[,-1]
dentist$text <- as.character((dentist$text))
matrix <- create_matrix(dentist$text, language="english", removeSparseTerms = 0.9, removeStopwords = TRUE,
                       removeNumbers = TRUE, stemWords = TRUE, stripWhitespace = TRUE, toLower = TRUE)
mat <- t(as.matrix(matrix))
term.freq <- rowSums(as.matrix(mat))
df <- data.frame(term=names(term.freq), freq=term.freq)

