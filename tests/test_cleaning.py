import pandas as pd

from src.cleaning import clean_orders


def make_df():
    """Small fake data: we know exactly what the right answer should be."""
    return pd.DataFrame({
        "order_id": ["a", "b", "c", "d", "a"],
        "order_status": ["delivered", "delivered", "canceled", "delivered", "delivered"],
        "order_purchase_timestamp": ["2018-01-01"] * 5,
        "order_delivered_customer_date": ["2018-01-05", "2018-01-20", None, None, "2018-01-05"],
        "order_estimated_delivery_date": ["2018-01-10"] * 5,
    })


def test_keeps_only_delivered_orders_with_date():
    result = clean_orders(make_df())
    assert set(result["order_id"]) == {"a", "b"}


def test_order_id_is_unique():
    result = clean_orders(make_df())
    assert result["order_id"].is_unique


def test_delivery_days():
    result = clean_orders(make_df()).set_index("order_id")
    assert result.loc["a", "delivery_days"] == 4


def test_late_flag():
    result = clean_orders(make_df()).set_index("order_id")
    assert not result.loc["a", "is_late"]   # 4 days, estimated 9
    assert result.loc["b", "is_late"]       # 19 days, estimated 9
    