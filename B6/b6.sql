-- 1
USE ss14_second;DELIMITER $$

-- 2
CREATE TRIGGER check_phone_length_before_update
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.phone) != 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số điện thoại phải có 10 chữ số';
    END IF;
END $$
DELIMITER ;
-- 3
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);
-- 4
DELIMITER $$
CREATE TRIGGER create_welcome_notification
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO notifications (employee_id, message)
    VALUES (NEW.employee_id, 'Xin chào');
END $$
DELIMITER ;
-- 5
set autocommit = 0;
DELIMITER $$
CREATE PROCEDURE AddNewEmployeeWithPhone(
    emp_name VARCHAR(255),
	emp_email VARCHAR(255),
	emp_phone VARCHAR(20),
	emp_hire_date DATE,
	emp_department_id INT
)
BEGIN
    DECLARE exit handler for sqlexception
  
    START TRANSACTION;
    IF (SELECT COUNT(*) FROM employees WHERE email = emp_email) > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email đã tồn tại';
    END IF;
    IF LENGTH(emp_phone) != 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số điện thoại phải có 10 chữ số';
    END IF;
    INSERT INTO employees (name, email, phone, hire_date, department_id)
		VALUES (emp_name, emp_email, emp_phone, emp_hire_date, emp_department_id);
    INSERT INTO notifications (employee_id, message)
		VALUES (LAST_INSERT_ID(), 'Xin chào');
    COMMIT;
END $$
DELIMITER ;
-- 6
call AddNewEmployeeWithPhone('Nguyen Van A', 'nguyenvana@example.com', '0912345678', '2025-02-19', 1);
select * from employees;
select * from notifications;