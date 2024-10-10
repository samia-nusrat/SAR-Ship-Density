import pandas as pd
import os

# Configuration
MAX_ROWS = 1048576  # Maximum number of rows per file to match Excel's limit
# Start from July onwards
months = ['july', 'aug', 'sep', 'oct', 'nov', 'dec']

# Get the current working directory where the script and CSV files are located
base_path = os.getcwd()

# Function to merge and split CSV files
def merge_and_split_csv(month):
    data = pd.DataFrame(columns=['band', 'value', 'center', 'rect', 'Ship Count'])  # Define the column names

    # Load all CSVs for the month
    i = 1
    while True:
        file_name = f"{month}2023({i}).csv"
        file_path = os.path.join(base_path, file_name)
        if not os.path.exists(file_path):
            break  # Stop when there are no more files to load
        
        # Read CSV and append data
        temp_df = pd.read_csv(file_path)

        # Check if the DataFrame is empty to avoid any future warnings
        if not temp_df.empty:
            data = pd.concat([data, temp_df], ignore_index=True)
        i += 1
    
    # Split data into separate CSV files if it exceeds MAX_ROWS
    file_index = 1
    for start_row in range(0, len(data), MAX_ROWS):
        end_row = start_row + MAX_ROWS
        chunk = data.iloc[start_row:end_row]

        # Write to a new CSV file
        output_file = f"{month}2023"
        if file_index > 1:
            output_file += f"_{file_index}"
        output_file += ".csv"
        chunk.to_csv(output_file, index=False)

        print(f"Saved: {output_file}")
        file_index += 1

# Process from July to December
for month in months:
    merge_and_split_csv(month)
