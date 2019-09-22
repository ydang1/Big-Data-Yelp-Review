# Project Title
This is a 4-persons academic team project which we used big data tools combined with other data analysis tools to manipulate and process the data so that it can be queried when loaded on Big Data infrastructure. The Project Requrements are the following:

- Create scripts of processesing or querying the data on Pig or Hive on Hadoop.
- Understand how to manage the data on a cluster (AWS/cloudera virtual machine)
- Built an analytical prediction model on Spark

## Business Question
1. How many dentist reviews? are those mostly postive or negative and are they growing?

2. Identify the major factors that help customers understand what affects the sentiment of online reviews of dentists.

# Dataset
We choose the 'yelp_academic_dataset_review' which is in json file, it conatains full review text data including the user_id that wrote the review and the business_id that review is written for. we need the information only related to denist review.
In order to get the relative sub dataset, we use another 'yelp_academic_dataset' to help us identify the dentist review by the unique business id. 

- 'yelp_academic_dataset_review' (8GB) (rows: 5996996, columns:9)
- 'yelp_academic_dataset_business' (163MB) (row: 188593, columns:2)

features includes: 'business_id','cool','funny','review_id','starts', 'text', 'date', 'user_id', 'useful' and 'categories'.


# Prerequistes
Tools: 
- Hadoop (Cloudera virtual Machine)
- AWS: https://aws.amazon.com/
- R studio: https://www.rstudio.com/products/rstudio/download/
- Python (Anaconda Environment): https://www.anaconda.com/distribution/
- Tableau: https://www.tableau.com/products/desktop/download

# Running the tests
### 1. Json convert to CSV (local Python)
```
import json
import pandas as pd
from glob import glob

def convert(x):
    ''' Convert a json string to a flat python dictionary
    which can be passed into Pandas. '''
    ob = json.loads(x)
    for k, v in ob.items():
        if isinstance(v, list):
            ob[k] = ','.join(v)
        elif isinstance(v, dict):
            for kk, vv in v.items():
                ob['%s_%s' % (k, kk)] = vv
            del ob[k]
    return ob

for json_filename in glob('yelp_academic_dataset_review.json'):
     csv_filename = '%s.csv' % json_filename[:-5]
    print 'Converting %s to %s' % (json_filename, csv_filename)
    df = pd.DataFrame([convert(line) for line in file(json_filename)])
    df.to_csv(csv_filename, encoding='utf-8', index=False)
```

### 2. Create pig script for data query (running in AWS EMR, store the MapReduce results in AWS S3)
- find_dentist_businessid
```
REGISTER 's3://bigdataprojectzongdi/loudacre/piggybank.jar';

DEFINE CSVLoader org.apache.pig.piggybank.storage.CSVLoader();

business = LOAD 's3://bigdataprojectzongdi/loudacre/bid_categ.csv' USING CSVLoader AS (categories:chararray, business_id:chararray);

a = FILTER business BY (categories MATCHES '.*Dentist.*') OR (categories MATCHES '.*Dental.*') OR (categories MATCHES '.*dentist.*') OR (categories MATCHES '.*dental.*');

b = DISTINCT a;

STORE b INTO 's3://bigdataprojectzongdi/output/bid4dentist';
```
- merge the dentist_buinsessid back to review dataset
```
REGISTER 's3://bigdataprojectzongdi/loudacre/piggybank.jar';

DEFINE CSVLoader org.apache.pig.piggybank.storage.CSVLoader();

dentist = LOAD 's3://bigdataprojectzongdi/output/bid4dentist' AS (categories:chararray, business_id:chararray);

reviewall = LOAD 's3://bigdataprojectzongdi/loudacre/sample_no_break.csv' USING CSVLoader AS (
business_id: chararray,
cool: int,
date: chararray,
funny: int,
review_id: chararray,
stars:int,
text: chararray,
useful: int,
user_id: chararray);

dentistreview = JOIN dentist BY business_id, reviewall BY business_id;
temp = LIMIT dentistreview 5;
DUMP temp;
STORE dentistreview INTO 's3://bigdataprojectzongdi/output/mergesample';
```
- Data exploration and description
```
dentist = LOAD '/Users/zhou/Desktop/bigdata/dentist_review' AS (categories:chararray,
business_id: chararray,
business_idaa: chararray,
cool: int,
date: chararray,
funny: int,
review_id: chararray,
stars:int,
text: chararray,
useful: int,
user_id: chararray);

/* #####total records################################## */

dent_details = GROUP dentist ALL;
dent_total_num = FOREACH dent_details GENERATE COUNT(dentist.review_id);
DUMP dent_total_num;

/* #####stars########################################## */

dentstars = GROUP dentist BY stars;
starnum = FOREACH dentstars GENERATE COUNT(dentist.review_id);
DUMP starnum;

dent_positive = FILTER dentist BY (stars >= 3);
dent_pos_details = GROUP dent_positive ALL;
dent_pos_num = FOREACH dent_pos_details GENERATE COUNT(dent_positive.review_id);
DUMP dent_pos_num;

dent_negative = FILTER dentist BY (stars < 3);
dent_neg_details = GROUP dent_negative ALL;
dent_neg_num = FOREACH dent_neg_details GENERATE COUNT(dent_negative.review_id);
DUMP dent_neg_num;
```
- MapReduce results image:
![](Hadoop%20Pig%20Script%20and%20AWS%20results/AWS%20MapReduce%20Results.png)

Totally data set after joined is 32.8 MB, and we have 44366 dentist reviews, of which 7036 reviews give one star, 1165 reviews
give two stars, 651 reviews give three stars, 1658 reviews give four stars and 33856 reviews give five stars. If we assumed that the positive review are stars(3,4,5), whereas the negatives review are stars(1,2). There are total 36165 positive reviews and 8201 negative reviews.

### 3. Visualize the reviews trends across the time line (Tableau)
![](Hadoop%20Pig%20Script%20and%20AWS%20results/review%20trend.png)
![](Hadoop%20Pig%20Script%20and%20AWS%20results/review%20trend%20positive.png)
![](Hadoop%20Pig%20Script%20and%20AWS%20results/review%20trend%20negative.png)

### 4. Text mining and Sentiment Analysis (Local R)
#### Sentiment Analysis
  1. Use online standard dictionary which contains both positive and negative words
  2. define function
  3. Scores=Numbers of positive words-Number of negative words
  4. If Score >0, means that text has 'positive sentiment'
  5. If Score <0. menas that the text has 'negative sentiment'
  6. If Score=0, means that the text has 'neutral sentiment'
  7. visualize the label results (ggplot)
```
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
```
![](Hadoop%20Pig%20Script%20and%20AWS%20results/sentiment%20label%20results.png)
![](Hadoop%20Pig%20Script%20and%20AWS%20results/sentiment%20by%20attitude.png)
![](Hadoop%20Pig%20Script%20and%20AWS%20results/sentiment%20by%20stars.png)

  ##### Interesting finds:
  1. Star 1 and Star 2 has relatively higher negative reviews, whereas Star 3,4 has relative more positive reviews and Star 5 has a significant positive reviews. It is consistent with our assumption of positive label and negative label.

  2. Customer tends to find negative dentist review are more useful than positive reviews.

  3. Generally, customers do not personal favor too much on the attitude of the dentist reviews.

### Text Mining
  1. removeSparseTerms(10%)
  2. removeStopwords
  3. removeNumbers
  4. stemWords
  5. stripWhitespace
  6. toLowercase
  7. weighting term frequency
  8. Create document term matrix (DTM)
  9. Plot the keywords frequencies 
  
```
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
matrix <- create_matrix(dentist$text, language="english", removeSparseTerms = 0.89, removeStopwords = TRUE,
                        removeNumbers = TRUE, stemWords = TRUE, stripWhitespace = TRUE, toLower = TRUE, weighting = weightTf)
mat <- as.matrix(matrix)
mat <- as.data.table(mat)

term.freq <- rowSums(t(as.matrix(mat)))
df <- data.frame(term=names(term.freq), freq=term.freq)
ggplot(df, aes(x=term, y=freq))+geom_bar(stat="identity")+xlab("Terms")+ylab("Count")
```
![](Hadoop%20Pig%20Script%20and%20AWS%20results/term%20frequencies%20counts.png)

### 5. predictive models (Python written on Spark(pyspark on Cloudera Virtual Machine))
  1. TDM as feature variables, sentiment labels as binary predicted variable
  2. randome split data to training 70% and testing sets 30%
  2. Logistic regression as based model (use cross-validation for model selection)
  3. Random Forest model as challenged model
  4. Model performance
  
![](Hadoop%20Pig%20Script%20and%20AWS%20results/predictive%20Model.png)
![](Hadoop%20Pig%20Script%20and%20AWS%20results/predictive%20model%202.png)

#### results:
- Baseline accuracy: 84.36%
- Logistic regression has out-of-sample accuracy 90.83%
- Random Forest has out-of-sample accuracy 90.10%
- positive correlation with predicted value: {'amazing','best','everyone','comfortable','friendly','great','highly','love','professional'}
- negative correlation with predicted value:
{'ever','insurance','never','just','even','ever','place','went'}

### 6. Data Fraud and Data Integrity
  #### Manually check some outliers (sample)
  ![](Hadoop%20Pig%20Script%20and%20AWS%20results/data%20fraud.png)
  #### potential issues:
  #### one person use different user account give same dentist shop multiple same review contents, and most of those rate starts are 5 star, if the fraud data are large, it will has bias in analysis!!!
  
## Future Improvement
1. After join the data, double check the duplicated review contents and delete the fraud data.
2. Try different way of sentiment labeling such as the probability estimated.
3. Instead of using TDM, consider using term frequency–inverse document frequency(tf-idf) to decreases the importance of the high frequency words.

# Contribution
- Converted json to csv file and support my teammates with pig scrite syntax debug.
- Conducted Text Mining and Sentiment Analysis in R and data visualization in R and Tableau.
- Build predictive model and check model performance and model comparison. 
- Lead my team to practice the presentation, support any technial help if necessary. 


 
  
  









  

















