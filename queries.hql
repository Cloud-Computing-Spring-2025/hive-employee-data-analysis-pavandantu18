#query 1
```
SELECT * 
FROM employees_partitioned
WHERE join_date > '2015-12-31';
```

#query 2 
```
SELECT department, AVG(salary) AS avg_salary
FROM employees_partitioned
GROUP BY department;
```

#query 3 
```
SELECT * 
FROM employees_partitioned
WHERE project = 'Alpha';
```

#query 4
```
SELECT job_role, COUNT(*) AS num_employees
FROM employees_partitioned
GROUP BY job_role;
```

#query 5
```
SELECT e.*
FROM employees_partitioned e
JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees_partitioned
    GROUP BY department
) dept_avg ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_salary;
```

#query 6
```
SELECT department, COUNT(*) as emp_count
FROM employees_partitioned
GROUP BY department
ORDER BY emp_count DESC
LIMIT 1;
```

#query 7
```
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
```

#query 8
```
SELECT e.*, d.location
FROM employees_partitioned e
INNER JOIN departments_temp d
ON e.department = d.department_name;
```

#query 9 
```
SELECT emp_id, name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees_partitioned;
```

#query 10
```
SELECT emp_id, name, department, salary
FROM (
    SELECT emp_id, name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
    FROM employees_partitioned
) ranked
WHERE rank <= 3;
```