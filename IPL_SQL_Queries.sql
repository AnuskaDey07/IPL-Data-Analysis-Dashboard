-- Create Database
CREATE DATABASE IPL_DB;

-- Use Database
USE DATABASE IPL_DB;

-- Create Schema
CREATE SCHEMA IPL_SCHEMA;

-- Use Schema
USE SCHEMA IPL_SCHEMA;

-- Create Warehouse
CREATE WAREHOUSE IPL_WH
WITH WAREHOUSE_SIZE='XSMALL'
AUTO_SUSPEND=60;

-- Use Warehouse
USE WAREHOUSE IPL_WH;

-- Create CSV File Format
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE = CSV
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY='"';

-- Create Stage to Connect Snowflake with AWS S3
CREATE OR REPLACE STAGE IPL_STAGE
URL='s3://ipl-analytics-project-data'
CREDENTIALS=(
    AWS_KEY_ID='YOUR_ACCESS_KEY',
    AWS_SECRET_KEY='YOUR_SECRET_KEY'
)
FILE_FORMAT = CSV_FORMAT;

-- Automatically Create Table from IPL.csv Structure
CREATE OR REPLACE TABLE IPL_DATA
USING TEMPLATE (
SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
FROM TABLE(
INFER_SCHEMA(
LOCATION=>'@IPL_STAGE',
FILES=>('IPL.csv'),
FILE_FORMAT=>'CSV_FORMAT'
)
)
);

-- Load Data from S3 into Snowflake Table
COPY INTO IPL_DATA
FROM @IPL_STAGE/IPL.csv
FILE_FORMAT = (FORMAT_NAME='CSV_FORMAT');

-- Verify Loaded Data
SELECT * FROM IPL_DATA LIMIT 10;
SHOW COLUMNS IN TABLE IPL_DATA;

SELECT DISTINCT
"c44" AS season

FROM IPL_DATA

ORDER BY season;

SELECT

"c44" AS season,

COUNT(DISTINCT "c2")
AS total_matches

FROM IPL_DATA

GROUP BY "c44";

SELECT

"c44" AS season,

COUNT(*)
AS total_sixes

FROM IPL_DATA

WHERE "c14"=6

GROUP BY "c44";


SELECT *

FROM(

SELECT

"c44" season,

"c12" batter,

SUM("c14")
AS runs,

ROW_NUMBER()

OVER(
PARTITION BY "c44"
ORDER BY SUM("c14") DESC
)

rn

FROM IPL_DATA

GROUP BY "c44","c12"

)

WHERE rn=1;



SELECT *

FROM (

SELECT

"c44" AS season,

"c16" AS bowler,

SUM("c62") AS wickets,

ROW_NUMBER()

OVER(
PARTITION BY "c44"
ORDER BY SUM("c62") DESC
)

AS rn

FROM IPL_DATA

GROUP BY
"c44","c16"

)

WHERE rn = 1;

SELECT

"c44" AS season,

COUNT(DISTINCT "c7")
AS total_teams

FROM IPL_DATA

GROUP BY "c44";

SELECT

"c44" AS season,

COUNT(*)
AS total_fours

FROM IPL_DATA

WHERE "c14"=4

GROUP BY "c44";

WITH player_runs AS(

SELECT

"c44" season,

"c2" matchid,

"c12" batter,

SUM("c14") runs

FROM IPL_DATA

GROUP BY
"c44","c2","c12"

)

SELECT

season,

COUNT(*)
AS half_centuries

FROM player_runs

WHERE runs BETWEEN 50 AND 99

GROUP BY season;

WITH player_runs AS(

SELECT

"c44" season,

"c2" matchid,

"c12" batter,

SUM("c14") runs

FROM IPL_DATA

GROUP BY
"c44","c2","c12"

)

SELECT

season,

COUNT(*)
AS centuries

FROM player_runs

WHERE runs>=100

GROUP BY season;


SELECT *

FROM(

SELECT

"c44" season,

"c12" batter,

COUNT(*) fours,

ROW_NUMBER()

OVER(
PARTITION BY "c44"
ORDER BY COUNT(*) DESC
)

rn

FROM IPL_DATA

WHERE "c14"=4

GROUP BY
"c44","c12"

)

WHERE rn=1;



SELECT *

FROM(

SELECT

"c44" season,

"c12" batter,

COUNT(*) sixes,

ROW_NUMBER()

OVER(
PARTITION BY "c44"
ORDER BY COUNT(*) DESC
)

rn

FROM IPL_DATA

WHERE "c14"=6

GROUP BY
"c44","c12"

)

WHERE rn=1;


SELECT

"c44" season,

"c7" team,

COUNT(DISTINCT "c2")
AS played,

SUM(
CASE

WHEN "c35"="c7"

THEN 1

ELSE 0

END

)

AS won,

SUM(
CASE

WHEN "c35"="c7"

THEN 2

ELSE 0

END

)

AS points

FROM IPL_DATA

GROUP BY
"c44","c7"

ORDER BY
season,
points DESC;

SELECT DISTINCT "c53" FROM IPL_DATA;
 SELECT

"c44" AS season,

"c35" AS champion

FROM IPL_DATA

WHERE "c53"='Final'

GROUP BY
"c44",
"c35"

ORDER BY season;

SELECT

"c44" AS season,

CASE

WHEN "c35"="c7"

THEN "c8"

ELSE "c7"

END

AS runnerup

FROM IPL_DATA

WHERE "c53"='Final'

GROUP BY
"c44",
"c35",
"c7",
"c8"

ORDER BY season;

SELECT

"c44" AS season,

COUNT(DISTINCT "c39")
AS total_venues

FROM IPL_DATA

GROUP BY "c44";

SELECT

"c44" AS season,

COUNT(DISTINCT "c7")
AS total_teams

FROM IPL_DATA

GROUP BY "c44";


WITH team_matches AS (

SELECT DISTINCT

"c44" AS season,
"c2" AS match_id,
"c7" AS team,
"c35" AS winner

FROM IPL_DATA

UNION

SELECT DISTINCT

"c44" AS season,
"c2" AS match_id,
"c8" AS team,
"c35" AS winner

FROM IPL_DATA

)

SELECT

season,

team,

COUNT(DISTINCT match_id) AS played,

SUM(
CASE
WHEN team = winner
THEN 1
ELSE 0
END
) AS won,

COUNT(DISTINCT match_id)

-

SUM(
CASE
WHEN team = winner
THEN 1
ELSE 0
END
) AS lost,

SUM(
CASE
WHEN team = winner
THEN 2
ELSE 0
END
) AS points

FROM team_matches

GROUP BY
season,
team

ORDER BY
season,
points DESC,
won DESC;