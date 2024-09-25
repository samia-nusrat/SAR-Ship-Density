% Constants
EARTH_RADIUS = 6371; % Earth radius in kilometers
DEGREE_TO_RADIAN = pi / 180;

% Data inspection
filePath = 'grid_float_Cargo Ships_2023_07.raster.csv';
data = readtable(filePath);
disp(head(data));

% Function to extract numeric values from a string
extractNumericValue = @(str) str2double(regexp(str, '-?\d+\.\d+', 'match', 'once'));

% Extract longitudes and latitudes
longitudes = arrayfun(@(x) extractNumericValue(data.Var2{x}), (1:height(data))');
latitudes = arrayfun(@(x) extractNumericValue(data.Var6{x}), (1:height(data))');

% Calculate grid size based on an average latitude
averageLatitude = mean(latitudes);

% Create a vector for different grid sizes (in km)
gridSizes = [10, 20, 50, 100]; % Different grid sizes to try

% Create a new figure
figure;

% Loop over each grid size and calculate ship density
for i = 1:length(gridSizes)
    gridSize = gridSizes(i);
    
    % Convert grid size to degrees
    latGridSize = gridSize / 111; % about 1 degree of latitude per 111 km
    lonGridSize = gridSize / (111 * cos(averageLatitude * DEGREE_TO_RADIAN)); % convert latitude to radians and calculate longitude size

    % Create grid edges
    lat_min = min(latitudes);
    lat_max = max(latitudes);
    lon_min = min(longitudes);
    lon_max = max(longitudes);

    lat_edges = lat_min:latGridSize:lat_max;
    lon_edges = lon_min:lonGridSize:lon_max;

    % Count ships in each grid cell
    densityCounts = histcounts2(longitudes, latitudes, lon_edges, lat_edges);

    % Normalize the density counts
    densityNormalized = densityCounts ./ max(densityCounts(:));

    % Plotting in subplot
    subplot(2, 2, i); % Create a 2x2 grid of subplots
    imagesc(lon_edges(1:end-1), lat_edges(1:end-1), densityNormalized');
    axis xy; % Correct axis orientation
    colormap([1 1 0; 1 0.5 0; 1 0 0]); % Set color map
    colorbar; % Add colorbar
    xlabel('Longitude');
    ylabel('Latitude');
    title([num2str(gridSize), 'km Grid']);
end

% Add a super title for the entire figure
sgtitle('Grid Ship Density Maps for Different Grid Sizes');
