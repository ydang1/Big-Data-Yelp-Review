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

/* #####positive vs negative########################### */

dent_positive = FILTER dentist BY (stars >= 3);
dent_pos_details = GROUP dent_positive ALL;
dent_pos_num = FOREACH dent_pos_details GENERATE COUNT(dent_positive.review_id);
DUMP dent_pos_num;

dent_negative = FILTER dentist BY (stars < 3);
dent_neg_details = GROUP dent_negative ALL;
dent_neg_num = FOREACH dent_neg_details GENERATE COUNT(dent_negative.review_id);
DUMP dent_neg_num;





