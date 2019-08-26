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

