# Hive Employee and Department Data Analysis

## Project Overview

This project involves analyzing employee and department data using Apache Hive. The dataset consists of employees.csv and departments.csv, which are loaded into Hive tables. The data is then processed and transformed into partitioned ORC tables for efficient querying. Various analytical queries are executed to derive insights, and the results are stored in HDFS.

## Tasks
# Environment Setup
- Start Docker containers:
  ```
  docker compose up -d
  ```
- Access the Hadoop container:
  ```
  docker exec -it resourcemanager /bin/bash
  ```
- Navigate to Hadoop MapReduce directory:
  ```
  cd /opt/hadoop-2.7.4/share/hadoop/mapreduce/
  ```

# HDFS Operations
- Create an HDFS directory for input data:
 ```
  hdfs dfs -mkdir -p /user/hive/warehouse/input_dataset
  ```
- Upload input datasets:
 ```
  hdfs dfs -put employees.csv /user/hive/warehouse/input_dataset/
  hdfs dfs -put departments.csv /user/hive/warehouse/input_dataset/
  ```

# 1. Creating and Loading Hive Tables
- Create temporary tables for raw data:
  ```
  CREATE TABLE employees_temp (
      emp_id INT,
      name STRING,
      age INT,
      job_role STRING,
      salary DOUBLE,
      project STRING,
      join_date STRING,
      department STRING
  )
  ROW FORMAT DELIMITED
  FIELDS TERMINATED BY ','
  STORED AS TEXTFILE;
  
  LOAD DATA INPATH '/user/hive/warehouse/input_dataset/employees.csv'
  INTO TABLE employees_temp;
  ```
  
  ```
  CREATE TABLE departments_temp (
      dept_id INT,
      department_name STRING,
      location STRING
  )
  ROW FORMAT DELIMITED
  FIELDS TERMINATED BY ','
  STORED AS TEXTFILE;
  
  LOAD DATA INPATH '/user/hive/warehouse/input_dataset/departments.csv'
  INTO TABLE departments_temp;
  ```

# 2. Creating Optimized Tables
- Create Partitioned Table and Move Data
```
CREATE TABLE employees (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING
)
STORED AS ORC;

ALTER TABLE employees ADD COLUMNS (department STRING);

CREATE TABLE employees_partitioned (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING
)
PARTITIONED BY (department STRING)
STORED AS ORC;
```

# Inserting Data into Partitioned Table
```
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT INTO TABLE employees_partitioned PARTITION (department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department
FROM employees_temp;
```
# 3. Query Execution
### Query 1: Employees Who Joined After 2015
```
SELECT * FROM employees_partitioned WHERE join_date > '2015-12-31';
```
### Query 2: Average Salary by Department
```
SELECT department, AVG(salary) AS avg_salary FROM employees_partitioned GROUP BY department;
```

### Query 3: Employees Working on the Alpha Project
```
SELECT * FROM employees_partitioned WHERE project = 'Alpha';
```

### Query 4: Employee Count by Job Role
```
SELECT job_role, COUNT(*) AS num_employees FROM employees_partitioned GROUP BY job_role;
```

### Query 5: Employees Earning Above Their Department's Average Salary
```
SELECT e.* FROM employees_partitioned e
JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees_partitioned
    GROUP BY department
) dept_avg ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_salary;
```

### Query 6: Department with the Highest Employee Count
```
SELECT department, COUNT(*) as emp_count FROM employees_partitioned
GROUP BY department ORDER BY emp_count DESC LIMIT 1;
```

### Query 7: Employees with No Null Values
```
SELECT * FROM employees_partitioned
WHERE emp_id IS NOT NULL AND name IS NOT NULL AND age IS NOT NULL 
AND job_role IS NOT NULL AND salary IS NOT NULL AND project IS NOT NULL 
AND join_date IS NOT NULL AND department IS NOT NULL;
```

### Query 8: Employee Details with Department Locations
```
SELECT e.*, d.location FROM employees_partitioned e
INNER JOIN departments_temp d ON e.department = d.department_name;
```

### Query 9: Employee Salary Ranking within Departments
```
SELECT emp_id, name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees_partitioned;
```

### Query 10: Top 3 Highest-Paid Employees by Department
```
SELECT emp_id, name, department, salary FROM (
    SELECT emp_id, name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
    FROM employees_partitioned
) ranked WHERE rank <= 3;
```
## Storing Query Results in HDFS
```
INSERT OVERWRITE DIRECTORY '/user/hive/output/query1' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT * 
FROM employees_partitioned
WHERE join_date > '2015-12-31';

INSERT OVERWRITE DIRECTORY '/user/hive/output/query2' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ','  
SELECT department, AVG(salary) AS avg_salary
FROM employees_partitioned
GROUP BY department;

INSERT OVERWRITE DIRECTORY '/user/hive/output/query3' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT * 
FROM employees_partitioned
WHERE project = 'Alpha';


INSERT OVERWRITE DIRECTORY '/user/hive/output/query4' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT job_role, COUNT(*) AS num_employees
FROM employees_partitioned
GROUP BY job_role;


INSERT OVERWRITE DIRECTORY '/user/hive/output/query5' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT e.*
FROM employees_partitioned e
JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees_partitioned
    GROUP BY department
) dept_avg ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_salary;


INSERT OVERWRITE DIRECTORY '/user/hive/output/query6' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT department, COUNT(*) as emp_count
FROM employees_partitioned
GROUP BY department
ORDER BY emp_count DESC
LIMIT 1;

INSERT OVERWRITE DIRECTORY '/user/hive/output/query7' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT * 
FROM employees_partitioned
WHERE emp_id IS NOT NULL
AND name IS NOT NULL
AND age IS NOT NULL
AND job_role IS NOT NULL
AND salary IS NOT NULL
AND project IS NOT NULL
AND join_date IS NOT NULL
AND department IS NOT NULL;


INSERT OVERWRITE DIRECTORY '/user/hive/output/query8' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT e.*, d.location
FROM employees_partitioned e
INNER JOIN departments_temp d
ON e.department = d.department_name;


INSERT OVERWRITE DIRECTORY '/user/hive/output/query9' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT emp_id, name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees_partitioned;

INSERT OVERWRITE DIRECTORY '/user/hive/output/query10' 
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT emp_id, name, department, salary
FROM (
    SELECT emp_id, name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
    FROM employees_partitioned
) ranked
WHERE rank <= 3;
```
## Retrieving Query Results from HDFS
```
docker exec -it resourcemanager /bin/bash
cd /opt/hadoop-2.7.4/share/hadoop/mapreduce/
hdfs dfs -get /user/hive/output /opt/hadoop-2.7.4/share/hadoop/mapreduce/output
exit
docker cp resourcemanager:/opt/hadoop-2.7.4/share/hadoop/mapreduce/output ./output
```

## Conclusion
This project successfully loads employee data into Hive, transforms and partitions it using `ALTER TABLE`, executes analytical queries, and stores query results in output files for further processing and visualization. The final output files and `.hql` scripts are pushed to GitHub for version control and sharing.

