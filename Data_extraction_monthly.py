import requests
import pandas as pd
from calendar import monthrange
import os

KM_TO_DEGREE = 1 / 111.32

def save_data(data, file_name):
    """Save data to CSV file."""
    if data:
        df = pd.DataFrame(data)
        df.to_csv(file_name, index=False)
        print(f"Data saved to {file_name}")
    else:
        print("No data to save.")

def get_density_data(bbox, year, vessel_type, months, output_file):
    min_lat, min_lon, max_lat, max_lon = map(float, bbox.split(','))

    lat_diff = max_lat - min_lat
    lon_diff = max_lon - min_lon

    num_pixels_height = int(lat_diff / KM_TO_DEGREE)
    num_pixels_width = int(lon_diff / KM_TO_DEGREE)

    monthly_data = []

    try:
        for month in months:
            days_in_month = monthrange(year, month)[1]

            for day in range(1, days_in_month + 1):
                time = f"{year}-{month:02d}-{day:02d}T00:00:00Z"
                print(f"Processing date: {time}")

                for row in range(num_pixels_height):
                    for col in range(num_pixels_width):
                        pixel_min_lat = min_lat + row * KM_TO_DEGREE
                        pixel_max_lat = pixel_min_lat + KM_TO_DEGREE
                        pixel_min_lon = min_lon + col * KM_TO_DEGREE
                        pixel_max_lon = pixel_min_lon + KM_TO_DEGREE

                        pixel_bbox = f"{pixel_min_lat},{pixel_min_lon},{pixel_max_lat},{pixel_max_lon}"

                        base_url = "https://gmtds.maplarge.com/ogc/ais:density/wms"
                        params = {
                            "SERVICE": "WMS",
                            "REQUEST": "GetFeatureInfo",
                            "LAYERS": "ais:density",
                            "STYLES": "",
                            "FORMAT": "image/png",
                            "TRANSPARENT": "TRUE",
                            "version": "1.3.0",
                            "WIDTH": 256,
                            "HEIGHT": 256,
                            "CRS": "EPSG:4326",
                            "bbox": pixel_bbox,
                            "time": time,
                            "cql_filter": f"category_column='ShipTypeAgg' AND category='{vessel_type}'",
                            "query_layers": "ais:density",
                            "info_format": "application/vnd.geo+json",
                            "feature_count": 1,
                            "I": 64,
                            "J": 196
                        }

                        try:
                            response = requests.get(base_url, params=params)
                            print(f"Requesting data for {time} with URL: {response.url}")

                            if response.status_code == 200:
                                try:
                                    data = response.json()
                                    print(f"Response Data: {data}")
                                    if "features" in data and len(data["features"]) > 0:
                                        density_value = data["features"][0]["properties"].get("DEFAULT")
                                        monthly_data.append({
                                            "Date": time,
                                            "Pixel BBox": pixel_bbox,
                                            "Density (Hours per Square Kilometer)": density_value
                                        })
                                    else:
                                        print(f"No features found for {time}, Pixel BBox: {pixel_bbox}. Response: {data}")
                                except ValueError:
                                    print(f"Failed to decode JSON for {time}, Pixel BBox: {pixel_bbox}. Response: {response.text}")
                            else:
                                print(f"Error for {time}, Pixel BBox: {pixel_bbox}: {response.status_code} - {response.text}")
                        except requests.RequestException as e:
                            print(f"Request failed for {time}, Pixel BBox: {pixel_bbox}: {e}")

            # Save data for the month
            save_data(monthly_data, f"{output_file}_{year}_{month:02d}.csv")

    except KeyboardInterrupt:
        # Handle manual stop and save the data collected so far
        print("Process interrupted.")
        save_data(monthly_data, f"{output_file}_interrupted.csv")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# User input
bbox = input("Enter the bounding box (format: min_lat,min_lon,max_lat,max_lon): ")
year = int(input("Enter the year (e.g., 2024): "))
vessel_type = input("Enter the type of vessel (e.g., Cargo Ships, Fishing, Icebreakers, etc.): ")
months_input = input("Enter the months to process (comma-separated, e.g., 1,2,3): ")
output_file = input("Enter the output CSV file name base (e.g., density_data): ")

# Convert months_input to a list of integers
months = list(map(int, months_input.split(',')))

# Ensure the output directory exists
output_directory = os.path.dirname(output_file)
if output_directory and not os.path.exists(output_directory):
    os.makedirs(output_directory)

# Call the function
get_density_data(bbox, year, vessel_type, months, output_file)
