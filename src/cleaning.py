import pandas as pd

DATE_COLS = [
    "order_purchase_timestamp",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]


def clean_orders(df):
    """Return delivered orders with delivery features added."""
    df = df.copy()

    # Text -> real dates
    for col in DATE_COLS:
        df[col] = pd.to_datetime(df[col])

    # One row per order
    df = df.drop_duplicates(subset="order_id")

    # Keep only delivered orders that have a delivery date
    df = df[
        (df["order_status"] == "delivered")
        & df["order_delivered_customer_date"].notna()
    ].copy()

    # New columns (feature engineering)
    one_day = pd.Timedelta(days=1)
    df["delivery_days"] = (
        df["order_delivered_customer_date"] - df["order_purchase_timestamp"]
    ) / one_day
    df["estimated_days"] = (
        df["order_estimated_delivery_date"] - df["order_purchase_timestamp"]
    ) / one_day
    df["delay_days"] = df["delivery_days"] - df["estimated_days"]
    df["is_late"] = df["delay_days"] > 0

    return df