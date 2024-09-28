% Constants
EARTH_RADIUS = 6371;
DEGREE_TO_RADIAN = pi / 180;

% Load the new dataset
filePath = 'grid_float_NonLoitering_2024_08.raster.csv';
data = readtable(filePath);
disp(head(data));

% Function to extract numeric values from a string
extractNumericValue = @(str) str2double(regexp(str, '-?\d+\.\d+', 'match', 'once'));

% Extract longitudes and latitudes
longitudes = arrayfun(@(x) extractNumericValue(data.Var2{x}), (1:height(data))');
latitudes = arrayfun(@(x) extractNumericValue(data.Var6{x}), (1:height(data))');

% Define coastal and deep sea regions by latitude and longitude ranges
coastalLatRange = [43.5753, 50.5];
coastalLonRange = [-70, -54];
deepSeaLatRange = [50.5, 51.3981];
deepSeaLonRange = [-70, -54];

% Define coastal and deep sea region conditions
isCoastal = (latitudes >= coastalLatRange(1)) & (latitudes <= coastalLatRange(2)) & ...
            (longitudes >= coastalLonRange(1)) & (longitudes <= coastalLonRange(2));
isDeepSea = (latitudes >= deepSeaLatRange(1)) & (latitudes <= deepSeaLatRange(2)) & ...
            (longitudes >= deepSeaLonRange(1)) & (longitudes <= deepSeaLonRange(2));

% Separate datasets for coastal and deep sea regions
coastalLongitudes = longitudes(isCoastal);
coastalLatitudes = latitudes(isCoastal);
deepSeaLongitudes = longitudes(isDeepSea);
deepSeaLatitudes = latitudes(isDeepSea);

% Check how many points are in each region
numCoastalPoints = sum(isCoastal);
numDeepSeaPoints = sum(isDeepSea);
disp(['Number of coastal data points: ', num2str(numCoastalPoints)]);
disp(['Number of deep sea data points: ', num2str(numDeepSeaPoints)]);

if numCoastalPoints == 0
    error('No data points found in the defined coastal region.');
end
if numDeepSeaPoints == 0
    warning('No data points found in the defined deep sea region.');
end

% Grid sizes to explore
gridSizes = [10, 25, 50, 100];
numGridSizes = length(gridSizes);

% Create a figure for subplots
figure;

for i = 1:numGridSizes
    gridSize = gridSizes(i);
    
    latGridSize = gridSize / 111;
    lonGridSize = gridSize / (111 * cos(mean(coastalLatitudes) * DEGREE_TO_RADIAN));

    lat_edges_coastal = min(coastalLatitudes):latGridSize:max(coastalLatitudes);
    lon_edges_coastal = min(coastalLongitudes):lonGridSize:max(coastalLongitudes);
    
    densityCountsCoastal = histcounts2(coastalLongitudes, coastalLatitudes, lon_edges_coastal, lat_edges_coastal);
    
    if any(densityCountsCoastal(:) > 0)
        densityNormalizedCoastal = densityCountsCoastal ./ max(densityCountsCoastal(:));
    else
        densityNormalizedCoastal = zeros(size(densityCountsCoastal));
    end
    
    subplot(2, numGridSizes, i);
    imagesc(lon_edges_coastal(1:end-1), lat_edges_coastal(1:end-1), densityNormalizedCoastal');
    axis xy;
    colormap([1 1 0; 1 0.5 0; 1 0 0]);
    colorbar;
    xlabel('Longitude');
    ylabel('Latitude');
    title(['Coastal Region: ', num2str(gridSize), ' km Grid']);
    
    lat_edges_deepSea = min(deepSeaLatitudes):latGridSize:max(deepSeaLatitudes);
    lon_edges_deepSea = min(deepSeaLongitudes):lonGridSize:max(deepSeaLongitudes);
    
    densityCountsDeepSea = histcounts2(deepSeaLongitudes, deepSeaLatitudes, lon_edges_deepSea, lat_edges_deepSea);
    disp(['Density counts for Deep Sea at ', num2str(gridSize), ' km:']);
    disp(densityCountsDeepSea);
    
    if any(densityCountsDeepSea(:) > 0)
        densityNormalizedDeepSea = densityCountsDeepSea ./ max(densityCountsDeepSea(:));
    else
        densityNormalizedDeepSea = zeros(size(densityCountsDeepSea));
    end
    
    subplot(2, numGridSizes, i + numGridSizes);
    if all(densityNormalizedDeepSea(:) == 0)
        imagesc(lon_edges_deepSea(1:end-1), lat_edges_deepSea(1:end-1), densityNormalizedDeepSea');
        title(['Deep Sea Region: ', num2str(gridSize), ' km Grid (No Data)']);
    else
        imagesc(lon_edges_deepSea(1:end-1), lat_edges_deepSea(1:end-1), densityNormalizedDeepSea');
        title(['Deep Sea Region: ', num2str(gridSize), ' km Grid']);
    end
    axis xy;
    colormap([1 1 0; 1 0.5 0; 1 0 0]);
    colorbar;
    xlabel('Longitude');
    ylabel('Latitude');
end
