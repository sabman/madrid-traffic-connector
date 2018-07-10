--INCIDENCES
CREATE TABLE madrid_traffic_incidences(
  id varchar(64) primary key,
  the_geom geometry(Point,4326),
  type varchar(16),
  description text,
  start timestamp,
  finish timestamp,
  created_at timestamp DEFAULT NOW()
);
SELECT cdb_cartodbfytable('madrid_traffic_incidences');
CREATE INDEX madrid_traffic_incidences_start_idx ON madrid_traffic_incidences(start);
CREATE INDEX madrid_traffic_incidences_finish_idx ON madrid_traffic_incidences(finish);
CREATE INDEX madrid_traffic_incidences_type_idx ON madrid_traffic_incidences(type);
ALTER TABLE madrid_traffic_incidences ADD CONSTRAINT madrid_traffic_incidences_id_unique UNIQUE (id);

--SERVICE LEVELS
CREATE TABLE madrid_traffic_servicelevels(
  id serial,
  the_geom geometry(LineString,4326),
  status varchar(16),
  created_at timestamp DEFAULT NOW()
);
SELECT cdb_cartodbfytable('madrid_traffic_servicelevels');

--INTENSITY POIS
CREATE TABLE madrid_traffic_intensity_pois(
  id serial,
  code varchar(32),
  intensity integer,
  occupancy integer,
  load integer,
  service_level integer,
  speed integer,
  created_at timestamp DEFAULT NOW()
);
CREATE INDEX madrid_traffic_intensity_pois_idx ON madrid_traffic_intensity_pois(code);

--INTENSITY LINES
CREATE TABLE madrid_traffic_intensity_lines(
  id serial,
  the_geom geometry(LineString,4326),
  intensity integer,
  created_at timestamp DEFAULT NOW()
);
SELECT cdb_cartodbfytable('madrid_traffic_intensity_lines');

--CAMERAS
CREATE TABLE madrid_traffic_cameras(
  the_geom geometry(Point,4326),
  name text,
  cod_id text,
  url text,
  created_at timestamp DEFAULT NOW()
);
SELECT cdb_cartodbfytable('madrid_traffic_cameras');

--DISTRICTS
CREATE VIEW madrid_traffic_districts_pond_v As (
  SELECT
    cartodb_id, the_geom, the_geom_webmercator,
    CASE
      WHEN jm_pond = 0 THEN 'no_data'
      WHEN jm_pond BETWEEN 0 AND 50 THEN 'low'
      WHEN jm_pond BETWEEN 50 AND 100 THEN 'medium'
      ELSE 'high'
    END as pond
  FROM (
    SELECT
      ds.cartodb_id, ds.the_geom,
      ds.the_geom_webmercator,
      COALESCE(SUM(jm.level_pond), 0) as jm_pond
    FROM madrid_historic_district ds
    LEFT JOIN LATERAL (
      SELECT
        CASE
          WHEN level = 1 OR level IS NULL THEN 1
          WHEN level = 2 THEN 2
          WHEN level = 3 THEN 4
          ELSE 8
        END as level_pond
      FROM madrid_waze_data_jams_mv
      WHERE ST_Intersects(ds.the_geom, the_geom)
    ) jm ON TRUE
    GROUP BY ds.cartodb_id
  ) _q
);