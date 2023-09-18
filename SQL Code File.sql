/* 

----------Q.1----------

Year	Week Day	Monday	Tuesday	Wednesday Thursday Friday Saturday Sunday
2006	Total Sales						  8164751  6749180	
2007	Total Sales	6639424	5590523		  6379290	  9967385  10042829
2008	Total Sales				  5814991

*/

USE AdventureWorks2008R2;

SELECT datepart(yy, OrderDate) YEAR,
       datepart(dw, OrderDate) AS WeekDay,
       CAST(sum(TotalDue) AS int) AS TotalSales
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) BETWEEN 2006 AND 2008
GROUP BY datepart(dw, OrderDate),  datepart(yy, OrderDate)
HAVING sum(TotalDue) > 5500000

SELECT YEAR,'Total Sales', ISNULL([1], ' ') AS 'Monday' ,
			   ISNULL([2], ' ') AS 'Tuesday',
			   ISNULL([3], ' ') AS 'Wednesday',
			   ISNULL([4], ' ') AS 'Thursday',
			   ISNULL([5], ' ') AS 'Friday',
			   ISNULL([6], ' ') AS 'Saturday',
			   ISNULL([7], ' ') AS 'Sunday'
FROM
	(SELECT datepart(yy, OrderDate) YEAR,
	        datepart(dw, OrderDate) AS WeekDay,
	        CAST(sum(TotalDue) AS int) AS TotalSales
	FROM Sales.SalesOrderHeader
	WHERE YEAR(OrderDate) BETWEEN 2006 AND 2008
	GROUP BY datepart(dw, OrderDate),  datepart(yy, OrderDate)
	HAVING sum(TotalDue) > 5500000
	) AS SourceTable
PIVOT
(
	SUM(TotalSales)
	FOR WeekDay
	IN ([1], [2], [3], [4], [5], [6], [7])

) AS PivotTable
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


	
/*

----------Q.2----------

Using AdventureWorks2008R2, write a query to retrieve 
the order years and their order info.

Return the year, a year's total sales, the top 3 
order values of a year, and the total of the top 3 
order values as a percentage of a year's total sales.

The top 3 order values are the 3 highest order values. 
Use TotalDue in SalesOrderHeader as the order value. 
Please keep in mind it's the order value and several orders 
may have the same value. 

Return only the top 2 years. The top 2 years have the 2 highest
total sales. If there is a tie, the tie needs to be retrieved.

Sort the returned data by year. Return the data in
the format specified below.
*/

/*
Year	TotalSales	Top 3 Order Values			Percentage
2006	34463848	170512.67, 166537.08, 165028.75		1.45
2007	47171490	187487.83, 182018.63, 145454.37		1.09
*/

USE AdventureWorks2008R2;

WITH TEMP AS
(
SELECT 
	YEAR(soh.OrderDate) YEAR,
	ProductID,
	SOH.TotalDue AS 'TTQ',
	DENSE_RANK() OVER (Partition BY YEAR(soh.OrderDate) ORDER BY SOH.TotalDue DESC) AS 'Rank'
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH
	ON SOD.SalesOrderID=SOH.SalesOrderID
GROUP BY YEAR(soh.OrderDate), SOD.ProductID, SOH.TotalDue
)
SELECT 
	TEMP.YEAR,
	TTQ1 AS [TotSales],
	(( CAST(SUM(TTQ) AS FLOAT)  / CAST(TTQ1 AS FLOAT) ) * 100 ) AS 'Percentage',
	STUFF(
		(
		SELECT TOP 3  ', '+RTRIM(CAST(SOH.TotalDue AS char))  
		FROM Sales.SalesOrderDetail SOD 
		JOIN Sales.SalesOrderHeader SOH
			ON SOD.SalesOrderID=SOH.SalesOrderID
		WHERE YEAR(soh.OrderDate) = TEMP.YEAR
		GROUP BY SOH.TotalDue
		ORDER BY  SOH.TotalDue  DESC
		FOR XML PATH('')
		) , 1, 1, ''
	     ) AS 'Top3Order Values'
FROM TEMP 
JOIN 
(SELECT YEAR(soh.OrderDate) YEAR, SUM(SOH.TotalDue) AS 'TTQ1'
 FROM Sales.SalesOrderHeader SOH
GROUP BY YEAR(soh.OrderDate)) B
ON TEMP.YEAR =B.YEAR 
WHERE TEMP.Rank <=3
GROUP BY TEMP.YEAR,B.TTQ1 
ORDER BY TEMP.YEAR;
