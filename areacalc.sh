#! /bin/bash
PATH=$PATH:/cygdrive/c/OSGeo4W/bin/:/cygdrive/c/SubPrograms/

rm -f summary.csv data.csv
for MAP in Agri Building Forest; do
	rm -f $MAP.shp $MAP.shx $MAP.dbf ${MAP}_single.*
	ogr2ogr -t_srs EPSG:24378 $MAP.shp $MAP.kml
	spatialite <<EOF
.loadshp $MAP $MAP UTF-8 24378 the_geom 2d
create table tmp as select rowid as id, gunion(the_geom) as ext from $MAP;
.dumpshp tmp ext ${MAP}_union UTF-8 POLYGON
EOF
	ogr2ogr -explodecollections -nlt POLYGON ${MAP}_single.shp ${MAP}_union.shp
	ogr2ogr -f KML -s_srs EPSG:24378 -t_srs EPSG:4326 ${MAP}_single.kml ${MAP}_single.shp
	spatialite >> data.csv <<EOF
.loadshp ${MAP}_single ${MAP}_single UTF-8 24378 the_geom 2d
.separator ,
select '$MAP',rowid,area(the_geom) from ${MAP}_single;
EOF
	spatialite >> summary.csv <<EOF
.loadshp ${MAP}_single ${MAP}_single UTF-8 24378 the_geom 2d
.separator ,
select '${MAP}',sum(1),sum(area(the_geom)) from ${MAP}_single;
EOF
done
MAP=Building
rm -f building_hist.csv
	spatialite >> building_hist.csv <<EOF
.loadshp ${MAP}_single ${MAP}_single UTF-8 24378 the_geom 2d
.separator ,
select '0-50',sum(1),sum(area(the_geom)) from ${MAP}_single where area(the_geom) < 50;
select '50-100',sum(1),sum(area(the_geom)) from ${MAP}_single where area(the_geom) >= 50 and area(the_geom) < 100;
select '100-200',sum(1),sum(area(the_geom)) from ${MAP}_single where area(the_geom) >= 100 and area(the_geom) < 200;
select '200-',sum(1),sum(area(the_geom)) from ${MAP}_single where area(the_geom) >= 200 ;
EOF

rm -f data_line.csv summary_line.csv
for MAP in Road Fence; do
	ogr2ogr -t_srs EPSG:24378 ${MAP}.shp ${MAP}.kml
	spatialite >> data_line.csv <<EOF
.loadshp ${MAP} ${MAP} UTF-8 24378 the_geom 2d
.separator ,
select '${MAP}',rowid, glength(the_geom) from ${MAP};
EOF

	spatialite >> summary_line.csv <<EOF
.loadshp ${MAP} ${MAP} UTF-8 24378 the_geom 2d
.separator ,
select '${MAP}',sum(1),sum(glength(the_geom)) from ${MAP};
EOF
done

MAP=Fence
rm -f fence_hist.csv
	spatialite >> fence_hist.csv <<EOF
.loadshp ${MAP} ${MAP} UTF-8 24378 the_geom 2d
.separator ,
select '0-20',sum(1),sum(glength(the_geom)) from ${MAP} where glength(the_geom) < 20;
select '20-50',sum(1),sum(glength(the_geom)) from ${MAP} where glength(the_geom) >= 20 and glength(the_geom) < 50;
select '50-100',sum(1),sum(glength(the_geom)) from ${MAP} where glength(the_geom) >= 50 and glength(the_geom) < 100;
select '100-',sum(1),sum(glength(the_geom)) from ${MAP} where glength(the_geom) >= 100 ;
EOF

exit 0
