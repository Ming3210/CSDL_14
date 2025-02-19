-- 1
USE ss14_first;

-- 2
DELIMITER $$

create procedure sp_create_order(
    p_customer_id int,
    p_product_id int,
    p_quantity int,
    p_price decimal(10,2)
)
begin
    declare v_stock int;
    declare v_order_id int;

    start transaction;

    -- Kiểm tra số lượng tồn kho
    select stock_quantity into v_stock from inventory where product_id = p_product_id;

    if v_stock < p_quantity then
        signal sqlstate '45000' set message_text = 'Không đủ hàng trong kho!';
        rollback;
    else
        -- Tạo đơn hàng mới
        insert into orders (customer_id, order_date, total_amount, status) 
        values (p_customer_id, now(), 0, 'Pending');

        -- Lấy ID đơn hàng vừa tạo
        set v_order_id = last_insert_id();

        -- Thêm sản phẩm vào chi tiết đơn hàng
        insert into order_items (order_id, product_id, quantity, price) 
        values (v_order_id, p_product_id, p_quantity, p_price);

        -- Cập nhật kho hàng
        update inventory set stock_quantity = stock_quantity - p_quantity where product_id = p_product_id;

        -- Commit transaction
        commit;
    end if;
end $$

DELIMITER ;

drop procedure sp_create_order;
-- 3
DELIMITER $$

create procedure sp_payment_order(
    p_order_id int,
    p_payment_method varchar(20)
)
begin
    declare v_status enum('Pending', 'Completed', 'Cancelled');
    declare v_total_amount decimal(10,2);

    start transaction;

    -- Kiểm tra trạng thái đơn hàng
    select status, total_amount into v_status, v_total_amount from orders where order_id = p_order_id;

    if v_status <> 'Pending' then
        signal sqlstate '45000' set message_text = 'Chỉ có thể thanh toán đơn hàng ở trạng thái Pending!';
        rollback;
    else
        -- Thêm bản ghi vào bảng payments
        insert into payments (order_id, payment_date, amount, payment_method, status) 
        values (p_order_id, now(), v_total_amount, p_payment_method, 'Completed');

        -- Cập nhật trạng thái đơn hàng
        update orders set status = 'Completed' where order_id = p_order_id;

        -- Commit transaction
        commit;
    end if;
end $$

DELIMITER ;

drop procedure  sp_payment_order;
-- 4
DELIMITER $$

create procedure sp_cancel_order(
    p_order_id int
)
begin
    declare v_status enum('Pending', 'Completed', 'Cancelled');

    start transaction;

    -- Kiểm tra trạng thái đơn hàng
    select status into v_status from orders where order_id = p_order_id;

    if v_status <> 'Pending' then
        signal sqlstate '45000' set message_text = 'Chỉ có thể hủy đơn hàng ở trạng thái Pending!';
        rollback;
    else
        -- Hoàn trả số lượng hàng vào kho
        update inventory i
        join order_items oi on i.product_id = oi.product_id
        set i.stock_quantity = i.stock_quantity + oi.quantity
        where oi.order_id = p_order_id;

        -- Xóa các sản phẩm khỏi bảng order_items
        delete from order_items where order_id = p_order_id;

        -- Cập nhật trạng thái đơn hàng
        update orders set status = 'Cancelled' where order_id = p_order_id;

        -- Commit transaction
        commit;
    end if;
end $$

DELIMITER ;

drop procedure sp_cancel_order;
-- 6?
drop procedure if exists sp_create_order;
drop procedure if exists sp_payment_order;
drop procedure if exists sp_cancel_order;



