-- clinic_booking_system.sql
-- Clinic Booking System schema
-- Date: 2025-09-15

DROP DATABASE IF EXISTS `clinic_booking`;
CREATE DATABASE `clinic_booking` CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
USE `clinic_booking`;

-- -----------------------------------------------------
-- Table: countries (lookup)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `countries`;
CREATE TABLE `countries` (
  `country_id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `iso_code` CHAR(3) NULL,
  PRIMARY KEY (`country_id`),
  UNIQUE KEY `uq_countries_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: clinics
-- Each physical clinic/branch (Kenya, South Africa, Nigeria)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `clinics`;
CREATE TABLE `clinics` (
  `clinic_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `address` VARCHAR(255) NULL,
  `city` VARCHAR(100) NULL,
  `country_id` SMALLINT UNSIGNED NOT NULL,
  `phone` VARCHAR(30) NULL,
  `email` VARCHAR(120) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`clinic_id`),
  CONSTRAINT `fk_clinic_country` FOREIGN KEY (`country_id`) REFERENCES `countries` (`country_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: users (staff / system users)
-- One-to-one-ish with staff when role = 'doctor'/'receptionist' etc.
-- -----------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(80) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `email` VARCHAR(150) NOT NULL,
  `full_name` VARCHAR(150) NULL,
  `role` ENUM('admin','doctor','nurse','receptionist','lab_technician','accountant') NOT NULL DEFAULT 'receptionist',
  `clinic_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_users_username` (`username`),
  UNIQUE KEY `uq_users_email` (`email`),
  CONSTRAINT `fk_users_clinic` FOREIGN KEY (`clinic_id`) REFERENCES `clinics` (`clinic_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: doctors (if you want doctor-specific metadata)
-- One-to-one relation with users (optional): user_id may be NULL for external doctors
-- -----------------------------------------------------
DROP TABLE IF EXISTS `doctors`;
CREATE TABLE `doctors` (
  `doctor_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NULL,               -- optional link to users table
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `license_number` VARCHAR(60) NULL,
  `phone` VARCHAR(30) NULL,
  `email` VARCHAR(150) NULL,
  `clinic_id` INT UNSIGNED NULL,
  `bio` TEXT NULL,
  PRIMARY KEY (`doctor_id`),
  UNIQUE KEY `uq_doctors_license` (`license_number`),
  CONSTRAINT `fk_doctors_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_doctors_clinic` FOREIGN KEY (`clinic_id`) REFERENCES `clinics` (`clinic_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: specialties (list of doctor specialties)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `specialties`;
CREATE TABLE `specialties` (
  `specialty_id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`specialty_id`),
  UNIQUE KEY `uq_specialties_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: doctor_specialties (many-to-many doctors <-> specialties)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `doctor_specialties`;
CREATE TABLE `doctor_specialties` (
  `doctor_id` INT UNSIGNED NOT NULL,
  `specialty_id` SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (`doctor_id`, `specialty_id`),
  CONSTRAINT `fk_ds_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ds_specialty` FOREIGN KEY (`specialty_id`) REFERENCES `specialties` (`specialty_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: patients
-- -----------------------------------------------------
DROP TABLE IF EXISTS `patients`;
CREATE TABLE `patients` (
  `patient_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `dob` DATE NULL,
  `gender` ENUM('male','female','other') NULL,
  `phone` VARCHAR(30) NULL,
  `email` VARCHAR(150) NULL,
  `address` VARCHAR(255) NULL,
  `city` VARCHAR(100) NULL,
  `country_id` SMALLINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`patient_id`),
  UNIQUE KEY `uq_patients_email` (`email`),
  CONSTRAINT `fk_patients_country` FOREIGN KEY (`country_id`) REFERENCES `countries`(`country_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: patient_conditions (many-to-many: patients <-> chronic conditions)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conditions`;
CREATE TABLE `conditions` (
  `condition_id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  PRIMARY KEY (`condition_id`),
  UNIQUE KEY `uq_condition_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `patient_conditions`;
CREATE TABLE `patient_conditions` (
  `patient_id` INT UNSIGNED NOT NULL,
  `condition_id` SMALLINT UNSIGNED NOT NULL,
  `diagnosed_at` DATE NULL,
  PRIMARY KEY (`patient_id`, `condition_id`),
  CONSTRAINT `fk_pc_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pc_condition` FOREIGN KEY (`condition_id`) REFERENCES `conditions` (`condition_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: appointment_statuses (lookup)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `appointment_statuses`;
CREATE TABLE `appointment_statuses` (
  `status_id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`status_id`),
  UNIQUE KEY `uq_status_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `appointment_statuses` (`name`) VALUES ('scheduled'), ('checked_in'), ('completed'), ('cancelled'), ('no_show');

-- -----------------------------------------------------
-- Table: appointments
-- One-to-many: patient -> appointments, doctor -> appointments
-- -----------------------------------------------------
DROP TABLE IF EXISTS `appointments`;
CREATE TABLE `appointments` (
  `appointment_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `doctor_id` INT UNSIGNED NULL,
  `clinic_id` INT UNSIGNED NOT NULL,
  `scheduled_start` DATETIME NOT NULL,
  `scheduled_end` DATETIME NULL,
  `status_id` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- scheduled
  `reason` VARCHAR(255) NULL,
  `created_by` INT UNSIGNED NULL, -- user_id who created
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`appointment_id`),
  INDEX `idx_appointments_patient` (`patient_id`),
  INDEX `idx_appointments_doctor` (`doctor_id`),
  CONSTRAINT `fk_appointments_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_appointments_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_appointments_clinic` FOREIGN KEY (`clinic_id`) REFERENCES `clinics` (`clinic_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_appointments_status` FOREIGN KEY (`status_id`) REFERENCES `appointment_statuses` (`status_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_appointments_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: treatments (catalog of services)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `treatments`;
CREATE TABLE `treatments` (
  `treatment_id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `base_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`treatment_id`),
  UNIQUE KEY `uq_treatment_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: appointment_treatments (many-to-many: appointment <-> treatments)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `appointment_treatments`;
CREATE TABLE `appointment_treatments` (
  `appointment_id` BIGINT UNSIGNED NOT NULL,
  `treatment_id` SMALLINT UNSIGNED NOT NULL,
  `quantity` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`appointment_id`, `treatment_id`),
  CONSTRAINT `fk_at_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`appointment_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_at_treatment` FOREIGN KEY (`treatment_id`) REFERENCES `treatments` (`treatment_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: prescriptions
-- -----------------------------------------------------
DROP TABLE IF EXISTS `prescriptions`;
CREATE TABLE `prescriptions` (
  `prescription_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `appointment_id` BIGINT UNSIGNED NOT NULL,
  `doctor_id` INT UNSIGNED NOT NULL,
  `notes` TEXT NULL,
  `issued_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`prescription_id`),
  CONSTRAINT `fk_prescriptions_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`appointment_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_prescriptions_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: medicines (inventory)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `medicines`;
CREATE TABLE `medicines` (
  `medicine_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `brand` VARCHAR(100) NULL,
  `unit` VARCHAR(32) NULL,
  `stock_qty` INT NOT NULL DEFAULT 0,
  `reorder_level` INT NOT NULL DEFAULT 10,
  PRIMARY KEY (`medicine_id`),
  UNIQUE KEY `uq_medicine_name_brand` (`name`,`brand`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: prescription_items (many-to-many prescriptions <-> medicines)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `prescription_items`;
CREATE TABLE `prescription_items` (
  `prescription_id` BIGINT UNSIGNED NOT NULL,
  `medicine_id` INT UNSIGNED NOT NULL,
  `dose` VARCHAR(80) NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`prescription_id`, `medicine_id`),
  CONSTRAINT `fk_pi_prescription` FOREIGN KEY (`prescription_id`) REFERENCES `prescriptions` (`prescription_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pi_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `medicines` (`medicine_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: payments
-- One-to-many: appointment -> payments (could be partial payments)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
  `payment_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `appointment_id` BIGINT UNSIGNED NOT NULL,
  `paid_amount` DECIMAL(10,2) NOT NULL,
  `method` ENUM('cash','card','mobile_money','bank_transfer') NOT NULL DEFAULT 'cash',
  `paid_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reference` VARCHAR(100) NULL,
  PRIMARY KEY (`payment_id`),
  CONSTRAINT `fk_payments_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`appointment_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Useful indexes for queries (scheduling, availability)
-- -----------------------------------------------------
CREATE INDEX `idx_appointments_schedule_clinic` ON `appointments` (`clinic_id`, `scheduled_start`);
CREATE INDEX `idx_appointments_schedule_doctor` ON `appointments` (`doctor_id`, `scheduled_start`);

-- -----------------------------------------------------
-- Example view: upcoming_appointments_by_clinic (optional)
-- -----------------------------------------------------
DROP VIEW IF EXISTS `view_upcoming_appointments`;
CREATE VIEW `view_upcoming_appointments` AS
SELECT
  a.appointment_id,
  a.scheduled_start,
  a.scheduled_end,
  a.status_id,
  s.name AS status_name,
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.doctor_id,
  CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
  a.clinic_id
FROM appointments a
LEFT JOIN appointment_statuses s ON a.status_id = s.status_id
LEFT JOIN patients p ON a.patient_id = p.patient_id
LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
WHERE a.scheduled_start >= NOW();

-- -----------------------------------------------------
-- Example stored procedure to create an appointment (simple checks)
-- (Optional - demonstrates business logic in DB)
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS `sp_create_appointment`;
DELIMITER $$
CREATE PROCEDURE `sp_create_appointment` (
  IN in_patient_id INT UNSIGNED,
  IN in_doctor_id INT UNSIGNED,
  IN in_clinic_id INT UNSIGNED,
  IN in_start DATETIME,
  IN in_end DATETIME,
  OUT out_appointment_id BIGINT UNSIGNED
)
BEGIN
  DECLARE conflict_count INT DEFAULT 0;

  -- Basic check: doctor availability overlap
  IF in_doctor_id IS NOT NULL THEN
    SELECT COUNT(*) INTO conflict_count
    FROM appointments
    WHERE doctor_id = in_doctor_id
      AND status_id IN (1,2) -- scheduled, checked_in
      AND ( (scheduled_start < in_end AND scheduled_end > in_start) OR (scheduled_end IS NULL AND scheduled_start = in_start) );

    IF conflict_count > 0 THEN
      SET out_appointment_id = 0; -- signal conflict
      LEAVE proc_end;
    END IF;
  END IF;

  -- Insert appointment
  INSERT INTO appointments (patient_id, doctor_id, clinic_id, scheduled_start, scheduled_end)
  VALUES (in_patient_id, in_doctor_id, in_clinic_id, in_start, in_end);

  SET out_appointment_id = LAST_INSERT_ID();

  proc_end: BEGIN END;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Seed some lookup data (countries and a sample clinic)
-- -----------------------------------------------------
INSERT INTO `countries` (`name`, `iso_code`)
VALUES ('Kenya', 'KEN'), ('South Africa', 'ZAF'), ('Nigeria', 'NGA');

INSERT INTO `clinics` (`name`, `address`, `city`, `country_id`, `phone`, `email`)
VALUES ('ManRutz Nairobi Clinic', '123 Tech Ave', 'Nairobi', (SELECT country_id FROM countries WHERE name='Kenya'), '+254700000000', 'nairobi@manrutz.example'),
       ('ManRutz Johannesburg Clinic', '45 Innovation St', 'Johannesburg', (SELECT country_id FROM countries WHERE name='South Africa'), '+27110000000', 'joburg@manrutz.example'),
       ('ManRutz Lagos Clinic', '9 Startup Rd', 'Lagos', (SELECT country_id FROM countries WHERE name='Nigeria'), '+2341000000000', 'lagos@manrutz.example');

-- -----------------------------------------------------
-- Seed Doctors
-- -----------------------------------------------------
INSERT INTO doctors (first_name, last_name, license_number, phone, email, clinic_id, bio)
VALUES
('James', 'Mwangi', 'KEN12345', '+254701111111', 'jmwangi@manrutz.org', 1, 'Specialist in General Medicine'),
('Thandi', 'Nkosi', 'ZAF56789', '+27112223333', 'tnkosi@manrutz.org', 2, 'Cardiologist with 10 years of experience'),
('Adebayo', 'Okeke', 'NGA98765', '+2348033334444', 'aokeke@manrutz.org', 3, 'Expert in Pediatrics'),
('Susan', 'Kariuki', 'KEN22222', '+254702222222', 'skariuki@manrutz.org', 1, 'Dermatology and skin care'),
('Michael', 'Dlamini', 'ZAF33333', '+27114445555', 'mdlamini@manrutz.org', 2, 'Orthopedic Surgeon');

-- -----------------------------------------------------
-- Seed Patients
-- -----------------------------------------------------
INSERT INTO patients (first_name, last_name, dob, gender, phone, email, address, city, country_id)
VALUES
('John', 'Roi', '1990-05-14', 'male', '+254711111111', 'john.roi@yahoo.com', '12 Garden Rd', 'Nairobi', 1),
('Mary', 'Wanjiku', '1985-07-20', 'female', '+254722222222', 'mary.wanjiku@gmail.com', '45 Market St', 'Nakuru', 1),
('Peter', 'Kinuthia', '1978-09-10', 'male', '+254733333333', 'peter.kinuthia@gmail.com', '7 River Lane', 'Kisumu', 1),
('Sipho', 'Mthembu', '1992-01-05', 'male', '+27110001111', 'sipho.m@example.com', '89 Hillcrest Ave', 'Johannesburg', 2),
('Lerato', 'Ruleh', '1989-11-18', 'female', '+27112223333', 'lerato.ruleh@yahoo.com', '23 Mandela St', 'Pretoria', 2),
('Precious', 'Ndlovu', '1995-03-30', 'female', '+27113334444', 'precious.ndlovu@gmail.com', '78 Rosebank Dr', 'Durban', 2),
('Chinedu', 'Obikenu', '1980-12-25', 'male', '+2348011111111', 'chinedu.obikenu@gmail.com', '5 Victoria Island', 'Lagos', 3),
('Ngozi', 'Okafor', '1994-06-08', 'female', '+2348022222222', 'ngozi.okafor@gmail.com', '12 Lekki Phase 1', 'Abuja', 3),
('Emeka', 'Adeyemi', '1987-02-14', 'male', '+2348033333333', 'emeka.adeyemi@gmail.com', '67 Ikeja Rd', 'Lagos', 3),
('Aisha', 'Mohammed', '1999-09-09', 'female', '+2348044444444', 'aisha.mohammed@yahoo.com', '34 Kano Crescent', 'Kano', 3);

-- -----------------------------------------------------
-- Seed Appointments
-- Assume status_id = 1 (scheduled), 2 (checked_in), 3 (completed), etc.
-- -----------------------------------------------------
INSERT INTO appointments (patient_id, doctor_id, clinic_id, scheduled_start, scheduled_end, status_id, reason, created_by)
VALUES
(1, 1, 1, '2025-09-20 09:00:00', '2025-09-20 09:30:00', 1, 'General check-up', NULL),
(2, 4, 1, '2025-09-20 10:00:00', '2025-09-20 10:30:00', 1, 'Skin rash consultation', NULL),
(3, 1, 1, '2025-09-21 11:00:00', '2025-09-21 11:45:00', 1, 'High blood pressure follow-up', NULL),
(4, 2, 2, '2025-09-22 14:00:00', '2025-09-22 14:30:00', 1, 'Cardiology consultation', NULL),
(5, 2, 2, '2025-09-22 15:00:00', '2025-09-22 15:45:00', 1, 'Chest pains diagnosis', NULL),
(6, 5, 2, '2025-09-23 09:30:00', '2025-09-23 10:15:00', 1, 'Knee injury check', NULL),
(7, 3, 3, '2025-09-24 13:00:00', '2025-09-24 13:45:00', 1, 'Child vaccination', NULL),
(8, 3, 3, '2025-09-24 14:30:00', '2025-09-24 15:00:00', 1, 'Fever and flu symptoms', NULL),
(9, 3, 3, '2025-09-25 09:00:00', '2025-09-25 09:30:00', 1, 'Annual health screening', NULL),
(10, 3, 3, '2025-09-25 10:00:00', '2025-09-25 10:30:00', 1, 'Allergy diagnosis', NULL);
