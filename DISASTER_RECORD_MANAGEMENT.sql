-- =============================================================
-- MAHARASHTRA DISASTER MANAGEMENT DATABASE
-- Beginner-friendly MySQL 8.0 script
-- Uses ordinary CREATE TABLE, INSERT, SELECT, UPDATE and JOIN queries.
-- No AI, stored procedures, triggers, or advanced automation in SQL.
-- Python will later perform the risk calculations and allocation logic.
--
-- GEOGRAPHY INCLUDED:
--   All 36 Maharashtra districts
--   All 15 Raigad talukas (pilot district)
--   48 Raigad locations listed in the 2024 Maharashtra Landslide
--   Management Plan Appendix 5.2 as very-high-priority entries.
--
-- IMPORTANT:
--   This is NOT a complete list of every disaster-affected village in
--   Maharashtra. Hazard-priority locations are not the same as confirmed
--   historical disaster incidents. No fictional incidents, rescue teams,
--   resource centres or stock quantities are inserted.
--   Add real operational data only after checking official records.
-- =============================================================

CREATE DATABASE IF NOT EXISTS maharashtra_disaster_db;
USE maharashtra_disaster_db;

-- 1. COUNTRY
CREATE TABLE countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL
);

-- 2. STATE
CREATE TABLE states (
    state_id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT NOT NULL,
    state_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

-- 3. DISTRICTS
CREATE TABLE districts (
    district_id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    district_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (state_id) REFERENCES states(state_id)
);

-- 4. TALUKAS
CREATE TABLE talukas (
    taluka_id INT AUTO_INCREMENT PRIMARY KEY,
    district_id INT NOT NULL,
    taluka_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (district_id) REFERENCES districts(district_id)
);

-- 5. VILLAGES / CITIES / LOCALITIES
CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    taluka_id INT NOT NULL,
    location_name VARCHAR(150) NOT NULL,
    location_type VARCHAR(40) DEFAULT 'VILLAGE_OR_LOCALITY',
    pincode VARCHAR(6),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    is_verified TINYINT DEFAULT 0,
    FOREIGN KEY (taluka_id) REFERENCES talukas(taluka_id)
);

-- 6. DISASTER TYPES
CREATE TABLE disaster_types (
    disaster_type_id INT AUTO_INCREMENT PRIMARY KEY,
    disaster_name VARCHAR(80) NOT NULL
);

-- 7. HAZARD / RISK-PRONE LOCATION RECORDS
-- These are sourced hazard-priority records, not actual incident records.
CREATE TABLE hazard_records (
    hazard_id INT AUTO_INCREMENT PRIMARY KEY,
    location_id INT,
    district_id INT NOT NULL,
    disaster_type_id INT NOT NULL,
    risk_level VARCHAR(30),
    susceptible_area_hectares DECIMAL(12,4),
    source_name VARCHAR(200),
    source_year VARCHAR(30),
    source_note TEXT,
    FOREIGN KEY (location_id) REFERENCES locations(location_id),
    FOREIGN KEY (district_id) REFERENCES districts(district_id),
    FOREIGN KEY (disaster_type_id) REFERENCES disaster_types(disaster_type_id)
);

-- 8. DISASTER INCIDENTS
-- Every new disaster occurrence gets a separate row. Do not overwrite history.
CREATE TABLE disaster_incidents (
    incident_id INT AUTO_INCREMENT PRIMARY KEY,
    incident_code VARCHAR(40) NOT NULL,
    district_id INT NOT NULL,
    taluka_id INT,
    location_id INT,
    disaster_type_id INT NOT NULL,
    incident_date DATETIME NOT NULL,
    severity VARCHAR(30),
    affected_people INT DEFAULT 0,
    injured_people INT DEFAULT 0,
    missing_people INT DEFAULT 0,
    deaths INT DEFAULT 0,
    estimated_damage_rupees DECIMAL(15,2),
    description TEXT,
    incident_status VARCHAR(30) DEFAULT 'REPORTED',
    reported_by VARCHAR(100),
    FOREIGN KEY (district_id) REFERENCES districts(district_id),
    FOREIGN KEY (taluka_id) REFERENCES talukas(taluka_id),
    FOREIGN KEY (location_id) REFERENCES locations(location_id),
    FOREIGN KEY (disaster_type_id) REFERENCES disaster_types(disaster_type_id)
);

-- 9. RISK ASSESSMENTS
-- Python will calculate the score; MySQL stores the result and explanation.
CREATE TABLE risk_assessments (
    assessment_id INT AUTO_INCREMENT PRIMARY KEY,
    incident_id INT NOT NULL,
    risk_score DECIMAL(5,2),
    risk_category VARCHAR(30),
    factors_used TEXT,
    assessment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (incident_id) REFERENCES disaster_incidents(incident_id)
);

-- 10. INCIDENT STATUS / PROGRESS UPDATES
CREATE TABLE incident_updates (
    update_id INT AUTO_INCREMENT PRIMARY KEY,
    incident_id INT NOT NULL,
    status_name VARCHAR(30),
    update_description TEXT,
    updated_by VARCHAR(100),
    update_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (incident_id) REFERENCES disaster_incidents(incident_id)
);

-- 11. RESCUE TEAMS
CREATE TABLE rescue_teams (
    team_id INT AUTO_INCREMENT PRIMARY KEY,
    team_name VARCHAR(150) NOT NULL,
    district_id INT NOT NULL,
    taluka_id INT,
    team_size INT DEFAULT 0,
    team_status VARCHAR(30) DEFAULT 'AVAILABLE',
    contact_number VARCHAR(20),
    FOREIGN KEY (district_id) REFERENCES districts(district_id),
    FOREIGN KEY (taluka_id) REFERENCES talukas(taluka_id)
);

-- 12. TEAM SKILLS / CAPABILITIES
CREATE TABLE team_capabilities (
    capability_id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    disaster_type_id INT NOT NULL,
    skill_description VARCHAR(200),
    FOREIGN KEY (team_id) REFERENCES rescue_teams(team_id),
    FOREIGN KEY (disaster_type_id) REFERENCES disaster_types(disaster_type_id)
);

-- 13. TEAM ASSIGNMENTS TO INCIDENTS
CREATE TABLE team_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    incident_id INT NOT NULL,
    team_id INT NOT NULL,
    distance_km DECIMAL(8,2),
    assignment_status VARCHAR(30) DEFAULT 'PROPOSED',
    approved_by VARCHAR(100),
    assignment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (incident_id) REFERENCES disaster_incidents(incident_id),
    FOREIGN KEY (team_id) REFERENCES rescue_teams(team_id)
);

-- 14. RESOURCE TYPES / ITEMS
CREATE TABLE resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(120) NOT NULL,
    unit_name VARCHAR(40) NOT NULL
);

-- 15. RESOURCE CENTRES
CREATE TABLE resource_centres (
    centre_id INT AUTO_INCREMENT PRIMARY KEY,
    centre_name VARCHAR(150) NOT NULL,
    district_id INT NOT NULL,
    taluka_id INT,
    contact_number VARCHAR(20),
    centre_status VARCHAR(30) DEFAULT 'ACTIVE',
    FOREIGN KEY (district_id) REFERENCES districts(district_id),
    FOREIGN KEY (taluka_id) REFERENCES talukas(taluka_id)
);

-- 16. STOCK AVAILABLE AT EACH CENTRE
CREATE TABLE resource_stock (
    stock_id INT AUTO_INCREMENT PRIMARY KEY,
    centre_id INT NOT NULL,
    resource_id INT NOT NULL,
    quantity_available DECIMAL(12,2) DEFAULT 0,
    minimum_stock DECIMAL(12,2) DEFAULT 0,
    FOREIGN KEY (centre_id) REFERENCES resource_centres(centre_id),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id)
);

-- 17. RESOURCE REQUESTS FOR EACH INCIDENT
CREATE TABLE resource_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    incident_id INT NOT NULL,
    resource_id INT NOT NULL,
    quantity_required DECIMAL(12,2) NOT NULL,
    request_status VARCHAR(30) DEFAULT 'OPEN',
    request_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (incident_id) REFERENCES disaster_incidents(incident_id),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id)
);

-- 18. RESOURCE ALLOCATIONS
CREATE TABLE resource_allocations (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    incident_id INT NOT NULL,
    centre_id INT NOT NULL,
    resource_id INT NOT NULL,
    quantity_allocated DECIMAL(12,2) NOT NULL,
    allocation_status VARCHAR(30) DEFAULT 'PROPOSED',
    approved_by VARCHAR(100),
    allocation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (incident_id) REFERENCES disaster_incidents(incident_id),
    FOREIGN KEY (centre_id) REFERENCES resource_centres(centre_id),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id)
);

-- 19. SIMPLE ACTIVITY LOG
CREATE TABLE activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    activity VARCHAR(100),
    table_name VARCHAR(100),
    record_id INT,
    done_by VARCHAR(100),
    activity_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- =============================================================
-- MASTER DATA: INDIA, MAHARASHTRA AND 36 DISTRICTS
-- =============================================================
INSERT INTO countries (country_name) VALUES ('India');
INSERT INTO states (country_id, state_name) VALUES (1, 'Maharashtra');
INSERT INTO districts (state_id, district_name) VALUES
(1, 'Ahilyanagar'),
(1, 'Akola'),
(1, 'Amravati'),
(1, 'Beed'),
(1, 'Bhandara'),
(1, 'Buldhana'),
(1, 'Chandrapur'),
(1, 'Chhatrapati Sambhajinagar'),
(1, 'Dharashiv'),
(1, 'Dhule'),
(1, 'Gadchiroli'),
(1, 'Gondia'),
(1, 'Hingoli'),
(1, 'Jalgaon'),
(1, 'Jalna'),
(1, 'Kolhapur'),
(1, 'Latur'),
(1, 'Mumbai City'),
(1, 'Mumbai Suburban'),
(1, 'Nagpur'),
(1, 'Nanded'),
(1, 'Nandurbar'),
(1, 'Nashik'),
(1, 'Palghar'),
(1, 'Parbhani'),
(1, 'Pune'),
(1, 'Raigad'),
(1, 'Ratnagiri'),
(1, 'Sangli'),
(1, 'Satara'),
(1, 'Sindhudurg'),
(1, 'Solapur'),
(1, 'Thane'),
(1, 'Wardha'),
(1, 'Washim'),
(1, 'Yavatmal');

INSERT INTO talukas (district_id, taluka_name) VALUES
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Alibag') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Karjat') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Khalapur') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Mahad') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Mangaon') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Mhasala') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Murud') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Panvel') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Pen') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Poladpur') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Roha') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Shrivardhan') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Sudhagad') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Tala') ,
((SELECT district_id FROM districts WHERE district_name='Raigad'), 'Uran');

INSERT INTO disaster_types (disaster_name) VALUES
('Flood'),
('Landslide'),
('Heatwave'),
('Cyclone'),
('Lightning'),
('Earthquake'),
('Drought');

-- =============================================================
-- RAIGAD PILOT: 48 NAMED VERY-HIGH-PRIORITY LANDSLIDE LOCATIONS
-- Source: Maharashtra Landslide Management Plan 2024, Appendix 5.2.
-- Source spelling "Mahsala" is mapped to official taluka name "Mhasala".
-- =============================================================
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Neral', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Karjat' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 29.0176, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 308. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Neral' AND t.taluka_name='Karjat' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Tala', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Tala' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 28.4871, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 309. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Tala' AND t.taluka_name='Tala' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Wahal', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Panvel' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 27.2509, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 310. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Wahal' AND t.taluka_name='Panvel' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Boripakhadi', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Uran' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 27.1243, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 311. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Boripakhadi' AND t.taluka_name='Uran' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Khopoli', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Khalapur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 26.6817, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 312. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Khopoli' AND t.taluka_name='Khalapur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Rajpuri', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Murud' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 26.6637, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 313. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Rajpuri' AND t.taluka_name='Murud' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Matheran', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Karjat' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 26.0566, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 314. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Matheran' AND t.taluka_name='Karjat' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Poladpur', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Poladpur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 24.3972, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 315. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Poladpur' AND t.taluka_name='Poladpur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Dasgaon', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 22.8353, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 316. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Dasgaon' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Apte', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Panvel' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 19.9915, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 317. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Apte' AND t.taluka_name='Panvel' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Gavhan', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Panvel' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 19.1303, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 318. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Gavhan' AND t.taluka_name='Panvel' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Gherakilla Raigad (Raigadwadi)', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 19.1214, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 319. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Gherakilla Raigad (Raigadwadi)' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Mahad', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 18.1390, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 320. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Mahad' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Morba', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mangaon' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 17.0904, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 321. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Morba' AND t.taluka_name='Mangaon' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Pale', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 16.9375, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 322. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Pale' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Birwadi', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 16.8943, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 323. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Birwadi' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Pangaloli', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mhasala' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 15.9307, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 324. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Pangaloli' AND t.taluka_name='Mhasala' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Mandad', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Tala' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 15.0366, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 325. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Mandad' AND t.taluka_name='Tala' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Lower Tudil', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 14.8507, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 326. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Lower Tudil' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Jui', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Uran' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 14.7531, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 327. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Jui' AND t.taluka_name='Uran' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Jasai', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Uran' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 14.6579, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 328. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Jasai' AND t.taluka_name='Uran' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Chawane', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Panvel' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 14.4317, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 329. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Chawane' AND t.taluka_name='Panvel' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Nhave', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Panvel' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 14.2590, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 330. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Nhave' AND t.taluka_name='Panvel' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Roha (Gaulwadi)', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Roha' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 13.9490, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 331. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Roha (Gaulwadi)' AND t.taluka_name='Roha' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Devali', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mangaon' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 13.8839, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 332. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Devali' AND t.taluka_name='Mangaon' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Padum', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Roha' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 13.7802, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 333. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Padum' AND t.taluka_name='Roha' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Cholai', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Poladpur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 13.6208, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 334. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Cholai' AND t.taluka_name='Poladpur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Kapade Bk.', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Poladpur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 13.6081, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 335. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Kapade Bk.' AND t.taluka_name='Poladpur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Kasbe Pali', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Sudhagad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 13.0765, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 336. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Kasbe Pali' AND t.taluka_name='Sudhagad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Shrivardhan', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Shrivardhan' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 12.6241, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 337. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Shrivardhan' AND t.taluka_name='Shrivardhan' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Pachad', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 12.5919, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 338. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Pachad' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Vadval', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Khalapur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 12.5588, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 339. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Vadval' AND t.taluka_name='Khalapur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Honad', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Khalapur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 12.1770, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 340. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Honad' AND t.taluka_name='Khalapur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Durshet', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Khalapur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 11.8780, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 341. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Durshet' AND t.taluka_name='Khalapur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Kamble Tarf Birwadi', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 11.6513, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 342. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Kamble Tarf Birwadi' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Vaijali', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Alibag' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 11.4305, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 343. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Vaijali' AND t.taluka_name='Alibag' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Adoshi', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Khalapur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 11.3394, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 344. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Adoshi' AND t.taluka_name='Khalapur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Waral', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mhasala' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 11.0580, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 345. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Waral' AND t.taluka_name='Mhasala' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Kondhawi', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Poladpur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.8075, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 346. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Kondhawi' AND t.taluka_name='Poladpur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Kalsuri', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mhasala' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.7243, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 347. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Kalsuri' AND t.taluka_name='Mhasala' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Murud (rural)', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Murud' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.6439, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 348. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Murud (rural)' AND t.taluka_name='Murud' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Shil', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Khalapur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.5819, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 349. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Shil' AND t.taluka_name='Khalapur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Killa', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Roha' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.5454, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 350. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Killa' AND t.taluka_name='Roha' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Kaire', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Khalapur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.4976, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 351. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Kaire' AND t.taluka_name='Khalapur' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Talavade', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mhasala' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.4748, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 352. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Talavade' AND t.taluka_name='Mhasala' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Devaghar', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Shrivardhan' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.4555, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 353. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Devaghar' AND t.taluka_name='Shrivardhan' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Wahoor', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Mahad' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.2447, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 354. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Wahoor' AND t.taluka_name='Mahad' AND d.district_name='Raigad';
INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
SELECT taluka_id, 'Lohare', 'VILLAGE_OR_LOCALITY', 1
FROM talukas WHERE taluka_name='Poladpur' AND district_id=(SELECT district_id FROM districts WHERE district_name='Raigad');
INSERT INTO hazard_records (location_id, district_id, disaster_type_id, risk_level, susceptible_area_hectares, source_name, source_year, source_note)
SELECT l.location_id, d.district_id, dt.disaster_type_id, 'VERY_HIGH', 10.2123, 'Maharashtra Landslide Management Plan 2024 - Appendix 5.2', '2024', 'Source row 355. Susceptible area in hectares; not the total area of the village.'
FROM locations l
JOIN talukas t ON l.taluka_id=t.taluka_id
JOIN districts d ON t.district_id=d.district_id
JOIN disaster_types dt ON dt.disaster_name='Landslide'
WHERE l.location_name='Lohare' AND t.taluka_name='Poladpur' AND d.district_name='Raigad';

-- =============================================================
-- RESOURCE CATALOGUE (ITEM NAMES ONLY; NO INVENTED STOCK QUANTITIES)
-- =============================================================
INSERT INTO resources (resource_name, unit_name) VALUES
('Drinking Water','litres'),
('Food Packet','packets'),
('First Aid Kit','kits'),
('Medical Kit','kits'),
('Blanket','pieces'),
('Rescue Boat','units'),
('Life Jacket','pieces'),
('Ambulance','vehicles'),
('Rescue Vehicle','vehicles'),
('Temporary Shelter','units'),
('Torch','pieces'),
('Generator','units');

-- =============================================================
-- BASIC CHECK QUERIES
-- Run these after executing the script.
-- =============================================================

-- 1. Count districts (expected: 36)
SELECT COUNT(*) AS total_districts FROM districts;

-- 2. Show all districts
SELECT district_name FROM districts ORDER BY district_name;

-- 3. Show Raigad talukas (expected: 15)
SELECT t.taluka_name
FROM talukas t
JOIN districts d ON t.district_id = d.district_id
WHERE d.district_name = 'Raigad'
ORDER BY t.taluka_name;

-- 4. Show Raigad landslide-priority locations
SELECT d.district_name, t.taluka_name, l.location_name,
       h.risk_level, h.susceptible_area_hectares
FROM hazard_records h
JOIN locations l ON h.location_id = l.location_id
JOIN talukas t ON l.taluka_id = t.taluka_id
JOIN districts d ON t.district_id = d.district_id
WHERE d.district_name = 'Raigad'
ORDER BY t.taluka_name, l.location_name;

-- 5. Count named Raigad landslide-priority records (expected: 48)
SELECT COUNT(*) AS raigad_landslide_locations
FROM hazard_records h
JOIN locations l ON h.location_id = l.location_id
JOIN talukas t ON l.taluka_id = t.taluka_id
JOIN districts d ON t.district_id = d.district_id
WHERE d.district_name = 'Raigad' AND h.risk_level = 'VERY_HIGH';

-- =============================================================
-- COMMON SQL QUERIES YOU WILL USE IN THE PROJECT
-- =============================================================

-- A. Add a new location after checking its taluka exists.
-- Replace the values with verified real data.
-- INSERT INTO locations (taluka_id, location_name, location_type, is_verified)
-- VALUES (1, 'Example Village', 'VILLAGE', 0);

-- B. Add a new disaster incident.
-- First find the IDs using SELECT queries, then insert the incident.
-- INSERT INTO disaster_incidents
-- (incident_code, district_id, taluka_id, location_id, disaster_type_id,
--  incident_date, severity, affected_people, description, reported_by)
-- VALUES
-- ('MH-RAI-0001', 27, 1, NULL, 1, NOW(), 'HIGH', 100,
--  'Training example only - replace with verified incident details', 'Operator');
-- NOTE: The example is commented out and is NOT inserted as a real incident.

-- C. View incidents with their district, taluka, location and disaster type.
SELECT i.incident_id, i.incident_code, d.district_name, t.taluka_name,
       l.location_name, dt.disaster_name, i.incident_date,
       i.severity, i.affected_people, i.incident_status
FROM disaster_incidents i
JOIN districts d ON i.district_id = d.district_id
LEFT JOIN talukas t ON i.taluka_id = t.taluka_id
LEFT JOIN locations l ON i.location_id = l.location_id
JOIN disaster_types dt ON i.disaster_type_id = dt.disaster_type_id
ORDER BY i.incident_date DESC;

-- D. Find incidents in one district (change district name as needed).
SELECT i.*
FROM disaster_incidents i
JOIN districts d ON i.district_id = d.district_id
WHERE d.district_name = 'Raigad';

-- E. Count incidents by disaster type.
SELECT dt.disaster_name, COUNT(i.incident_id) AS total_incidents
FROM disaster_types dt
LEFT JOIN disaster_incidents i ON dt.disaster_type_id = i.disaster_type_id
GROUP BY dt.disaster_type_id, dt.disaster_name
ORDER BY total_incidents DESC;

-- F. Count incidents by district.
SELECT d.district_name, COUNT(i.incident_id) AS total_incidents
FROM districts d
LEFT JOIN disaster_incidents i ON d.district_id = i.district_id
GROUP BY d.district_id, d.district_name
ORDER BY total_incidents DESC;

-- G. View risk assessment history for incidents.
SELECT i.incident_code, r.risk_score, r.risk_category,
       r.factors_used, r.assessment_date
FROM risk_assessments r
JOIN disaster_incidents i ON r.incident_id = i.incident_id
ORDER BY r.assessment_date DESC;

-- H. Add a risk assessment result calculated by Python.
-- INSERT INTO risk_assessments
-- (incident_id, risk_score, risk_category, factors_used)
-- VALUES (1, 85, 'CRITICAL', 'Example only: replace with Python-calculated factors');

-- I. View rescue teams and their base location.
SELECT rt.team_id, rt.team_name, d.district_name, t.taluka_name,
       rt.team_size, rt.team_status, rt.contact_number
FROM rescue_teams rt
JOIN districts d ON rt.district_id = d.district_id
LEFT JOIN talukas t ON rt.taluka_id = t.taluka_id;

-- J. Find available teams.
SELECT * FROM rescue_teams WHERE team_status = 'AVAILABLE';

-- K. View team capabilities.
SELECT rt.team_name, dt.disaster_name, tc.skill_description
FROM team_capabilities tc
JOIN rescue_teams rt ON tc.team_id = rt.team_id
JOIN disaster_types dt ON tc.disaster_type_id = dt.disaster_type_id;

-- L. View resource stock by centre.
SELECT rc.centre_name, d.district_name, r.resource_name,
       rs.quantity_available, r.unit_name
FROM resource_stock rs
JOIN resource_centres rc ON rs.centre_id = rc.centre_id
JOIN districts d ON rc.district_id = d.district_id
JOIN resources r ON rs.resource_id = r.resource_id
ORDER BY rc.centre_name, r.resource_name;

-- M. Find resources whose stock is at or below the minimum level.
SELECT rc.centre_name, r.resource_name,
       rs.quantity_available, rs.minimum_stock
FROM resource_stock rs
JOIN resource_centres rc ON rs.centre_id = rc.centre_id
JOIN resources r ON rs.resource_id = r.resource_id
WHERE rs.quantity_available <= rs.minimum_stock;

-- N. View resource requests for each incident.
SELECT i.incident_code, r.resource_name, rq.quantity_required,
       r.unit_name, rq.request_status
FROM resource_requests rq
JOIN disaster_incidents i ON rq.incident_id = i.incident_id
JOIN resources r ON rq.resource_id = r.resource_id;

-- O. View team allocation proposals and their approval status.
SELECT i.incident_code, rt.team_name, ta.distance_km,
       ta.assignment_status, ta.approved_by
FROM team_assignments ta
JOIN disaster_incidents i ON ta.incident_id = i.incident_id
JOIN rescue_teams rt ON ta.team_id = rt.team_id;

-- P. View resource allocation proposals.
SELECT i.incident_code, rc.centre_name, r.resource_name,
       ra.quantity_allocated, r.unit_name, ra.allocation_status
FROM resource_allocations ra
JOIN disaster_incidents i ON ra.incident_id = i.incident_id
JOIN resource_centres rc ON ra.centre_id = rc.centre_id
JOIN resources r ON ra.resource_id = r.resource_id;

-- Q. Update incident status after verification / response.
-- UPDATE disaster_incidents SET incident_status = 'VERIFIED'
-- WHERE incident_id = 1;

-- R. Update team status after approved deployment.
-- UPDATE rescue_teams SET team_status = 'DEPLOYED' WHERE team_id = 1;

-- S. Update stock after an approved and physically confirmed issue.
-- UPDATE resource_stock SET quantity_available = quantity_available - 50
-- WHERE centre_id = 1 AND resource_id = 1
-- AND quantity_available >= 50;
-- Always check the affected row count and stock before confirming issue.

-- T. View incident updates.
SELECT i.incident_code, u.status_name, u.update_description,
       u.updated_by, u.update_date
FROM incident_updates u
JOIN disaster_incidents i ON u.incident_id = i.incident_id
ORDER BY u.update_date DESC;

-- U. View activity log.
SELECT * FROM activity_logs ORDER BY activity_date DESC;

-- V. Add a new disaster type if required.
-- INSERT INTO disaster_types (disaster_name) VALUES ('Tsunami');

-- W. Important: do not delete closed incidents. Keep them as history.
-- Use UPDATE to change status; delete only incorrect test records after checking.

-- END OF DATABASE SCRIPT
show tables;
select district_id, district_name from districts where district_name="Raigad";
describe rescue_teams;
insert into  rescue_teams
(team_name, district_id, team_size, team_status, contact_number)
values
('demo rescue team', 27, 5, 'AVAILABLE','9900580058');
select * from resource_stock;
select * from resource_centres;
describe resource_centres;
select rc.centre_name, r.resource_name, rs.quantity_available, r.unit_name
from resource_stock rs join resource_centres rc on rs.centre_id = rs.centre_id
join resources r on rs.resource_id = r.resource_id;
select * from resource_stock where centre_id = 1;
insert into resource_centres(centre_name, district_id, contact_number, centre_status) values ('Demo Resourse Centre',27,'9900580058','ACTIVE');
select resource_id, resource_name from resources;
insert into resource_stock(centre_id, resource_id, quantity_available, minimum_stock)
values (1,1,1000,100);
select * from resource_stock;



