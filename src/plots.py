import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

sns.set_theme(style="whitegrid")


def monthly_revenue_chart(df):
    """Line chart: revenue per month (months with fewer than 100 orders removed)."""
    month = df["order_purchase_timestamp"].dt.to_period("M")
    monthly = df.groupby(month).agg(orders=("order_id", "count"), revenue=("revenue", "sum"))
    monthly = monthly[monthly["orders"] >= 100]
    monthly.index = monthly.index.to_timestamp()

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(monthly.index, monthly["revenue"], marker="o")
    ax.set_title("Monthly revenue (delivered orders)")
    ax.set_xlabel("Month")
    ax.set_ylabel("Revenue (BRL)")
    return fig


def late_pct_by_state_chart(df):
    """Bar chart: percentage of late orders in each customer state."""
    late_pct = (df.groupby("customer_state")["is_late"].mean() * 100).sort_values(ascending=False)

    fig, ax = plt.subplots(figsize=(10, 5))
    sns.barplot(x=late_pct.index, y=late_pct.values, ax=ax, color="steelblue")
    ax.set_title("Late deliveries by customer state")
    ax.set_xlabel("State")
    ax.set_ylabel("Late orders (%)")
    return fig


def review_by_delivery_chart(df):
    """Bar chart: average review score for late vs on-time orders."""
    data = df.dropna(subset=["review_score"]).copy()
    data["delivery"] = np.where(data["is_late"], "late", "on_time")

    fig, ax = plt.subplots(figsize=(6, 5))
    sns.barplot(data=data, x="delivery", y="review_score", ax=ax, errorbar=None)
    ax.set_title("Average review score: late vs on-time")
    ax.set_xlabel("")
    ax.set_ylabel("Average review score")
    ax.set_ylim(0, 5)
    return fig


def review_by_delay_chart(df):
    """Bar chart: average review score by how early or late the order arrived."""
    data = df.dropna(subset=["review_score"]).copy()
    bins = [-np.inf, -10, 0, 3, 7, 14, np.inf]
    labels = ["10+ days early", "0-10 early", "1-3 late", "4-7 late", "8-14 late", "15+ late"]
    data["delay_group"] = pd.cut(data["delay_days"], bins=bins, labels=labels)

    avg = data.groupby("delay_group", observed=True)["review_score"].mean()

    fig, ax = plt.subplots(figsize=(10, 5))
    sns.barplot(x=avg.index, y=avg.values, ax=ax, color="steelblue")
    ax.set_title("Review score by delivery delay")
    ax.set_xlabel("Delivery vs estimated date")
    ax.set_ylabel("Average review score")
    ax.set_ylim(0, 5)
    return fig