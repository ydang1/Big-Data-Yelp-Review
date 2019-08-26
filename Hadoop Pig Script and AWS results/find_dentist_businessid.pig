REGISTER 's3://bigdataprojectzongdi/loudacre/piggybank.jar';

DEFINE CSVLoader org.apache.pig.piggybank.storage.CSVLoader();

business = LOAD 's3://bigdataprojectzongdi/loudacre/bid_categ.csv' USING CSVLoader AS (categories:chararray, business_id:chararray);

a = FILTER business BY (categories MATCHES '.*Dentist.*') OR (categories MATCHES '.*Dental.*') OR (categories MATCHES '.*dentist.*') OR (categories MATCHES '.*dental.*');

b = DISTINCT a;


STORE b INTO 's3://bigdataprojectzongdi/output/bid4dentist';


