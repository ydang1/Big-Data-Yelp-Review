rm(list=ls())
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#library(data.table)
yelp <- fread("yelp_academic_dataset_review.csv", sep = ",", header = TRUE, stringsAsFactors = TRUE)
yelp_business <- fread("yelp_academic_dataset_business.csv", sep = ",", header = TRUE, stringsAsFactors = TRUE)
colnames <- as.factor(c("business_id","categories"))
business <- yelp_business[,..colnames]

#business_dentist <- grep("DENT|Dent|dent",business$categories)

#business_id <- business[unique(business_dentist),]
#dentist_review <-merge(yelp, business_id)

## text mining
library(RTextTools)
library(data.table)
library(ggplot2)
library(ROAuth)
library(plyr)
library(stringr)
library(plotly)
library(maxent)

#count the words frequencies
dentist <-fread("dentist.csv", sep = ",", header = TRUE, stringsAsFactors = TRUE)[,-1]
dentist$text <- as.character((dentist$text))
dentist$stars <- as.numeric(dentist$stars)
dentist$positive <- ifelse(dentist$stars==1&2, 0,1)
matrix <- create_matrix(dentist$text, language="english", removeSparseTerms = 0.89, removeStopwords = TRUE,
                        removeNumbers = TRUE, stemWords = TRUE, stripWhitespace = TRUE, toLower = TRUE, weighting = weightTf)
mat <- as.matrix(matrix)
mat <- as.data.table(mat)
fwrite(mat, file="DTM.csv")


term.freq <- rowSums(t(as.matrix(mat)))
df <- data.frame(term=names(term.freq), freq=term.freq)
ggplot(df, aes(x=term, y=freq))+geom_bar(stat="identity")+xlab("Terms")+ylab("Count")




#logistic regression
dentist$positive <- ifelse(dentist$stars==1&2,0,1)
positive <- dentist$positive


set.seed(12345)
training<- sample(nrow(mat ), nrow(mat )*0.7)
train_x<-mat[training,]
test_x<-mat[-training,]
training_y <-positive[training]
testing_y <-positive[-training]

model <- maxent(train_x, training_y)
predictions <- predict(model, test_x)
table(testing_y, as.factor(predictions[,1]),dnn=c("Actual", "Predicted"))
sum((predictions[,1]==testing_y))/nrow(predictions)


#baseline
testing_y <- as.matrix(testing_y)
sum(testing_y==1)/nrow(testing_y)




#or with cross validation
library(lattice)
library(caret)
mat_new <-cbind(mat,positive)
mat_new=as.data.frame((mat_new))
fwrite(mat_new, file="mat_new.csv")
#library(ranger)
set.seed(12345)
training<- sample(nrow(mat_new), nrow(mat_new)*0.7)
train<-mat_new[training,]
test<-mat_new[-training,]
train_control <- trainControl(method="repeatedcv", number=10, repeats=3, savePredictions = TRUE)

train <- as.data.frame(train)
model1 <-train(positive~., family = "binomial", data=train, trControl=train_control, method="glm", 
               tuneLength = 5)

summary(model1)
prediction1 <-predict(model1, newdata=test)
prediction1 <-ifelse(prediction1>0.5,1,0)
table(test$positive, as.factor(prediction1),dnn=c("Actual", "Predicted"))
sum((as.matrix(prediction1)==test$positive))/nrow(test)


#LASSO model
library(glmnet)
LASSO <- glmnet(as.matrix(train[,c(1:64)]),as.matrix(train$positive), alpha=1)
LASSO.cv <- cv.glmnet(as.matrix(train[,c(1:64)]),as.matrix(train$positive), alpha=1)
best.lamda=LASSO.cv$lambda.min
best.lamda
predict(LASSO, s=best.lamda, type="coefficients")


#model improvement
#delete non significant variables
indexRemove<-which(names(train)%in%c("care", "done","see","can", "cleaning", "work", "got", "know", "like", "made", "make",
                                     "need", "patient", "first", "teeth"))
train_new <- train[,-indexRemove]
test_new <- test[,-indexRemove]
model2 <-train(positive~., family = "binomial", data=train_new, trControl=train_control, method="glm", 
               tuneLength = 5)

summary(model2)
prediction1 <-predict(model1, newdata=test)
prediction1 <-ifelse(prediction1>0.5,1,0)
table(test$positive, as.factor(prediction1),dnn=c("Actual", "Predicted"))
sum((as.matrix(prediction1)==test$positive))/nrow(test)



#baseline
sum(test$positive==1)/nrow(test)



#Random Forest
library(ranger)
RF <- ranger(positive~., data=train, mtry=4, num.trees =1000, importance = 'impurity')
test <- as.data.frame(test)
prediction2 <- predict(RF, data=test)
prediction2 <-predictions(prediction2)
prediction2 <- ifelse(prediction2>0.5,1,0)
table(test$positive, as.factor(prediction2),dnn=c("Actual", "Predicted"))
sum((as.matrix(prediction2)==test$positive))/nrow(test)

#baseline
sum(test$positive==1)/nrow(test)



##sentiment analysis
#define function
#Scores=Numbers of positive words-Number of negative words
#If Score >0, means that text has 'positive sentiment'
#If Score <0. menas that the text has 'negative sentiment'
#If Score=0, means that the text has 'neutral sentiment'

#importing Files
posText <- fread("positive-words.csv", header=FALSE, stringsAsFactors=FALSE)
posText <- posText$V1
posText <- unlist(lapply(posText, function(x) { str_split(x, "\n") }))
negText <- read.delim("negative-words.csv", header=FALSE, stringsAsFactors=FALSE)
negText <- negText$V1
negText <- unlist(lapply(negText, function(x) { str_split(x, "\n") }))
pos.words = c(posText, 'upgrade')
neg.words = c(negText, 'with', 'wait', 'waiting','epicfail', 'mechanical')



#define a function
score.sentiment = function(sentences, pos.words, neg.words, .progress='none')
{
  # Parameters
  # sentences: vector of text to score
  # pos.words: vector of words of positive sentiment
  # neg.words: vector of words of negative sentiment
  # .progress: passed to laply() to control of progress bar
  # create a simple array of scores wif laply
  scores = laply(sentences,
                 function(sentence, pos.words, neg.words)
                 {
                   # remove punctuation
                   sentence = gsub("[[:punct:]]", "", sentence)
                   # remove control characters
                   sentence = gsub("[[:cntrl:]]", "", sentence)
                   # remove digits?
                   sentence = gsub('\\d+', '', sentence)
                   # define error handling function when trying tolower
                   tryTolower = function(x)
                   {
                     # create missing value
                     y = NA
                     # tryCatch error
                     try_error = tryCatch(tolower(x), error=function(e) e)
                     # if not an error
                     if (!inherits(try_error, "error"))
                       y = tolower(x)
                     # result
                     return(y)
                   }
                   # use tryTolower wif sapply 
                   sentence = sapply(sentence, tryTolower)
                   # split sentence into words wif str_split (stringr package)
                   word.list = str_split(sentence, "\\s+")
                   words = unlist(word.list)
                   # compare words to teh dictionaries of positive & negative terms
                   pos.matches = match(words, pos.words)
                   neg.matches = match(words, neg.words)
                   # get teh position of teh matched term or NA
                   # we just want a TRUE/FALSE
                   pos.matches = !is.na(pos.matches)
                   neg.matches = !is.na(neg.matches)
                   # final score
                   score = sum(pos.matches) - sum(neg.matches)
                   return(score)
                 }, pos.words, neg.words, .progress=.progress )
  # data frame wif scores for each sentence
  scores.df = data.frame(text=sentences, score=scores)
  return(scores.df)
}
  
scores= score.sentiment((dentist$text), pos.words, neg.words, .progress= 'text')
scores <- as.data.table(scores)
setkey(scores, text)
setkey(dentist, text)
dentist_sentiment <- merge(scores, dentist, by="text")

#seperate the sentiment
dentist_sentiment$polarity <- ifelse(dentist_sentiment$score>0,"positive", 
                                             ifelse(dentist_sentiment$score<0, "negative", ifelse(dentist_sentiment$score==0,
                                                                                                                      "neutral",0)))
#plot the sentiment by polarity
ggplot(data=dentist_sentiment, aes(x=factor(polarity),fill=factor(polarity)))+
  geom_bar() +  geom_text(stat='count', aes(label=..count..), vjust=-1)+ggtitle("Customer Sentiments - Dentist")

fwrite(dentist_sentiment, file="dentist_sentiment.csv")


dentist_repeat <- dentist[duplicated(dentist$text)]  
dentist_new <- merge(dentist_repeat, dentist, by="text")


review <- fread("review_sample.txt", header = TRUE, stringsAsFactors = TRUE)
b <- fread("b.txt", header = TRUE, stringsAsFactors = TRUE)

merge <- merge(x=review, y=b, by="business_id")

fwrite(review, file="review.txt")
txt <- fread("sample.txt", header=TRUE, stringsAsFactors = TRUE)


review_sample_notext <- fread("review_sample.csv", sep=",", header = TRUE, stringsAsFactors = TRUE)
review_sample_notext<-review_sample_notext[,-7]
fwrite(review_sample_notext, file = "review_sample_notext.txt")


library(stringr)
yelp$text<-str_replace_all(yelp$text, "[\r\n]" , "")
write.csv(sample,file = "/Users/zhou/Desktop/bigdata/sample_no_break.csv", row.names = FALSE)

