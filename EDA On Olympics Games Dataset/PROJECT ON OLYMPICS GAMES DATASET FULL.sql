-- 1. How many olympics games have been held?

SELECT COUNT(DISTINCT Games) AS TOTAL_OLYMPICS_GAMES
FROM olympics_history

-- 2. List down all Olympics games held so far.

SELECT 
	Year,
	Season,
    City
FROM olympics_history   

-- 3. Mention the total no of nations who participated in each olympics game?  

SELECT	
	Games,
    COUNT(DISTINCT NOC) AS NO_Of_PARTICIPANTS
FROM olympics_history
GROUP BY Games



-- 4. Which year saw the highest and lowest no of countries participating in olympics 


WITH T1 AS (
  SELECT Games, COUNT(DISTINCT NOC) AS lowest_participation
  FROM olympics_history
  GROUP BY Games
  ORDER BY COUNT(DISTINCT NOC) ASC
  LIMIT 1
),
T2 AS (
  SELECT Games, COUNT(DISTINCT NOC) AS highest_participation
  FROM olympics_history
  GROUP BY Games
  ORDER BY COUNT(DISTINCT NOC) DESC
  LIMIT 1
)
SELECT
  CONCAT(T1.Games, '-', T1.lowest_participation) AS lowest_participation,
  CONCAT(T2.Games, '-', T2.highest_participation) AS highest_participation
FROM T1, T2;

-- 5. Which nation has participated in all of the olympic games 


SELECT 
    COUNT(DISTINCT Games) AS TOTAL_PARTICIPATED_GAMES,
    ohr.region
FROM 
    olympics_history oh
INNER JOIN olympic_history_noc_region ohr ON oh.NOC = ohr.NOC
GROUP BY 
    ohr.region
ORDER BY 
    TOTAL_PARTICIPATED_GAMES DESC;   
    
    
    
-- 6. Identify the sport which was played in all summer olympics.


WITH T1 AS (
  SELECT COUNT(DISTINCT Games) AS TOTAL_GAMES_PLAYED
  FROM olympics_history
  WHERE Season = 'Summer'
),
T2 AS (
  SELECT DISTINCT Sport, COUNT(DISTINCT Games) AS NO_OF_GAMES
  FROM olympics_history
  WHERE Season = 'Summer'
  GROUP BY Sport
)
SELECT *
FROM T2, T1
WHERE T1.TOTAL_GAMES_PLAYED = T2.NO_OF_GAMES;

-- 7. Which Sports were just played only once in the olympics.

SELECT Sport,
       COUNT(DISTINCT Games) AS NO_OF_GAMES,
       GROUP_CONCAT(DISTINCT Games SEPARATOR ', ') AS All_Games
FROM olympics_history
GROUP BY Sport
HAVING COUNT(DISTINCT Games) = 1
ORDER BY NO_OF_GAMES ASC;


-- 8. Fetch the total no of sports played in each olympic games. 

SELECT Games,
	COUNT(DISTINCT Sport) AS NO_OF_SPORTS_PLAYED
FROM olympics_history
GROUP BY Games
ORDER BY NO_OF_SPORTS_PLAYED DESC

-- 9. Fetch 3 oldest athletes to win a gold medal

SELECT *
FROM olympics_history
WHERE Medal = 'Gold' AND age != 'NA'
ORDER BY age DESC
LIMIT 3

-- 10. Find the Ratio of male and female athletes participated in all olympic games.

WITH T1 AS 
	(SELECT COUNT(Sex) AS COUNT_FEMALE
    FROM olympics_history
    WHERE Sex = 'f'),
    T2 AS 
    (SELECT COUNT(Sex) AS COUNT_MALE
    FROM olympics_history
    WHERE Sex = 'm')
SELECT
	CONCAT('1:',(COUNT_MALE / COUNT_FEMALE)) AS RATIO
FROM T2,T1


-- 11. Fetch the top 5 athletes who have won the most gold medals.

SELECT Player,
       COUNT(Medal) AS TOTAL_GOLD_MEDAL,
       Team
FROM olympics_history
WHERE Medal = 'Gold'
GROUP BY Player, Team
ORDER BY TOTAL_GOLD_MEDAL DESC
LIMIT 5;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze). 

SELECT Player,
       COUNT(Medal) AS TOTAL_MEDAL,
       Team
FROM olympics_history
GROUP BY Player, Team
ORDER BY TOTAL_MEDAL DESC
LIMIT 5;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

SELECT
  Team,
  COUNT(Medal) AS TotalMedalWon,
  RANK() OVER (ORDER BY COUNT(Medal) DESC) AS Rank_
FROM olympics_history
WHERE Medal <> 'NA'
GROUP BY Team
ORDER BY Rank_
LIMIT 5;
	

-- 14. List down total gold, silver and bronze medals won by each country.

SELECT
	O2.region AS COUNTRY,
	SUM(CASE WHEN O1.Medal='Gold' THEN 1 ELSE 0 END) AS GOLD,
    SUM(CASE WHEN O1.Medal='Silver' THEN 1 ELSE 0 END) AS Silver,
    SUM(CASE WHEN O1.Medal='Bronze' THEN 1 ELSE 0 END) AS Bronze
FROM olympics_history AS O1
JOIN olympic_history_noc_region AS O2
ON O1.NOC = O2.NOC
GROUP BY COUNTRY
ORDER BY GOLD DESC


-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

SELECT
    O1.Games AS GAMES,  
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal='Gold' THEN 1 ELSE 0 END) AS GOLD,
    SUM(CASE WHEN O1.Medal='Silver' THEN 1 ELSE 0 END) AS Silver,
    SUM(CASE WHEN O1.Medal='Bronze' THEN 1 ELSE 0 END) AS Bronze
FROM olympics_history AS O1
JOIN olympic_history_noc_region AS O2
ON O1.NOC = O2.NOC
GROUP BY O1.Games, COUNTRY
ORDER BY GOLD DESC; 


-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

 WITH T1_GOLD AS (
  SELECT
    O1.Games AS GAMES,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal = 'Gold' THEN 1 ELSE 0 END) AS GOLD,
    DENSE_RANK() OVER (PARTITION BY O1.Games ORDER BY SUM(CASE WHEN O1.Medal = 'Gold' THEN 1 ELSE 0 END) DESC) AS GOLD_RANK
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY O1.Games, O2.region
),
T2_SILVER AS (
  SELECT
    O1.Games AS GAMES,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal = 'Silver' THEN 1 ELSE 0 END) AS SILVER,
    DENSE_RANK() OVER (PARTITION BY O1.Games ORDER BY SUM(CASE WHEN O1.Medal = 'Silver' THEN 1 ELSE 0 END) DESC) AS SILVER_RANK
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY O1.Games, O2.region
),
T3_BRONZE AS (
  SELECT
    O1.Games AS GAMES,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal = 'Bronze' THEN 1 ELSE 0 END) AS BRONZE,
    DENSE_RANK() OVER (PARTITION BY O1.Games ORDER BY SUM(CASE WHEN O1.Medal = 'Bronze' THEN 1 ELSE 0 END) DESC) AS BRONZE_RANK
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY O1.Games, O2.region
)
SELECT
  T1_GOLD.GAMES,
  CONCAT(T1_GOLD.COUNTRY, '-', T1_GOLD.GOLD) AS MAX_GOLD,
  CONCAT(T2_SILVER.COUNTRY, '-', T2_SILVER.SILVER) AS MAX_SILVER,
  CONCAT(T3_BRONZE.COUNTRY, '-', T3_BRONZE.BRONZE) AS MAX_BRONZE
FROM T1_GOLD
JOIN T2_SILVER ON T1_GOLD.GAMES = T2_SILVER.GAMES
JOIN T3_BRONZE ON T1_GOLD.GAMES = T3_BRONZE.GAMES
WHERE T1_GOLD.GOLD_RANK = 1
  AND T2_SILVER.SILVER_RANK = 1
  AND T3_BRONZE.BRONZE_RANK = 1;
  
  
  -- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
  
  WITH T1_GOLD AS (
  SELECT
    O1.Games AS GAMES,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal = 'Gold' THEN 1 ELSE 0 END) AS GOLD,
    DENSE_RANK() OVER (PARTITION BY O1.Games ORDER BY SUM(CASE WHEN O1.Medal = 'Gold' THEN 1 ELSE 0 END) DESC) AS GOLD_RANK
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY O1.Games, O2.region
),
T2_SILVER AS (
  SELECT
    O1.Games AS GAMES,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal = 'Silver' THEN 1 ELSE 0 END) AS SILVER,
    DENSE_RANK() OVER (PARTITION BY O1.Games ORDER BY SUM(CASE WHEN O1.Medal = 'Silver' THEN 1 ELSE 0 END) DESC) AS SILVER_RANK
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY O1.Games, O2.region
),
T3_BRONZE AS (
  SELECT
    O1.Games AS GAMES,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal = 'Bronze' THEN 1 ELSE 0 END) AS BRONZE,
    DENSE_RANK() OVER (PARTITION BY O1.Games ORDER BY SUM(CASE WHEN O1.Medal = 'Bronze' THEN 1 ELSE 0 END) DESC) AS BRONZE_RANK
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY O1.Games, O2.region
),
T4_TOTAL AS (
  SELECT
    O1.Games AS GAMES,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal <> 'NA' THEN 1 ELSE 0 END) AS TOTAL_MEDALS,
    DENSE_RANK() OVER (PARTITION BY O1.Games ORDER BY SUM(CASE WHEN O1.Medal <> 'NA' THEN 1 ELSE 0 END) DESC) AS TOTAL_MEDALS_RANK
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY O1.Games, O2.region
)
SELECT
  T1_GOLD.GAMES,
  CONCAT(T1_GOLD.COUNTRY, '-', T1_GOLD.GOLD) AS MAX_GOLD,
  CONCAT(T2_SILVER.COUNTRY, '-', T2_SILVER.SILVER) AS MAX_SILVER,
  CONCAT(T3_BRONZE.COUNTRY, '-', T3_BRONZE.BRONZE) AS MAX_BRONZE,
  CONCAT(T4_TOTAL.COUNTRY, '-', T4_TOTAL.TOTAL_MEDALS) AS MAX_TOTAL_MEDALS
FROM T1_GOLD
JOIN T2_SILVER ON T1_GOLD.GAMES = T2_SILVER.GAMES AND T1_GOLD.COUNTRY = T2_SILVER.COUNTRY
JOIN T3_BRONZE ON T1_GOLD.GAMES = T3_BRONZE.GAMES AND T1_GOLD.COUNTRY = T3_BRONZE.COUNTRY
JOIN T4_TOTAL ON T1_GOLD.GAMES = T4_TOTAL.GAMES AND T1_GOLD.COUNTRY = T4_TOTAL.COUNTRY
WHERE T1_GOLD.GOLD_RANK = 1
  AND T2_SILVER.SILVER_RANK = 1
  AND T3_BRONZE.BRONZE_RANK = 1
  AND T4_TOTAL.TOTAL_MEDALS_RANK = 1;
  
  
-- 18. Which countries have never won gold medal but have won silver/bronze medals?

WITH MedalCounts AS (
  SELECT
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal = 'Gold' THEN 1 ELSE 0 END) AS GoldCount,
    SUM(CASE WHEN O1.Medal = 'Silver' THEN 1 ELSE 0 END) AS SilverCount,
    SUM(CASE WHEN O1.Medal = 'Bronze' THEN 1 ELSE 0 END) AS BronzeCount
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  GROUP BY COUNTRY
)
SELECT
  COUNTRY,
  GoldCount,
  SilverCount,
  BronzeCount
FROM MedalCounts
WHERE GoldCount = 0
  AND (SilverCount > 0 OR BronzeCount > 0);
  
-- 19. In which Sport/event, India has won highest medals.

WITH MedalCounts AS (
  SELECT
    O1.Sport AS SPORTS,
    O2.region AS COUNTRY,
    SUM(CASE WHEN O1.Medal <> 'NA' THEN 1 ELSE 0 END) AS TOTAL_MEDALS
  FROM olympics_history AS O1
  JOIN olympic_history_noc_region AS O2 ON O1.NOC = O2.NOC
  WHERE O2.region = 'India'
  GROUP BY O1.Sport, O2.region
)
SELECT 
  SPORTS,
  COUNTRY,
  TOTAL_MEDALS
FROM MedalCounts
ORDER BY TOTAL_MEDALS DESC
LIMIT 1;
  
-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

SELECT
  O1.Sport AS Sport,
  O2.region AS Country,
  O1.Games AS Games,
  SUM(CASE WHEN Medal <> 'NA' THEN 1 ELSE 0 END) AS TotalMedals
FROM olympics_history AS O1
JOIN olympic_history_noc_region AS O2
ON O1.NOC = O2.NOC
WHERE O2.region = 'India'
  AND O1.Sport = 'Hockey'
GROUP BY O2.region, O1.Sport, O1.Games
HAVING SUM(CASE WHEN Medal <> 'NA' THEN 1 ELSE 0 END) > 0;

 