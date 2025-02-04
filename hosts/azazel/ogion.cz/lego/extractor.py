import argparse
import requests
from bs4 import BeautifulSoup
import json
import re
import os
import datetime
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

# Set up argparse to accept a command-line argument for idSeries
parser = argparse.ArgumentParser(
    description="Obtain percentages for BrickLink Designer Program."
)
parser.add_argument(
    "series_id",
    type=int,
    nargs="?",
    default=None,
    help="ID of the series to filter submissions by.",
)
parser.add_argument(
    "--prometheus-uri",
    nargs="?",
    default="localhost:9091",
    help="ID of the series to filter submissions by.",
)
args = parser.parse_args()
prometheus_uri = args.prometheus_uri

# Prometheus setup
registry = CollectorRegistry()
gauge_progress = Gauge(
    "bricklink_submission_progress",
    "Progress percentage of pre-orders",
    ["submission_name", "series_id"],
    registry=registry,
)
gauge_max_available = Gauge(
    "bricklink_submission_max_available",
    "Number of pre-ordered sets",
    ["submission_name", "series_id"],
    registry=registry,
)

# Define state directory
state_directory = os.getenv("STATE_DIRECTORY", ".")
current_time = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup_file = os.path.join(state_directory, f"bricklink_data_{current_time}.json")

# Fetch the webpage
url = "https://www.bricklink.com/v3/designer-program/main.page"

# Headers to mimic a real browser request
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
}

# Fetch the webpage with the custom headers
response = requests.get(url, headers=headers)

# Check if the request was successful
if response.status_code != 200:
    print(f"Failed to fetch the page: {response.status_code}")
    exit()

# Parse the HTML
soup = BeautifulSoup(response.content, features="html.parser")


# Find the <script> tag that contains 'blapp.models.set'
script_tag = None
for script in soup.find_all("script"):
    if "blapp.models.set" in script.string if script.string else "":
        script_tag = script.string
        break

if script_tag is None:
    print("Couldn't find the script containing the 'blapp.models.set' call.")
    exit()

# Extract the JSON data from the 'blapp.models.set' call using regex
json_data = re.search(r"blapp.models.set\((.*)\);", script_tag)
if not json_data:
    print("Failed to extract JSON data.")
    exit()

# Load the extracted JSON
data = json.loads(json_data.group(1))

# Save JSON backup
with open(backup_file, "w") as f:
    json.dump(data, f)

submissions = []
crowd_data = {}

# Loop through each section of the JSON data
for section in data:
    # Process submission finalists
    if section["name"] == "submissions_finalists":
        submissions = section["data"]["data"]["submissions"]

    # Process crowd data (which contains preorder progress)
    elif section["name"] == "crowdData":
        for entry in section["data"]:
            crowd_data[entry["idSubmission"]] = entry["stock"]

# Prepare data for the table, filtering by series_id if specified
table_data = []
for submission in submissions:
    submission_id = submission["idSubmission"]
    title = submission["strSubmissionName"]
    id_series = submission["dmBDPSeries"]["idSeries"]

    # Filter based on the series_id provided via CLI
    if args.series_id is not None and id_series != args.series_id:
        continue

    # Get the stock data from crowdData (if available)
    stock = crowd_data.get(submission_id)
    if stock is not None:
        progress = stock["dPercentagePreordered"]
        max_available = stock["nMaxAvailable"]
        # Push to Prometheus
        gauge_progress.labels(
            submission_name=title,
            series_id=id_series,
        ).set(progress)
        gauge_max_available.labels(
            submission_name=title,
            series_id=id_series,
        ).set(max_available)

# Push metrics to Prometheus
push_to_gateway(
    prometheus_uri,
    job="bricklink_scraper",
    registry=registry,
)
