from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# 1. Load the exported data
orders = pd.read_csv("data/processed/orders.csv", parse_dates=["order_purchase_timestamp"])
categories = pd.read_csv("data/processed/categories.csv")
sellers = pd.read_csv("data/processed/sellers.csv")

# 2. KPI numbers
total_revenue = orders["revenue"].sum()
total_orders = len(orders)
avg_order_value = orders["revenue"].mean()
late_pct = orders["is_late"].mean() * 100
avg_review = orders["review_score"].mean()

# 3. Data for the charts
month = orders["order_purchase_timestamp"].dt.to_period("M")
monthly = orders.groupby(month).agg(orders=("order_id", "count"), revenue=("revenue", "sum"))
monthly = monthly[monthly["orders"] >= 100]
monthly.index = monthly.index.to_timestamp()

late_by_state = (orders.groupby("customer_state")["is_late"].mean() * 100).sort_values(ascending=False)

top_categories = categories.nlargest(10, "revenue").sort_values("revenue")

top_sellers = sellers.nlargest(10, "revenue").sort_values("revenue")
top_sellers["label"] = top_sellers["seller_id"].str[:8] + " (" + top_sellers["seller_state"] + ")"

# 4. Build the 4 charts
fig = make_subplots(
    rows=2, cols=2,
    subplot_titles=("Monthly revenue", "Late deliveries by state (%)",
                    "Top 10 categories by revenue", "Top 10 sellers by revenue"),
    vertical_spacing=0.18,
)
fig.add_trace(go.Scatter(x=monthly.index, y=monthly["revenue"], mode="lines+markers"), row=1, col=1)
fig.add_trace(go.Bar(x=late_by_state.index, y=late_by_state.values), row=1, col=2)
fig.add_trace(go.Bar(x=top_categories["revenue"], y=top_categories["category"], orientation="h"), row=2, col=1)
fig.add_trace(go.Bar(x=top_sellers["revenue"], y=top_sellers["label"], orientation="h"), row=2, col=2)
fig.update_layout(height=800, showlegend=False, template="plotly_white")

# 5. Put KPI cards and charts in one HTML page
def card(title, value):
    return f'<div class="card"><div class="t">{title}</div><div class="v">{value}</div></div>'

cards = "".join([
    card("Total revenue (BRL)", f"{total_revenue:,.0f}"),
    card("Total orders", f"{total_orders:,}"),
    card("Avg order value (BRL)", f"{avg_order_value:,.1f}"),
    card("Late deliveries", f"{late_pct:.1f}%"),
    card("Avg review score", f"{avg_review:.2f}"),
])

html = f"""<html><head><meta charset="utf-8"><title>E-commerce Delivery Dashboard</title>
<style>
body {{ font-family: Arial, sans-serif; margin: 24px; background: #f5f6f8; }}
h1 {{ margin-bottom: 16px; }}
.cards {{ display: flex; gap: 16px; margin-bottom: 16px; }}
.card {{ flex: 1; background: white; padding: 16px; border-radius: 8px; }}
.t {{ color: #666; font-size: 14px; }}
.v {{ font-size: 28px; font-weight: bold; margin-top: 6px; }}
</style></head><body>
<h1>E-commerce Sales and Delivery Dashboard</h1>
<div class="cards">{cards}</div>
{fig.to_html(full_html=False, include_plotlyjs="cdn")}
</body></html>"""

Path("reports/dashboard.html").write_text(html, encoding="utf-8")
print("Saved reports/dashboard.html")