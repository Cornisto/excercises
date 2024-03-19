/*
Exercise 1
*/

WITH RECURSIVE parent AS
(
    SELECT
  	EmployeeId, EmployeeName, EmployeeTitle, EmployeeId as ManagerId, EmployeeName as ManagerName, EmployeeName as DirectorName, 0 as level,
  	CAST(EmployeeName AS VARCHAR) AS PositionBreadcrumbs
    FROM
  	EmployeeList WHERE ManagerId IS NULL
    UNION ALL
    SELECT
  	emp.EmployeeId, emp.EmployeeName, emp.EmployeeTitle, emp.ManagerId, parent.EmployeeName as ManagerName, parent.DirectorName as DirectorName, level+1,
  	CONCAT(parent.PositionBreadcrumbs, ' | ', emp.EmployeeName) AS PositionBreadcrumbs
    FROM
  	EmployeeList emp JOIN parent ON emp.ManagerId = Parent.EmployeeId
)
SELECT
    EmployeeId, EmployeeName, EmployeeTitle, ManagerId, ManagerName, DirectorName, PositionBreadcrumbs
FROM
    parent
ORDER BY EmployeeId;


/*
Exercise 2
*/

SELECT
    CalendarDate,
    Employee,
    Department,
    Salary,
    FIRST_VALUE(Salary) OVER(PARTITION BY Employee ORDER BY CalendarDate) AS FirstSalary,
        LAG(Salary) OVER(PARTITION BY Employee ORDER BY CalendarDate) AS PreviousPeriodSalary,
        LEAD(Salary) OVER(PARTITION BY Employee ORDER BY CalendarDate) AS FollowingPeriodSalary,
        SUM(Salary) OVER(PARTITION BY Department) AS SummarizedSalary,
        SUM(Salary) OVER(PARTITION BY Department ORDER BY CalendarDate rows between unbounded preceding and current row) AS CumulativeDepartmentSalary
FROM
    Salary;


/*
Exercise 3

To implement SCD Type 2, additional column RecordEndDate will be added to the Dimension.Employee table.
New records will have this column set to null, outdated records will have this column set to the date of update.
*/
                                                                                                                                                                                                                              DECLARE @RecordEndDate DATETIME = GETDATE();

INSERT INTO employees (EmployeeId, EmployeeName, EmployeeTitle, ManagerId, SalaryNumber, RecordEndDate)
SELECT EmployeeId, EmployeeName, EmployeeTitle, ManagerId, SalaryNumber, null
FROM
    (
        MERGE INTO Dimension.Employee AS DST
USING Staging.Employee AS SRC
ON (SRC.EmployeeId = DST.EmployeeId)
WHEN NOT MATCHED THEN
INSERT (EmployeeId, EmployeeName, EmployeeTitle, ManagerId, SalaryNumber, RecordEndDate)
VALUES (SRC.EmployeeId, SRC.EmployeeName, SRC.EmployeeTitle, SRC.ManagerId, SRC.SalaryNumber, NULL)
WHEN MATCHED
AND RecordEndDate IS NULL
AND (
    SRC.EmployeeName <> DST.EmployeeName
    OR SRC.EmployeeTitle <> DST.EmployeeTitle
    OR SRC.ManagerId <> DST.ManagerId
)
THEN UPDATE
SET DST.RecordEndDate = @RecordEndDate
OUTPUT SRC.EmployeeId, SRC.EmployeeName, SRC.EmployeeTitle, SRC.ManagerId, inserted.SalaryNumber, $Action AS MergeAction
        ) AS MRG
WHERE MRG.MergeAction = 'UPDATE'
;



-- Sample dataset used to test the solution:

create table Dimension.Employee(
    EmployeeId int,
    EmployeeName varchar(250),
    EmployeeTitle varchar(250),
    ManagerId int,
    SalaryNumber int,
    RecordEndDate DATETIME null
);
create table Staging.Employee(
    EmployeeId int,
    EmployeeName varchar(250),
    EmployeeTitle varchar(250),
    ManagerId int,
    SalaryNumber int
);

insert into Dimension.Employee (EmployeeId,EmployeeName,EmployeeTitle,ManagerId,SalaryNumber)
VALUES
    (1,'John T.','Director of American Office',null,1),
    (2,'George F.','Manager',1,2),
    (3,'Elliot S.','Driver',2,3);

insert into Staging.Employee (EmployeeId,EmployeeName,EmployeeTitle,ManagerId,SalaryNumber)
VALUES
    (100,'Anna K.','Director of European Office',null,4),
    (2,'George F.','Senior Manager',1,2),
    (3,'Elliot X.','SuperDriver',777,999),
    (101,'Troll K.','Stone Manager',22, 5);


