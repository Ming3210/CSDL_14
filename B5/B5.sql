USE ss14_first;

-- 2
DELIMITER $$
CREATE TRIGGER before_insert_check_payment
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE order_total DECIMAL(10,2);
    -- Lấy tổng tiền đơn hàng từ bảng orders
    SELECT total_amount INTO order_total
    FROM orders
    WHERE order_id = NEW.order_id;
    -- Kiểm tra số tiền thanh toán
    IF NEW.amount != order_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số tiền thanh toán không khớp với tổng đơn hàng!';
    END IF;
END $$
DELIMITER ;
-- 3
CREATE TABLE order_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    old_status ENUM('Pending', 'Completed', 'Cancelled'),
    new_status ENUM('Pending', 'Completed', 'Cancelled'),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);
-- 4
DELIMITER $$

CREATE PROCEDURE sp_update_order_status_with_payment(
    IN p_order_id INT,
    IN p_new_status ENUM('Pending', 'Completed', 'Cancelled'),
    IN p_amount DECIMAL(10,2),
    IN p_payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash')
)
BEGIN
    DECLARE current_status ENUM('Pending', 'Completed', 'Cancelled');

    -- Kiểm tra xem đơn hàng có tồn tại không
    IF (SELECT COUNT(*) FROM orders WHERE order_id = p_order_id) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Đơn hàng không tồn tại!';
    END IF;

    -- Lấy trạng thái hiện tại của đơn hàng
    SELECT status INTO current_status FROM orders WHERE order_id = p_order_id;

    -- Nếu trạng thái không thay đổi, không làm gì cả
    IF current_status = p_new_status THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Đơn hàng đã có trạng thái này!';
    END IF;

    -- Bắt đầu giao dịch
    START TRANSACTION;

    -- Nếu cập nhật trạng thái thành 'Completed', thêm thông tin thanh toán
    IF p_new_status = 'Completed' THEN
        INSERT INTO payments (order_id, payment_date, amount, payment_method, status)
        VALUES (p_order_id, NOW(), p_amount, p_payment_method, 'Completed');
    END IF;

    -- Cập nhật trạng thái đơn hàng
    UPDATE orders
    SET status = p_new_status
    WHERE order_id = p_order_id;

    -- Kiểm tra nếu có hàng bị ảnh hưởng
    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không thể cập nhật trạng thái đơn hàng!';
    ELSE
        COMMIT;
    END IF;
END $$

DELIMITER ;

-- 6

INSERT INTO customers (name, email) VALUES ('Nguyen Van A', 'nguyenvana@example.com');
INSERT INTO orders (customer_id, total_amount) VALUES (1, 100.00);

CALL sp_update_order_status_with_payment(1, 'Completed', 100.00, 'Credit Card');
-- 7

SELECT * FROM order_logs;

-- 8
DROP TRIGGER IF EXISTS before_insert_check_payment;
DROP TRIGGER IF EXISTS after_update_order_status;
DROP PROCEDURE IF EXISTS sp_update_order_status_with_payment;