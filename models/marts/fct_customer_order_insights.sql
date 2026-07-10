with sequenced_orders as (
    select * from {{ ref('int_customer_order_sequenced') }}
),

stores as (
    select * from {{ ref('stg_jaffle_shop__raw_stores') }}
),

joined as (
    select
        o.order_id,
        o.customer_id,
        o.store_id,
        s.store_name,
        o.order_date,
        o.order_total,
        o.user_order_seq,
        o.purchase_type,
        o.days_since_prior_order
    from sequenced_orders o
    left join stores s on o.store_id = s.store_id
)

select * from joined