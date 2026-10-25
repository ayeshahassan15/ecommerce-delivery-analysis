from pathlib import Path

import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st

st.set_page_config(page_title="E-commerce Delivery Analysis", layout="wide")


@st.cache_data
def load_data():
    path = Path(__file__).parent / "orders_slim.csv.gz"
    return pd.read_csv(path, parse_dates=["order_purchase_timestamp"])


df = load_data()

st.title("E-commerce Sales and Delivery Analysis")
st.caption("Olist Brazilian E-Commerce dataset (delivered orders, Oct 2016 to Aug 2018)")

# Sidebar filters
st.sidebar.header("Filters")
states = sorted(df["customer_state"].unique())
chosen_states = st.sidebar.multiselect("Customer state", states, default=states)

min_d = df["order_purchase_timestamp"].min().date()
max_d = df["order_purchase_timestamp"].max().date()
dates = st.sidebar.date_input("Purchase dates", (min_d, max_d), min_value=min_d, max_value=max_d)
if len(dates) != 2:
    st.stop()

mask = (
    df["customer_state"].isin(chosen_states)
    & (df["order_purchase_timestamp"].dt.date >= dates[0])
    & (df["order_purchase_timestamp"].dt.date <= dates[1])
)
f = df[mask]
if f.empty:
    st.warning("No orders match these filters.")
    st.stop()

# KPI cards
c1, c2, c3, c4, c5 = st.columns(5)
c1.metric("Revenue (BRL)", f"{f['revenue'].sum():,.0f}")
c2.metric("Orders", f"{len(f):,}")
c3.metric("Avg order value", f"{f['revenue'].mean():,.1f}")
c4.metric("Late deliveries", f"{f['is_late'].mean() * 100:.1f}%")
c5.metric("Avg review score", f"{f['review_score'].mean():.2f}")

left, right = st.columns(2)

# Monthly revenue
month = f["order_purchase_timestamp"].dt.to_period("M").dt.to_timestamp()
monthly = f.groupby(month)["revenue"].sum().reset_index()
monthly.columns = ["month", "revenue"]
left.plotly_chart(px.line(monthly, x="month", y="revenue", markers=True,
                          title="Monthly revenue"), use_container_width=True)

# Late % by state
late_state = (f.groupby("customer_state")["is_late"].mean() * 100).sort_values(ascending=False)
late_state = late_state.reset_index()
late_state.columns = ["state", "late_pct"]
right.plotly_chart(px.bar(late_state, x="state", y="late_pct",
                          title="Late deliveries by state (%)"), use_container_width=True)

# Review score by delay group
bins = [-np.inf, -10, 0, 3, 7, 14, np.inf]
labels = ["10+ days early", "0-10 early", "1-3 late", "4-7 late", "8-14 late", "15+ late"]
r = f.dropna(subset=["review_score"]).copy()
r["delay_group"] = pd.cut(r["delay_days"], bins=bins, labels=labels)
avg = r.groupby("delay_group", observed=True)["review_score"].mean().reset_index()
left.plotly_chart(px.bar(avg, x="delay_group", y="review_score", range_y=[0, 5],
                         title="Review score by delivery delay"), use_container_width=True)

# Late vs on-time
r["delivery"] = np.where(r["is_late"], "late", "on time")
cmp_ = r.groupby("delivery")["review_score"].mean().reset_index()
right.plotly_chart(px.bar(cmp_, x="delivery", y="review_score", range_y=[0, 5],
                          title="Average review score: late vs on time"), use_container_width=True)

st.markdown(
    "**Main finding:** late orders average about 2.6 stars against 4.3 for on-time orders. "
    "Scores fall sharply once an order is more than 3 days late."
)
st.caption("Data: Olist Brazilian E-Commerce Public Dataset (Kaggle). Code: github.com/ayeshahassan15/ecommerce-delivery-analysis")