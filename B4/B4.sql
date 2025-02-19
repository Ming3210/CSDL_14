-- 1
USE ss14_second;

-- 2
DELIMITER $$

create procedure IncreaseSalary(
    emp_id int,
    new_salary decimal(10,2),
    reason text
)
begin
    declare old_salary decimal(10,2);

    -- Bắt đầu transaction
    start transaction;

    -- Kiểm tra sự tồn tại của nhân viên trong bảng salaries
    select base_salary into old_salary from salaries where employee_id = emp_id;

    if old_salary is null then
        signal sqlstate '45000' set message_text = 'Nhân viên không tồn tại!';
        rollback;
    else
        -- Lưu lịch sử lương
        insert into salary_history (employee_id, old_salary, new_salary, reason)
        values (emp_id, old_salary, new_salary, reason);

        -- Cập nhật lương mới
        update salaries set base_salary = new_salary where employee_id = emp_id;

        -- Commit transaction
        commit;
    end if;
end $$

DELIMITER ;


-- 3
call IncreaseSalary(1, 5000.00, 'Tăng lương định kỳ');

select * from salaries;
select * from salary_history;


-- 4
DELIMITER //
CREATE PROCEDURE DeleteEmployee(
    IN emp_id INT
)
BEGIN
    DECLARE emp_exists INT;
    DECLARE old_salary DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
  
    START TRANSACTION;
    -- Kiểm tra xem nhân viên có tồn tại không
    SELECT COUNT(*) INTO emp_exists FROM employees WHERE employee_id = emp_id;
    
    IF emp_exists = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhân viên không tồn tại!';
    END IF;

    -- Lấy lương cũ để lưu vào lịch sử
    SELECT base_salary INTO old_salary FROM salaries WHERE employee_id = emp_id;
    
    -- Lưu lịch sử lương trước khi xóa nhân viên
    INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, reason)
    VALUES (emp_id, old_salary, NULL, NOW(), 'Nhân viên bị xóa');

    -- Xóa nhân viên trước, tránh trigger gây lỗi khi truy xuất lương
    DELETE FROM employees WHERE employee_id = emp_id;
    DELETE FROM salaries WHERE employee_id = emp_id;

    COMMIT;
END;//
DELIMITER 

drop procedure DeleteEmployee;

-- 5
call DeleteEmployee(2);


