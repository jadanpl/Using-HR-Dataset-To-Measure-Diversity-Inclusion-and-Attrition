USE hr_dataset;
SELECT COUNT(*) FROM hr_dataset; --total 311 employees

SELECT DISTINCT Department FROM hr_dataset; -- 6 distinct departments in the dataset

-- number of current emplyees by marital status, gender, and department (top 10)
SELECT MaritalDesc, Sex, Department, COUNT(*) AS num_of_emp
FROM hr_dataset
WHERE Termd =0
GROUP BY MaritalDesc, Sex, Department
ORDER BY num_of_emp DESC
LIMIT 10;

-- Q U E R Y 1
CREATE VIEW eng_hr_dataset AS
SELECT emp_name, Salary, Termd, Position, 
	CASE
		WHEN Position LIKE "%Manager%" THEN "Manager"
		WHEN (position LIKE "%Director%") OR (position LIKE "%CEO%") OR (position LIKE "%CIO%") THEN "Top Management"
		WHEN (Position LIKE "%Senior%") OR (Position LIKE "%Sr%") THEN "Senior Executive"
		ELSE "Executive"
			END AS "Level",
	State, DOB, 
	round((DATEDIFF(STR_TO_DATE("01/01/2019","%m/%d/%Y"),STR_TO_DATE(DOB,"%m/%d/%Y"))/365),0) AS age, 
	CASE
		WHEN YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))>=1946 AND YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))<=1964 THEN "Boomers"
		WHEN YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))>=1965 AND YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))<=1980 THEN "Gen X"
		WHEN YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))>=1981 AND YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))<=1996 THEN "Gen Y"
		WHEN YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))>=1997 AND YEAR(STR_TO_DATE(DOB,"%m/%d/%Y"))<=2012 THEN "Gen Z"
		ELSE "Alpha"
			END AS generation, # DOB <--> age // generational diversity
	Sex, MaritalDesc, CitizenDesc, RaceDesc, DateofHire, DateofTermination, 
	CASE
		WHEN DateofTermination NOT LIKE "%NA%" THEN ROUND(DATEDIFF(STR_TO_DATE(DateofTermination,'%m/%d/%Y'), STR_TO_DATE(DateofHire,'%m/%d/%Y'))/365,2)
		WHEN DateofTermination LIKE "%NA%" THEN ROUND(DATEDIFF(STR_TO_DATE("4/21/2021","%m/%d/%Y"), STR_TO_DATE(DateofHire, '%m/%d/%Y'))/365,2)
			END AS serv_period,
	TermReason, EmploymentStatus, Department, ManagerName, RecruitmentSource,
	PerformanceScore, EngagementSurvey, EmpSatisfaction, SpecialProjectsCount, 
	LastPerformanceReview_Date, DaysLateLast30, Absences
FROM hr_dataset;

SELECT * FROM eng_hr_dataset;
DESCRIBE eng_hr_dataset; # to examine the columns of the view eng_hr_dataset

-- trimmed average service period of the employees by gender and generations
SELECT 
    generation,
    Sex,
    COUNT(*) AS num_of_emp,
    ROUND(((SUM(serv_period) - MIN(serv_period) - MAX(serv_period)) / (COUNT(*) - 2)),2) AS avg_serv_period
FROM eng_hr_dataset
GROUP BY generation, Sex
ORDER BY generation, avg_serv_period DESC;

-- current diversity profile of the organization
SELECT Sex, Generation, RaceDesc, `Level`, COUNT(*) AS num_of_employees
FROM eng_hr_dataset
WHERE Termd=0
GROUP BY Sex, Generation, RaceDesc, `Level`
ORDER BY num_of_employees DESC;	

-- number of current (not resigned or teminated) employees in each department
-- option 1
SELECT SUM(CASE WHEN Department LIKE 'Production%' THEN 1 ELSE 0 END) AS `Production`,
	   SUM(CASE WHEN Department LIKE 'IT%' THEN 1 ELSE 0 END) `IT/IS`,
       SUM(CASE WHEN Department LIKE 'Software%' THEN 1 ELSE 0 END) AS `Software Engineering`,
       SUM(CASE WHEN Department LIKE 'Admin%' THEN 1 ELSE 0 END) AS `Admin Office`,
       SUM(CASE WHEN Department LIKE 'Sales%' THEN 1 ELSE 0 END) AS `Sales`,
       SUM(CASE WHEN Department LIKE 'Executive%' THEN 1 ELSE 0 END) AS `Executive Office` 
FROM hr_dataset
WHERE Termd =0;

-- option 2
SELECT MAX(CASE WHEN Department LIKE 'Production%' THEN num_of_emp ELSE 0 END) AS `Production`,
	   MAX(CASE WHEN Department LIKE 'IT%' THEN num_of_emp ELSE 0 END) `IT/IS`,
       MAX(CASE WHEN Department LIKE 'Software%' THEN num_of_emp ELSE 0 END) AS `Software Engineering`,
       MAX(CASE WHEN Department LIKE 'Admin%' THEN num_of_emp ELSE 0 END) AS `Admin Office`,
       MAX(CASE WHEN Department LIKE 'Sales%' THEN num_of_emp ELSE 0 END) AS `Sales`,
       MAX(CASE WHEN Department LIKE 'Executive%' THEN num_of_emp ELSE 0 END) AS `Executive Office`
FROM (
	SELECT Department, Count(*) as num_of_emp
    FROM hr_dataset
    WHERE Termd =0
    GROUP BY Department)emp_dpt;

-- number and running total of current (not resigned or teminated) employees by gender and department
SELECT Department, Sex, 
	   COUNT(*) AS num_of_emp, 
	   SUM(COUNT(*)) OVER(ORDER BY Department, Sex) AS running_total
FROM hr_dataset
WHERE Termd =0
GROUP BY Department, Sex;

-- Q U E R Y 2
-- number of current (not resigned or teminated) employees by gender and department; use pivoting 
SELECT 
	Sex, SUM(Production) AS `Production`, SUM(`IT/IS`) AS `IT/IS`, 
    SUM(`Software Engineering`) AS `Software Engineering`, 
    SUM(`Admin Office`) AS `Admin`, SUM(Sales) AS `Sales`, 
    SUM(`Executive Office`) AS `Executive Office`, SUM(Total) AS `Total`
FROM(
	SELECT sd.Sex, sd.Production, sd.`IT/IS`, sd.`Software Engineering`, sd.`Admin Office`, sd.Sales, sd.`Executive Office`, ns.Total
	FROM(
		SELECT Sex, 
			   MAX(CASE WHEN Department LIKE 'Production%' THEN num_of_emp ELSE 0 END) AS `Production`,
			   MAX(CASE WHEN Department LIKE 'IT%' THEN num_of_emp ELSE 0 END) AS `IT/IS`,
			   MAX(CASE WHEN Department LIKE 'Software%' THEN num_of_emp ELSE 0 END) AS `Software Engineering`,
			   MAX(CASE WHEN Department LIKE 'Admin%' THEN num_of_emp ELSE 0 END) AS `Admin Office`,
			   MAX(CASE WHEN Department LIKE 'Sales%' THEN num_of_emp ELSE 0 END) AS `Sales`,
			   MAX(CASE WHEN Department LIKE 'Executive%' THEN num_of_emp ELSE 0 END) AS `Executive Office`
		FROM (
			SELECT Department, Sex, COUNT(*) AS num_of_emp
			FROM hr_dataset
			WHERE Termd =0
			GROUP BY Department, Sex)ds
		GROUP BY Sex)sd
	INNER JOIN (
		SELECT Sex, COUNT(*) AS Total
		FROM hr_dataset
		WHERE Termd =0
		GROUP BY Sex)ns
	ON sd.Sex=ns.Sex)dns
GROUP BY Sex WITH ROLLUP;


-- Q U E R Y 3
-- original number of employees, number of current employees and percentage of changes in the number of employees 
-- by job levels and genders
SELECT a.`Level`, a.Sex, original_total_emp, current_emp, 
	CASE 
		WHEN original_total_emp != current_emp THEN ROUND((current_emp-original_total_emp)/original_total_emp*100,2) 
		ELSE "No Changes"
			END AS pct_of_chg
FROM(
	SELECT Department,`Level`,Sex, COUNT(*) AS original_total_emp
	FROM eng_hr_dataset
	GROUP BY `Level`,Sex)c
INNER JOIN(
	SELECT Department, `Level`,Sex, COUNT(*) AS current_emp
	FROM eng_hr_dataset
    	WHERE termd=0
	GROUP BY `Level`,Sex)a
ON (a.`Level`=c.`Level`) AND (a.Sex=c.Sex)
ORDER BY `Level`, pct_of_chg DESC;

-- Q U E R Y 4
-- number of current employees and number of resigned or terminated employees, as well as their respective turnover rate 
-- by departments, job levels, genders, and races
SELECT *
FROM(
	SELECT c.Department, c.`Level`, c.Sex, c.RaceDesc, original_total_emp, stayed_emp, left_emp, ROUND((left_emp/((original_total_emp+stayed_emp)/2))*100,2) AS turnover_rate
	FROM(
		SELECT Department,`Level`,Sex, RaceDesc, COUNT(*) AS original_total_emp
		FROM eng_hr_dataset
        GROUP BY Department, `Level`,Sex, RaceDesc)c
	LEFT JOIN(
		SELECT Department, `Level`,Sex, RaceDesc, COUNT(*) AS stayed_emp
		FROM eng_hr_dataset
		WHERE termd=0
		GROUP BY Department, `Level`,Sex, RaceDesc)a
	ON (a.Department=c.Department) AND (a.`Level`=c.`Level`) AND (a.Sex=c.Sex) AND (a.RaceDesc=c.RaceDesc)
	LEFT JOIN(
		SELECT Department, `Level`,Sex, RaceDesc, COUNT(*) AS left_emp
		FROM eng_hr_dataset
		WHERE (termd=1)
		GROUP BY Department, `Level`,Sex, RaceDesc)b
	ON (c.Department=b.Department) AND (c.`Level`=b.`Level`) AND (c.Sex=b.Sex) AND (c.RaceDesc=b.RaceDesc))dpt_level_gender
WHERE left_emp IS NOT NULL
ORDER BY Sex, turnover_rate DESC;

-- male Asian resigned Production manager
-- male Black or African American Software Engineering executive
SELECT emp_name, Sex, RaceDesc, Department, `Level`, PerformanceScore, Termd, TermReason, EmploymentStatus
FROM eng_hr_dataset
WHERE ((Termd=1) AND (`Level` LIKE "Manager") AND (Department LIKE "Production%") AND (RaceDesc LIKE "Asian%") AND (Sex LIKE "%M%")) OR 
	  ((Termd=1) AND (`Level` LIKE "Executive") AND (Department LIKE "Software Engineering%") AND (RaceDesc LIKE "Black%") AND (Sex LIKE "%M%"));


-- Q U E R Y 5
-- number and running total of terminated employees and their respective termination reasons
SELECT TermReason, EmploymentStatus, COUNT(*) AS num_of_employees, 
	   SUM(COUNT(*)) OVER (ORDER BY TermReason, EmploymentStatus DESC) AS running_total
FROM hr_dataset
WHERE Termd != 0
GROUP BY TermReason, EmploymentStatus;	

-- number of employees who were terminated for cause and their respective department
SELECT TermReason, EmploymentStatus, Department, COUNT(*) AS num_of_employees
FROM hr_dataset
WHERE EmploymentStatus LIKE 'Terminate%'
GROUP BY TermReason, EmploymentStatus, Department
ORDER BY num_of_employees DESC;	

-- Q U E R Y 6
-- the number of employees who resigned due to unhappiness, but they fully met or exceeds their performance assessment criteria
-- and their respective manager 
SELECT Department, ManagerName, COUNT(*) AS num_of_employees
FROM(
	SELECT emp_name, Department, Position, ManagerName
	FROM hr_dataset
	WHERE (TermReason LIKE 'unhappy') AND ((PerformanceScore LIKE 'Fully Meets') OR (PerformanceScore LIKE 'Exceeds')))uh
GROUP BY Department, ManagerName
ORDER BY num_of_employees DESC;	

-- Q U E R Y 7
-- overall turnover rate and turnover rate by gender
-- total number of employees, number of current employees, number of employees who left the company 
-- only consider those who voluntarily resigned and not have attendance / performance (fully met or exceeds their performance assessment criteria) issues
SELECT x.Sex, original_total, stayed_emp, left_emp, ROUND(left_emp/((original_total+stayed_emp)/2)*100,2) AS turnover_rate
FROM (
	SELECT Sex, COUNT(*) AS original_total 
	FROM hr_dataset
	GROUP BY Sex)x
INNER JOIN(
	SELECT Sex, COUNT(*) AS stayed_emp
	FROM hr_dataset
	WHERE Termd=0
	GROUP BY Sex)y
ON (x.Sex=y.Sex)
INNER JOIN(
	SELECT Sex, COUNT(*) AS left_emp
	FROM hr_dataset
    WHERE (EmploymentStatus LIKE "%Voluntarily%") AND (TermReason NOT LIKE "performance") AND (TermReason NOT LIKE "attendance") AND ((PerformanceScore LIKE 'Fully Meets') OR (PerformanceScore LIKE 'Exceeds'))
	GROUP BY Sex)z
ON (x.Sex=z.Sex)
UNION(
	SELECT NULL, original_sum, total_stayed_emp, total_left_emp, ROUND(total_left_emp/((original_sum+total_stayed_emp)/2)*100,2) AS overall_turnover
	FROM (
		SELECT Sex, COUNT(*) AS original_sum 
		FROM hr_dataset)d
	INNER JOIN(
		SELECT Sex, COUNT(*) AS total_stayed_emp
		FROM hr_dataset
		WHERE Termd=0)e
	ON (d.Sex=e.Sex)
	INNER JOIN(
		SELECT Sex, COUNT(*) AS total_left_emp
		FROM hr_dataset
		WHERE (EmploymentStatus LIKE "%Voluntarily%") AND (TermReason NOT LIKE "performance") AND (TermReason NOT LIKE "attendance") AND ((PerformanceScore LIKE 'Fully Meets') OR (PerformanceScore LIKE 'Exceeds')))f
	ON (d.Sex=f.Sex));
    
-- Q U E R Y 8
-- median pay of each gender
SET @row_number:=0; 
SET @median_group:='';

SELECT median_group AS gender, ROUND(AVG(Salary),2) AS median_pay
FROM(
	SELECT 
		@row_number:= CASE # to detect if there has been a change of the groups name and resets the counter accordingly.
			WHEN @median_group = Sex THEN @row_number + 1
			ELSE 1
		END AS count_of_group,
		@median_group:=Sex AS median_group,
		Sex, Salary, (SELECT COUNT(*) FROM eng_hr_dataset WHERE ss.Sex=Sex) AS total_in_group
	FROM(
		SELECT Sex, Salary
		FROM eng_hr_dataset
		ORDER BY Sex, Salary ASC)ss)st
WHERE count_of_group BETWEEN total_in_group / 2.0 AND total_in_group / 2.0 + 1
GROUP BY median_group;

-- Q U E R Y 9
-- the best recruiting platform to use if the company want to ensure diversity
SELECT RecruitmentSource, RaceDesc, COUNT(*) AS num_of_employees
FROM hr_dataset
WHERE (RaceDesc NOT LIKE 'White') AND (Termd=0) AND ((PerformanceScore LIKE "%Exceeds%") OR (PerformanceScore LIKE "%Fully Meets%"))
GROUP BY RecruitmentSource, RaceDesc
ORDER BY RaceDesc, num_of_employees DESC;	


