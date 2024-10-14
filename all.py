import requests
import pandas as pd
from calendar import monthrange
from concurrent.futures import ThreadPoolExecutor, as_completed

KM_TO_DEGREE = 1 / 111.32
PIXEL_AREA_KM2 = 1  # Each pixel represents 1 square kilometer
T_avg = 1  # Assume each ship spends 1 hour on average

def fetch_density_data_for_pixel(time, pixel_bbox, behavior):
    base_url = "https://gmtds.maplarge.com/ogc/ais:density/wms"
    
    # Only filter based on behavior, removing vessel type filtering
    cql_filter = f"behavior_column='{behavior}'"
    
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
        "cql_filter": cql_filter,  # Dynamic filter only for behavior
        "query_layers": "ais:density",
        "info_format": "application/vnd.geo+json",
        "feature_count": 1,
        "I": 64,
        "J": 196
    }

    response = requests.get(base_url, params=params)
    print(f"Requesting data for {time} with URL: {response.url}")
    
    if response.status_code == 200:
        data = response.json()
        if "features" in data and len(data["features"]) > 0:
            density_value = data["features"][0]["properties"].get("DEFAULT")
            
            # Calculate Ship Count
            if density_value is not None:
                try:
                    density_value = float(density_value)  # Convert density to a float
                    ship_count = int(density_value * PIXEL_AREA_KM2 / T_avg)  # Convert to integer
                except ValueError:
                    print(f"Invalid density value: {density_value}")
                    ship_count = None
            else:
                ship_count = None
                
            return {
                "Date": time,
                "Pixel BBox": pixel_bbox,
                "Density (Hours per Square Kilometer)": density_value,
                "Ship Count": ship_count
            }
    else:
        print(f"Error for {time}, Pixel BBox: {pixel_bbox}: {response.status_code} - {response.text}")
    return None

def get_density_data(bbox, year, month, behavior, output_file):
    output_data = []
    min_lat, min_lon, max_lat, max_lon = map(float, bbox.split(','))

    lat_diff = max_lat - min_lat
    lon_diff = max_lon - min_lon

    num_pixels_height = int(lat_diff / KM_TO_DEGREE)
    num_pixels_width = int(lon_diff / KM_TO_DEGREE)

    try:
        days_in_month = monthrange(year, month)[1]  # Get days in the selected month

        for day in range(1, days_in_month + 1):
            time = f"{year}-{month:02d}-{day:02d}T00:00:00Z"
            futures = []

            with ThreadPoolExecutor(max_workers=10) as executor:
                for row in range(num_pixels_height):
                    for col in range(num_pixels_width):
                        pixel_min_lat = min_lat + row * KM_TO_DEGREE
                        pixel_max_lat = pixel_min_lat + KM_TO_DEGREE
                        pixel_min_lon = min_lon + col * KM_TO_DEGREE
                        pixel_max_lon = pixel_min_lon + KM_TO_DEGREE

                        pixel_bbox = f"{pixel_min_lat},{pixel_min_lon},{pixel_max_lat},{pixel_max_lon}"

                        # Parallelize the requests using ThreadPoolExecutor
                        futures.append(
                            executor.submit(fetch_density_data_for_pixel, time, pixel_bbox, behavior)
                        )

                for future in as_completed(futures):
                    result = future.result()
                    if result:
                        output_data.append(result)

            # Save data after processing each day
            if output_data:
                df = pd.DataFrame(output_data)
                df.to_csv(f"{output_file}_{month:02d}_{day:02d}.csv", index=False)
                print(f"Data for {year}-{month:02d}-{day:02d} saved to {output_file}_{month:02d}_{day:02d}.csv")
                output_data.clear()  # Clear data for the next day

    except KeyboardInterrupt:
        # Handle manual stop and save the data collected so far
        if output_data:
            df = pd.DataFrame(output_data)
            df.to_csv(f"{output_file}_interrupted.csv", index=False)
            print(f"Process interrupted. Data saved to {output_file}_interrupted.csv.")
        else:
            print("No data collected to save.")

# User input
bbox = input("Enter the bounding box (format: min_lat,min_lon,max_lat,max_lon): ")
year = int(input("Enter the year (e.g., 2024): "))
month = int(input("Enter the month (1-12): "))
behavior = input("Enter the vessel behavior (Loitering or NonLoitering): ")
output_file = input("Enter the output CSV file name base (e.g., density_data): ")

# Call the function
get_density_data(bbox, year, month, behavior, output_file)