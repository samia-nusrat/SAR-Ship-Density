clear;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%Incidents Extraction And Plotting%%%
% incidents = readtable('TSB Marine Occurrence Extracted Data (Macro Enabled) (1).xlsm');
% lat = incidents.LatitudeMap;
% lon = incidents.LongitudeMap;
% pvt = incidents.PrimaryVesselType;
% month = incidents.OccMonth;
% year = incidents.OccYear;
% 
% row = find(pvt(:,1)=="FISHING");  %define parameters to sort by
% 
% newlat = lat(row,:);
% newlon = lon(row,:);
% newmonth = month(row,:);
% newyear = year(row,:);
% 
% row2= find(newmonth(:,1)==1);     %define parameters to sort by
% 
% newlat2 = newlat(row2);
% newlon2 = newlon(row2);
% newyear2 = newyear(row2);
% 
% row3 = find(newyear2(:,1)<=2019 & newyear2(:,1)>=2014);     %define
% parameters to sort etween
% 
% newlat3 = newlat2(row3);
% newlon3 = newlon2(row3);
% 
% %np.mod(newlon2, 360)
% 
% %newlon3 = mod(newlon2, 360);
% 
% 
% geoscatter(newlat3, newlon3, "*")
% hold on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%Density CSV Extraction%%%
%select grid size and use respective header names
trafficdensity = readtable('grid_float_Cargo Ships_2022_08.raster.csv'); %grid_float_Cargo Ships_2022_08.raster.csv for 50km grid or 10km_grids_2022_08 or 20km....., 10km....
lat = trafficdensity.Latitude_central; %..._central for 50km, _Points for the rest
lon = trafficdensity.Longitude_central; %or ..._central for 50km, _Points for the rest
latdens = trafficdensity.Latitude;
londens = trafficdensity.Longitude;
value = trafficdensity.Value_SUM;

%For docked vessels  ///done to deal with outliers
%value(value>=1000) = 0; % git rid of very high rates

value(value==0) = NaN;  %turn zeros to NaN

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%Getting Rid of Docked Vessels%%%
% row0 = find(value(:,1)<=250); 
% 
% lat = lat(row0,:);
% lon = lon(row0,:);
% value = value(row0,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%Historgram%%%
%histogram(value, 3)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%Different Colored Scatters Depending On Value%%%
figure()
row = find(value(:,1)<=20);  %0.8 for 10km, 3.5 for 20km, 20 for 50km, 88 for 100km

lat1 = lat(row,:);
lon1 = lon(row,:);
value1 = value(row,:);

m1 = mean(value1)

geoscatter(lat1, lon1, "MarkerFaceColor", "b", "MarkerEdgeColor", "b", "LineWidth", 0.5)
hold on

row2 = find(value(:,1)<=50 & value(:,1)>=20);

lat2 = lat(row2,:);
lon2 = lon(row2,:);
value2 = value(row2,:);

m2 = mean(value2)

geoscatter(lat2, lon2, "MarkerFaceColor", "y", "MarkerEdgeColor", "y", "LineWidth", 0.5)
hold on

row3 = find(value(:,1)>=50); %3 for 10km, 8-10 for 20km, 50 for 50km, 250 for 100km

lat3 = lat(row3,:);
lon3 = lon(row3,:);
value3 = value(row3,:);

m3 = mean(value3)

geoscatter(lat3, lon3, "MarkerFaceColor", "r", "MarkerEdgeColor", "r", "LineWidth", 0.5)
hold on

geobasemap streets

n = ["blue" "yellow" "red"]
y = [row row2 row3]

figure()
%histogram(value, 'BinCounts', n)

bar(n, y)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%selectable scatter with density plot above it%%%
figure()
geoscatter(lat, lon, "o", "LineWidth", 0.2, "PickableParts", "none");
hold on

geoscatter(lat, lon, value, "filled", "LineWidth", 0.5);
hold on

geobasemap streets

figure()
geodensityplot(latdens,londens, 'FaceColor', 'interp');
hold on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%Map Limit and Display%%%
%geolimits([40 60],[-90 -30])


geobasemap streets