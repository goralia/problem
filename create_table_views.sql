CREATE TABLE september(
    click_date DATE,
    campaign INTEGER,
    adgroup INTEGER,
    keyword INTEGER,
    grouping1 INTEGER,
    grouping2 INTEGER,
    cost NUMERIC,
    conversions SMALLINT,    
    PRIMARY KEY (click_date, campaign, adgroup, keyword)
);

\copy september(click_date, campaign, adgroup, keyword, grouping1, grouping2, cost, conversions) FROM 'C:\users\shawn\documents\scripts\problem\problem.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

--we CREATE our bASe table for the september click data on the account
--now we CREATE the views that I will use to manipulate data for different purposes

--first we will CREATE a VIEW giving a list of campaigns and how many times they were used
CREATE VIEW campaigns AS
SELECT 
	campaign, 
	COUNT(*) AS campaign_count, 
	SUM(cost) AS tot_cost, 
	SUM(conversions) AS tot_conversions
FROM september 
GROUP BY campaign 
ORDER BY campaign_count;

--realizing I need one that hAS a column for cpa
CREATE VIEW campaigns_cpa AS	
SELECT *, 
	CASE 
		WHEN tot_conversions > 0 
			THEN tot_cost/tot_conversions 
		WHEN tot_conversions = 0 
			THEN 0 
	END 
	AS cpa 
FROM campaigns;

--a seperate VIEW with campaigns that have more than 0 conversions
CREATE VIEW campaigns_conv AS
	SELECT *, t.cost_sum/t.conv_sum AS cpa
	FROM 
		(SELECT 
			campaign, 
			COUNT(*) AS camp_count, 
			SUM(cost) AS cost_sum, 
			SUM(conversions) AS conv_sum
		FROM september 
		WHERE conversions > 0
		GROUP BY campaign) 
	AS t;

--I realized I wanted a more focused look at the conversions 
--I bASically wanted to know how many conversions I would lose if I wanted to eliminate a certain subset of campaigns that had a high cpa
--for example, WHEN looking at this VIEW, I can see with 15 conversions, there is a cpa of 391.74.
--in the table I have the times column to see how many campaigns would be sharing the amount of total conversions, for the example, there is only 1 campaign that I would eliminate, 565628480
--this campaign hAS a cpa of 391, which seems highly inefficient, eliminating that would help the overall cpa of the account
--another example, we go to the set of conversions that have an average cpa of 229.55 between each other.
--there are 2 campaigns here that share a total amount of conversions of 10.
--Eliminating this row would result in the loss of 20 conversions, but the cost of 4591 would be removed FROM the total, and the cpa of 229 AS well, improving our overall cpa
--this obviously depends on how valuable conversions are compared to cost
--comparing to an industry standard, our overall cpa is pretty bad, sacrificing some conversions would improve the cpa, resulting in a reduction in cost
CREATE VIEW conversions_cpa AS
SELECT 
	tot_conversions, 
	CAST ((SUM(tot_conversions) * 1.0 / tot_conversions) AS FLOAT) AS times,
	SUM(tot_conversions) AS conversions,
	SUM(tot_cost) AS cost,
	AVG(cpa) AS cpa
FROM campaigns_cpa 
WHERE tot_conversions > 0 
GROUP BY tot_conversions
ORDER BY cpa DESC;