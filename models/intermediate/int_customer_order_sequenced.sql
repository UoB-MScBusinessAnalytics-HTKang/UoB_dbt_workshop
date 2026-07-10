with orders as (
    select * from {{ ref('stg_jaffle_shop__raw_orders') }}
),

sequenced as (
    select
        order_id,
        customer_id,
        store_id, -- Kept for future multi-store scalability
        order_date,
        order_total,
        -- Sequence orders per customer within each specific store
        row_number() over (
            partition by store_id, customer_id 
            order by order_date, ordered_at
        ) as user_order_seq,
        -- Get previous order date to calculate retention velocity
        lag(order_date) over (
            partition by store_id, customer_id 
            order by order_date, ordered_at
        ) as previous_order_date
    from orders
),

final as (
    select
        order_id,
        customer_id,
        store_id,
        order_date,
        order_total,
        user_order_seq,
        case 
            when user_order_seq = 1 then 'First-time'
            else 'Repeat'
        end as purchase_type,
        -- Calculate days between current and previous purchase per store
        case 
            when previous_order_date is not null then date_diff(order_date, previous_order_date, day)
            else null
        end as days_since_prior_order
    from sequenced
)

select * from final