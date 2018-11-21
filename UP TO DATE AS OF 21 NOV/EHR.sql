-- phpMyAdmin SQL Dump
-- version 4.8.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Nov 21, 2018 at 11:59 PM
-- Server version: 10.1.34-MariaDB
-- PHP Version: 7.2.8

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `EHR`
--
CREATE DATABASE IF NOT EXISTS `EHR` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `EHR`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `clear_doctor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_doctor` ()  SELECT MAX(doctor_id)+1,' 'as '1', ' ' as '2', ' ' as '3', ' ' as '4'
FROM doctor$$

DROP PROCEDURE IF EXISTS `clear_patient`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_patient` ()  BEGIN
START TRANSACTION ;
SELECT Max(patient_id) + 1, ' ' AS '1', ' ' AS '2', ' ' AS '3' , ' ' AS '4', ' ' AS '5', ' ' AS '6', ' ' AS '7', ' ' AS '8', ' ' AS '9'
FROM patient
COMMIT;
END$$

DROP PROCEDURE IF EXISTS `count_patients_by_age`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `count_patients_by_age` ()  SELECT YEAR(CURRENT_TIMESTAMP)-YEAR(date_of_birth)-(RIGHT(CURRENT_TIMESTAMP, 5)<RIGHT(date_of_birth, 5)) as age, 
    COUNT(YEAR(CURRENT_TIMESTAMP) - YEAR(date_of_birth) - (RIGHT(CURRENT_TIMESTAMP, 5) < RIGHT(date_of_birth, 5)))
    FROM patient
    GROUP BY age$$

DROP PROCEDURE IF EXISTS `count_patients_by_sex`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `count_patients_by_sex` ()  SELECT sex, COUNT(sex)
    FROM patient
    GROUP BY sex$$

DROP PROCEDURE IF EXISTS `create_consult`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_consult` (IN `in_patient_id` INT, IN `in_doctor_id` INT, IN `in_peea` VARCHAR(100), IN `in_consult_schedule` CHAR(5), IN `in_consult_date` DATE)  BEGIN
START TRANSACTION;
INSERT INTO consult (patient_id,doctor_id,peea,consult_schedule,consult_date) 
	VALUES(
        in_patient_id,
        in_doctor_id,
        in_peea,
        in_consult_schedule,
        in_consult_date
		);

SELECT consult_id,consult_schedule, consult_date, peea
FROM consult
ORDER BY consult_id DESC;


COMMIT;
END$$

DROP PROCEDURE IF EXISTS `create_doctor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_doctor` (IN `in_doctor_id` INT, IN `in_first_name` VARCHAR(20), IN `in_last_name` VARCHAR(20), IN `in_phone` VARCHAR(15), IN `in_license` VARCHAR(8))  BEGIN       
START TRANSACTION;
       INSERT INTO doctor VALUES(in_doctor_id,in_license, in_first_name, in_last_name, in_phone );
       SELECT * 
       FROM doctor
       WHERE doctor.doctor_id = in_doctor_id;
COMMIT;
END$$

DROP PROCEDURE IF EXISTS `create_patient`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_patient` (IN `in_patient_id` INT, IN `in_first_name` VARCHAR(20), IN `in_last_name` VARCHAR(20), IN `in_sex` CHAR(1), IN `in_rfc` VARCHAR(13), IN `in_phone` VARCHAR(15), IN `in_city` VARCHAR(20), IN `in_street_address` VARCHAR(50), IN `in_email` VARCHAR(30), IN `in_date_of_birth` DATE)  BEGIN
START TRANSACTION;
INSERT INTO patient
	VALUES(
        in_patient_id,
		in_first_name,
		in_last_name,
		in_sex,
		in_rfc,
		in_phone,
		in_city,
		in_street_address,
		in_email,
		in_date_of_birth
		);

	SELECT *
	FROM patient
	WHERE patient_id = in_patient_id;
COMMIT;
END$$

DROP PROCEDURE IF EXISTS `create_prescription_id`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_prescription_id` (IN `in_consult_id` INT)  BEGIN
START TRANSACTION;
INSERT INTO prescription(consult_id) VALUES(in_consult_id);

SELECT prescription_id
FROM prescription
ORDER BY prescription_id DESC;
COMMIT;
END$$

DROP PROCEDURE IF EXISTS `create_recipe`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_recipe` (IN `in_prescription_id` INT, IN `in_medicine_id` INT, IN `in_instructions` VARCHAR(40))  BEGIN
START TRANSACTION;
INSERT INTO recipe VALUES(in_medicine_id, in_prescription_id, in_instructions);

SELECT Instructions
FROM recipe
WHERE medicine_id = in_medicine_id AND prescription_id = in_prescription_id;

COMMIT;
END$$

DROP PROCEDURE IF EXISTS `delete_doctor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_doctor` (IN `in_doctor_id` INT)  BEGIN
START TRANSACTION;
DELETE FROM consult
WHERE consult.doctor_id = in_doctor_id;

DELETE FROM doctor
WHERE doctor.doctor_id = in_doctor_id;

SELECT Max(doctor_id) + 1, ' ' AS '1', ' ' AS '2', ' ' AS '3' , ' ' AS '4'
FROM doctor;

COMMIT;
END$$

DROP PROCEDURE IF EXISTS `delete_patient`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_patient` (IN `in_patient_id` INT)  BEGIN
START TRANSACTION;
/* 1. Borrar respuestas del paciente de consultas donde el paciente es in_patient_id */
	DELETE FROM answer
	WHERE instance_id IN (
						  SELECT instance_id 
						  FROM test_instance
						  WHERE consult_id IN (
							  				   SELECT consult_id
						  					   FROM consult
											   WHERE patient_id = in_patient_id
											  )
						 );
/*2.Borrar consultas de test_instance donde el paciente es in_patient_id*/
DELETE FROM test_instance
WHERE consult_id IN (
					 SELECT consult_id
					 FROM consult
					 WHERE patient_id = in_patient_id
					);

/* 3.Borrar de la tabla Detalles_Med */
DELETE FROM recipe
WHERE prescription_id IN (
						  SELECT prescription_id
                          FROM prescription
						  WHERE consult_id IN (
							  				   SELECT consult_id
						  					   FROM consult
											   WHERE patient_id = in_patient_id
											  )
						 );

/* 4.Borrar de la tabla prescription todas las consultas donde el paciente es in_patient_id*/
DELETE FROM prescription
WHERE consult_id IN (
					 SELECT consult_id
					 FROM consult
					 WHERE patient_id = in_patient_id
					);

/* 5. Borrar consultas del diagnostico donde el paciente es in_patient_id*/ 
DELETE FROM diagnostic
WHERE consult_id IN (
					 SELECT consult_id
					 FROM consult
					 WHERE patient_id = in_patient_id
					);

/* 6. Borrar de la tabla consultas donde el paciente es in_patient_id*/
	DELETE FROM consult
	WHERE patient_id = in_patient_id;

/* 7. Borrar de la tabla paciente donde el paciente es in_patient_id */
	DELETE FROM patient
	WHERE patient_id = in_patient_id;	

	SELECT Max(patient_id) + 1, ' ' AS '1', ' ' AS '2', ' ' AS '3' , ' ' AS '4', ' ' AS '5', ' ' AS '6', ' ' AS '7', ' ' AS '8', ' ' AS '9'
	FROM patient;
COMMIT;
END$$

DROP PROCEDURE IF EXISTS `delete_patient_by_name`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_patient_by_name` (IN `in_first_name` VARCHAR(20))  BEGIN
/* 1. Borrar respuestas del paciente de consultas donde el paciente es in_first_name */
	DELETE FROM answer
	WHERE instance_id = ANY(
		SELECT ti.instance_id
		FROM consult c JOIN test_instance ti ON c.consult_id = ti.consult_id
		WHERE first_name = in_first_name);
/*2.Borrar consultas de test_instance donde el paciente es in_first_name*/
DELETE FROM test_instance
	WHERE consult_id = ANY (
		SELECT consult_id
		FROM consult
		WHERE first_name = in_first_name
	);

/* 3.Borrar de la tabla Detalles_Med */
DELETE FROM recipe
WHERE prescription_id = ANY(
	SELECT p.prescription_id
	FROM consult c JOIN prescription p ON c.prescription_id = p.prescription_id
	WHERE c.first_name = in_first_name);

/* 4.Borrar de la tabla prescription todas las consultas donde el paciente es in_first_name*/
DELETE FROM prescription
WHERE consult_id = ANY(
	SELECT c.consult_id
	FROM consult c
	WHERE c.first_name = in_first_name
	);

/* 5. Borrar consultas del diagnostico donde el paciente es in_first_name*/ 
DELETE FROM diagnostic
WHERE consult_id = ANY(
	SELECT c.consult_id
	FROM consult c
	WHERE c.first_name = in_first_name
	);
/* 6. Borrar de la tabla consultas donde el paciente es in_first_name*/
	DELETE FROM consult
	WHERE first_name = in_first_name;

/* 7. Borrar de la tabla paciente donde el paciente es in_first_name */
	DELETE FROM patient
	WHERE first_name = in_first_name;
	END$$

DROP PROCEDURE IF EXISTS `get_all_patients`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_patients` ()  SELECT * FROM patient$$

DROP PROCEDURE IF EXISTS `get_consult_by_dates`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_consult_by_dates` (IN `in_start_date` DATE, IN `in_end_date` DATE)  SELECT consult.consult_id AS 'Consulta', concat(doctor.first_name," ",doctor.last_name) AS 'Doctor',concat(patient.first_name," ",patient.last_name) AS 'Patient', peea AS 'Motivo de consulta', consult_date AS 'Fecha de consulta', description AS 'Descripción de diagnóstico'
    FROM doctor
    JOIN consult ON doctor.doctor_id = consult.doctor_id
    JOIN patient ON consult.patient_id = patient.patient_id
    JOIN diagnostic ON consult.consult_id = diagnostic.consult_id
    JOIN disease_catalog ON diagnostic.disease_catalog_id = disease_catalog.disease_catalog_id
    WHERE consult_date > in_start_date AND consult_date < in_end_date
    ORDER BY COUNT(consult.consult_id) DESC$$

DROP PROCEDURE IF EXISTS `get_consult_by_dates_doctor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_consult_by_dates_doctor` (IN `in_start_date` DATE, IN `in_end_date` DATE)  SELECT consult.consult_id AS 'Consulta', concat(doctor.first_name," ",doctor.last_name) AS 'Doctor'
    FROM doctor
    JOIN consult ON doctor.doctor_id = consult.doctor_id
    JOIN diagnostic ON consult.consult_id = diagnostic.consult_id
    JOIN disease_catalog ON diagnostic.disease_catalog_id = disease_catalog.disease_catalog_id
    WHERE consult_date > in_start_date AND consult_date < in_end_date
    ORDER BY COUNT(consult.consult_id) DESC$$

DROP PROCEDURE IF EXISTS `get_diagnostic_by_dates_chart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_diagnostic_by_dates_chart` (IN `in_start_date` DATE, IN `in_end_date` DATE)  SELECT disease_catalog.disease_catalog_id, count(diagnostic.disease_catalog_id) AS 'Consult amount'
    FROM consult 
    JOIN diagnostic ON consult.consult_id = diagnostic.consult_id
    JOIN disease_catalog ON diagnostic.disease_catalog_id = disease_catalog.disease_catalog_id
    WHERE consult_date BETWEEN in_start_date AND in_end_date
    GROUP BY disease_catalog.disease_catalog_id
    ORDER BY disease_catalog.disease_catalog_id$$

DROP PROCEDURE IF EXISTS `get_diagnostic_by_dats_legend`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_diagnostic_by_dats_legend` (IN `in_start_date` DATE, IN `in_end_date` DATE)  SELECT disease_catalog.disease_catalog_id AS 'ID' ,ICD10,ICD9, description as 'Description'
    FROM consult 
    JOIN diagnostic ON consult.consult_id  = diagnostic.consult_id
    JOIN disease_catalog ON diagnostic.disease_catalog_id = disease_catalog.disease_catalog_id
    WHERE consult_date BETWEEN in_start_date AND in_end_date
    GROUP BY ICD10,ICD9,description
    ORDER BY  disease_catalog.disease_catalog_id$$

DROP PROCEDURE IF EXISTS `get_diagnostic_id_name`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_diagnostic_id_name` ()  SELECT disease_catalog_id, description
FROM disease_catalog$$

DROP PROCEDURE IF EXISTS `get_doctor_by_id`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_doctor_by_id` (IN `in_doctor_id` INT)  SELECT *
FROM doctor
WHERE doctor.doctor_id = in_doctor_id$$

DROP PROCEDURE IF EXISTS `get_doctor_id_name`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_doctor_id_name` ()  SELECT doctor_id, concat(first_name, ' ', last_name ) AS Name
FROM doctor
ORDER BY Name$$

DROP PROCEDURE IF EXISTS `get_medical_records`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_medical_records` (IN `in_patient_id` INT)  SELECT consult.consult_id AS 'Consult',  peea AS 'Reason', concat(first_name," ",last_name)AS 'Doctor', consult_date AS 'Consult date', description AS 'Diagnostic description'
FROM doctor JOIN consult 
ON doctor.doctor_id = consult.doctor_id
JOIN diagnostic ON consult.consult_id = diagnostic.consult_id
JOIN disease_catalog ON diagnostic.disease_catalog_id = disease_catalog.disease_catalog_id
WHERE patient_id = in_patient_id
ORDER BY YEAR(consult_date), MONTH(consult_date), DAY(consult_date)$$

DROP PROCEDURE IF EXISTS `get_med_id_name`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_med_id_name` ()  SELECT medicine_id, medicine_name
FROM medicine
ORDER BY medicine_name$$

DROP PROCEDURE IF EXISTS `get_patient`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient` (IN `in_patient_id` INT)  NO SQL
SELECT * 
FROM patient
WHERE patient_id = in_patient_id$$

DROP PROCEDURE IF EXISTS `get_patient_id_name`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_id_name` ()  NO SQL
SELECT patient_id, concat(first_name," ",last_name) AS Name
FROM patient
ORDER BY first_name, last_name$$

DROP PROCEDURE IF EXISTS `get_prescription`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_prescription` (IN `in_prescription_id` INT)  SELECT medicine_name AS 'Medicine', Ingredient, Dose, Instructions
    FROM prescription JOIN recipe
    ON prescription.prescription_id = recipe.prescription_id
    JOIN medicine ON recipe.medicine_id = medicine.medicine_id
    WHERE in_prescription_id = prescription.prescription_id
    ORDER BY medicine_name$$

DROP PROCEDURE IF EXISTS `get_test`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_test` ()  SELECT test_id, test_name
FROM test$$

DROP PROCEDURE IF EXISTS `get_test_instance`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_test_instance` (IN `in_instance_id` INT)  SELECT Question, answer_value AS 'Answer'
FROM questions JOIN test
ON questions.test_id = test.test_id
JOIN test_instance ON test_instance.test_id = test.test_id
JOIN answer ON answer.instance_id = test_instance.instance_id
WHERE test_instance.instance_id = in_instance_id AND answer.question_id = questions.question_id$$

DROP PROCEDURE IF EXISTS `get_test_instances_by_patient`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_test_instances_by_patient` (IN `in_test_id` INT, IN `in_patient_id` INT)  SELECT instance_id AS 'ID', consult_date AS 'DATE'
FROM test JOIN test_instance ON test.test_id = test_instance.test_id
JOIN consult ON test_instance.consult_id = consult.consult_id
JOIN patient ON consult.patient_id = patient.patient_id
WHERE test.test_id = in_test_id AND patient.patient_id = in_patient_id$$

DROP PROCEDURE IF EXISTS `get_test_result`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_test_result` (IN `in_instance_id` INT)  SELECT SUM(answer_value) AS Result, 'Not depressed' AS Meaning
FROM questions JOIN test
ON questions.test_id = test.test_id
JOIN test_instance ON test_instance.test_id = test.test_id
JOIN answer ON answer.instance_id = test_instance.instance_id
WHERE answer.question_id = questions.question_id AND test_instance.instance_id = in_instance_id
HAVING SUM(answer_value)<8
UNION
SELECT SUM(answer_value), 'Minor/mild depression'
FROM questions JOIN test
ON questions.test_id = test.test_id
JOIN test_instance ON test_instance.test_id = test.test_id
JOIN answer ON answer.instance_id = test_instance.instance_id
WHERE answer.question_id = questions.question_id AND test_instance.instance_id = in_instance_id
HAVING SUM(answer_value)>7 AND SUM(answer_value)<14 
UNION
SELECT SUM(answer_value), 'Moderate depression'
FROM questions JOIN test
ON questions.test_id = test.test_id
JOIN test_instance ON test_instance.test_id = test.test_id
JOIN answer ON answer.instance_id = test_instance.instance_id
WHERE answer.question_id = questions.question_id AND test_instance.instance_id = in_instance_id
HAVING SUM(answer_value)>13 AND SUM(answer_value)<19
UNION
SELECT SUM(answer_value), 'Severe depression'
FROM questions JOIN test
ON questions.test_id = test.test_id
JOIN test_instance ON test_instance.test_id = test.test_id
JOIN answer ON answer.instance_id = test_instance.instance_id
WHERE answer.question_id = questions.question_id AND test_instance.instance_id = in_instance_id
HAVING SUM(answer_value)>18 AND SUM(answer_value)<23 
UNION
SELECT SUM(answer_value), 'Very severe depression'
FROM questions JOIN test
ON questions.test_id = test.test_id
JOIN test_instance ON test_instance.test_id = test.test_id
JOIN answer ON answer.instance_id = test_instance.instance_id
WHERE answer.question_id = questions.question_id AND test_instance.instance_id = in_instance_id
HAVING SUM(answer_value)>22$$

DROP PROCEDURE IF EXISTS `show_test_questions`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `show_test_questions` (IN `in_test_id` INT)  SELECT Question_id AS 'Question ID',Question
FROM questions
WHERE test_id = in_test_id$$

DROP PROCEDURE IF EXISTS `submit_answer`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `submit_answer` (IN `in_test_id` INT, IN `in_question_id` INT, IN `in_answer_value` INT)  BEGIN
START TRANSACTION;
INSERT INTO answer(question_id, instance_id, answer_value ) VALUES (in_question_id, in_test_id, in_answer_value);

SELECT instance_id, MAX(question_id)+1, ' ' AS '1'
FROM answer 
WHERE instance_id = in_test_id;
COMMIT;
END$$

DROP PROCEDURE IF EXISTS `update_doctor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_doctor` (IN `in_doctor_id` INT, IN `in_first_name` VARCHAR(20), IN `in_last_name` VARCHAR(20), IN `in_license` VARCHAR(8), IN `in_phone` VARCHAR(15))  BEGIN
START TRANSACTION;
UPDATE doctor
SET first_name=in_first_name,
	last_name =	in_last_name,
	license = in_license,
	phone = in_phone
	WHERE doctor.doctor_id = in_doctor_id;

SELECT Max(doctor_id) + 1, ' ' AS '1', ' ' AS '2', ' ' AS '3' , ' ' AS '4'
FROM doctor;
    

COMMIT;
END$$

DROP PROCEDURE IF EXISTS `update_patient`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_patient` (IN `in_patient_id` INT, IN `in_first_name` VARCHAR(20), IN `in_last_name` VARCHAR(20), IN `in_sex` CHAR(1), IN `in_rfc` VARCHAR(13), IN `in_phone` VARCHAR(15), IN `in_city` VARCHAR(20), IN `in_street_address` VARCHAR(50), IN `in_email` VARCHAR(30), IN `in_date_of_birth` DATE)  BEGIN
START TRANSACTION;
UPDATE patient
	SET first_name=in_first_name,
	last_name =	in_last_name,
	sex =	in_sex,
	rfc = in_rfc,
	phone = in_phone,
	city = in_city,
	street_address = in_street_address,
	email = in_email,
	date_of_birth =	in_date_of_birth
	WHERE patient_id = in_patient_id;

	SELECT *
	FROM patient
    WHERE patient_id=in_patient_id;
COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `answer`
--

DROP TABLE IF EXISTS `answer`;
CREATE TABLE `answer` (
  `answer_id` int(11) NOT NULL,
  `question_id` int(11) DEFAULT NULL,
  `instance_id` int(11) NOT NULL,
  `answer_value` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `answer`
--

INSERT INTO `answer` (`answer_id`, `question_id`, `instance_id`, `answer_value`) VALUES
(1, 1, 1, 2),
(2, 2, 1, 2),
(3, 3, 1, 2),
(4, 4, 1, 1),
(5, 5, 1, 1),
(6, 6, 1, 2),
(7, 7, 1, 0),
(8, 8, 1, 2),
(9, 9, 1, 1),
(10, 10, 1, 1),
(11, 11, 1, 0),
(12, 12, 1, 1),
(13, 13, 1, 2),
(14, 14, 1, 0),
(15, 15, 1, 2),
(16, 16, 1, 0),
(17, 17, 1, 2),
(18, 1, 2, 2),
(19, 2, 2, 2),
(20, 3, 2, 0),
(21, 4, 2, 1),
(22, 5, 2, 2),
(23, 6, 2, 0),
(24, 7, 2, 2),
(25, 8, 2, 0),
(26, 9, 2, 1),
(27, 10, 2, 0),
(28, 11, 2, 0),
(29, 12, 2, 2),
(30, 13, 2, 0),
(31, 14, 2, 0),
(32, 15, 2, 2),
(33, 16, 2, 1),
(34, 17, 2, 2),
(35, 1, 3, 1),
(36, 2, 3, 2),
(37, 3, 3, 1),
(38, 4, 3, 2),
(39, 5, 3, 1),
(40, 6, 3, 0),
(41, 7, 3, 0),
(42, 8, 3, 0),
(43, 9, 3, 1),
(44, 10, 3, 1),
(45, 11, 3, 2),
(46, 12, 3, 0),
(47, 13, 3, 0),
(48, 14, 3, 2),
(49, 15, 3, 0),
(50, 16, 3, 1),
(51, 17, 3, 1),
(52, 1, 4, 1),
(53, 2, 4, 0),
(54, 3, 4, 0),
(55, 4, 4, 2),
(56, 5, 4, 0),
(57, 6, 4, 1),
(58, 7, 4, 2),
(59, 8, 4, 2),
(60, 9, 4, 1),
(61, 10, 4, 2),
(62, 11, 4, 0),
(63, 12, 4, 0),
(64, 13, 4, 1),
(65, 14, 4, 2),
(66, 15, 4, 0),
(67, 16, 4, 0),
(68, 17, 4, 2),
(69, 1, 5, 1),
(70, 2, 5, 0),
(71, 3, 5, 1),
(72, 4, 5, 2),
(73, 5, 5, 1),
(74, 6, 5, 2),
(75, 7, 5, 1),
(76, 8, 5, 1),
(77, 9, 5, 2),
(78, 10, 5, 1),
(79, 11, 5, 1),
(80, 12, 5, 2),
(81, 13, 5, 2),
(82, 14, 5, 1),
(83, 15, 5, 2),
(84, 16, 5, 0),
(85, 17, 5, 0),
(86, 1, 6, 1),
(87, 2, 6, 0),
(88, 3, 6, 1),
(89, 4, 6, 1),
(90, 5, 6, 0),
(91, 6, 6, 2),
(92, 7, 6, 2),
(93, 8, 6, 0),
(94, 9, 6, 0),
(95, 10, 6, 1),
(96, 11, 6, 1),
(97, 12, 6, 2),
(98, 13, 6, 1),
(99, 14, 6, 2),
(100, 15, 6, 2),
(101, 16, 6, 2),
(102, 17, 6, 2),
(103, 1, 7, 0),
(104, 2, 7, 0),
(105, 3, 7, 0),
(106, 4, 7, 1),
(107, 5, 7, 1),
(108, 6, 7, 0),
(109, 7, 7, 2),
(110, 8, 7, 2),
(111, 9, 7, 1),
(112, 10, 7, 0),
(113, 11, 7, 1),
(114, 12, 7, 1),
(115, 13, 7, 0),
(116, 14, 7, 0),
(117, 15, 7, 0),
(118, 16, 7, 0),
(119, 17, 7, 1),
(120, 1, 8, 0),
(121, 2, 8, 1),
(122, 3, 8, 0),
(123, 4, 8, 0),
(124, 5, 8, 2),
(125, 6, 8, 0),
(126, 7, 8, 2),
(127, 8, 8, 0),
(128, 9, 8, 1),
(129, 10, 8, 2),
(130, 11, 8, 1),
(131, 12, 8, 1),
(132, 13, 8, 1),
(133, 14, 8, 2),
(134, 15, 8, 1),
(135, 16, 8, 1),
(136, 17, 8, 1),
(137, 18, 9, 1),
(138, 19, 9, 2),
(139, 20, 9, 2),
(140, 21, 9, 1),
(141, 22, 9, 0),
(142, 23, 9, 2),
(143, 24, 9, 1),
(144, 25, 9, 2),
(145, 26, 9, 1),
(146, 27, 9, 2),
(147, 28, 9, 0),
(148, 29, 9, 0),
(149, 30, 9, 0),
(150, 31, 9, 0),
(151, 18, 10, 1),
(152, 19, 10, 1),
(153, 20, 10, 0),
(154, 21, 10, 0),
(155, 22, 10, 2),
(156, 23, 10, 2),
(157, 24, 10, 0),
(158, 25, 10, 1),
(159, 26, 10, 0),
(160, 27, 10, 2),
(161, 28, 10, 1),
(162, 29, 10, 0),
(163, 30, 10, 1),
(164, 31, 10, 0),
(165, 18, 11, 0),
(166, 19, 11, 0),
(167, 20, 11, 2),
(168, 21, 11, 1),
(169, 22, 11, 0),
(170, 23, 11, 1),
(171, 24, 11, 1),
(172, 25, 11, 0),
(173, 26, 11, 2),
(174, 27, 11, 0),
(175, 28, 11, 0),
(176, 29, 11, 1),
(177, 30, 11, 2),
(178, 31, 11, 0),
(179, 18, 12, 1),
(180, 19, 12, 0),
(181, 20, 12, 2),
(182, 21, 12, 0),
(183, 22, 12, 2),
(184, 23, 12, 0),
(185, 24, 12, 1),
(186, 25, 12, 2),
(187, 26, 12, 0),
(188, 27, 12, 0),
(189, 28, 12, 0),
(190, 29, 12, 1),
(191, 30, 12, 0),
(192, 31, 12, 0),
(193, 18, 13, 0),
(194, 19, 13, 1),
(195, 20, 13, 2),
(196, 21, 13, 2),
(197, 22, 13, 0),
(198, 23, 13, 0),
(199, 24, 13, 0),
(200, 25, 13, 1),
(201, 26, 13, 0),
(202, 27, 13, 0),
(203, 28, 13, 1),
(204, 29, 13, 2),
(205, 30, 13, 2),
(206, 31, 13, 0),
(207, 18, 14, 1),
(208, 19, 14, 1),
(209, 20, 14, 2),
(210, 21, 14, 2),
(211, 22, 14, 1),
(212, 23, 14, 2),
(213, 24, 14, 2),
(214, 25, 14, 0),
(215, 26, 14, 0),
(216, 27, 14, 1),
(217, 28, 14, 0),
(218, 29, 14, 2),
(219, 30, 14, 2),
(220, 31, 14, 0),
(221, 18, 15, 0),
(222, 19, 15, 2),
(223, 20, 15, 1),
(224, 21, 15, 0),
(225, 22, 15, 1),
(226, 23, 15, 2),
(227, 24, 15, 1),
(228, 25, 15, 1),
(229, 26, 15, 2),
(230, 27, 15, 2),
(231, 28, 15, 2),
(232, 29, 15, 1),
(233, 30, 15, 1),
(234, 31, 15, 1),
(235, 18, 16, 2),
(236, 19, 16, 2),
(237, 20, 16, 1),
(238, 21, 16, 0),
(239, 22, 16, 2),
(240, 23, 16, 1),
(241, 24, 16, 1),
(242, 25, 16, 0),
(243, 26, 16, 1),
(244, 27, 16, 1),
(245, 28, 16, 2),
(246, 29, 16, 0),
(247, 30, 16, 1),
(248, 31, 16, 2),
(249, 18, 21, 1),
(250, 19, 21, 4),
(251, 20, 21, 2),
(252, 21, 21, 3),
(253, 22, 21, 3),
(254, 23, 21, 0),
(255, 24, 21, 1),
(256, 25, 21, 3),
(257, 26, 21, 2),
(258, 27, 21, 3),
(259, 28, 21, 1),
(260, 29, 21, 3),
(261, 30, 21, 1),
(262, 31, 21, 1),
(263, 18, 22, 1),
(264, 19, 22, 1),
(265, 20, 22, 0),
(266, 21, 22, 1),
(267, 22, 22, 1),
(268, 23, 22, 1),
(269, 24, 22, 1),
(270, 25, 22, 1),
(271, 26, 22, 1),
(272, 27, 22, 1),
(273, 28, 22, 1),
(274, 29, 22, 1),
(275, 30, 22, 1),
(276, 18, 24, 1),
(277, 19, 24, 1),
(278, 20, 24, 1),
(279, 21, 24, 1),
(280, 22, 24, 1),
(281, 23, 24, 1),
(282, 24, 24, 1),
(283, 25, 24, 1),
(284, 26, 24, 1),
(285, 27, 24, 1),
(286, 28, 24, 1),
(287, 29, 24, 1),
(288, 30, 24, 1),
(289, 31, 24, 1);

-- --------------------------------------------------------

--
-- Table structure for table `app_info`
--

DROP TABLE IF EXISTS `app_info`;
CREATE TABLE `app_info` (
  `id` int(6) UNSIGNED NOT NULL,
  `app_nombre` varchar(250) NOT NULL,
  `color1` varchar(250) DEFAULT NULL,
  `color2` varchar(50) DEFAULT NULL,
  `home_name` varchar(100) DEFAULT NULL,
  `home_icon` varchar(50) DEFAULT NULL,
  `button1_name` varchar(100) DEFAULT NULL,
  `button1_icon` varchar(50) DEFAULT NULL,
  `button1_show` int(11) DEFAULT NULL,
  `button2_name` varchar(100) DEFAULT NULL,
  `button2_icon` varchar(50) DEFAULT NULL,
  `button2_show` int(11) DEFAULT NULL,
  `button3_name` varchar(100) DEFAULT NULL,
  `button3_icon` varchar(50) DEFAULT NULL,
  `button3_show` int(11) DEFAULT NULL,
  `button4_name` varchar(100) DEFAULT NULL,
  `button4_icon` varchar(50) DEFAULT NULL,
  `button4_show` int(11) DEFAULT NULL,
  `button5_name` varchar(100) DEFAULT NULL,
  `button5_icon` varchar(50) DEFAULT NULL,
  `button5_show` int(11) DEFAULT NULL,
  `button6_name` varchar(100) DEFAULT NULL,
  `button6_icon` varchar(50) DEFAULT NULL,
  `button6_show` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `app_info`
--

INSERT INTO `app_info` (`id`, `app_nombre`, `color1`, `color2`, `home_name`, `home_icon`, `button1_name`, `button1_icon`, `button1_show`, `button2_name`, `button2_icon`, `button2_show`, `button3_name`, `button3_icon`, `button3_show`, `button4_name`, `button4_icon`, `button4_show`, `button5_name`, `button5_icon`, `button5_show`, `button6_name`, `button6_icon`, `button6_show`) VALUES
(0, 'App', '#00b4ff', '#f8e71c', 'Home', 'home', 'Patient Dashboard', 'user', 1, 'Doctor Dashboard', 'user md', 1, 'Test', 'clipboard check', 1, 'Prescriptions', 'pills', 1, 'Reports', 'clipboard list', 1, 'New Visit', 'plus', 1),
(1, 'EHR', '#e91d1d', '#999292', 'Home', 'home', 'Pacientes', 'users', 1, 'Button 2', 'none', 0, 'Button 3', 'none', 0, 'Button 4', 'none', 0, 'Button 5', 'none', 0, 'Button 6', 'none', 0);

-- --------------------------------------------------------

--
-- Table structure for table `app_reporte`
--

DROP TABLE IF EXISTS `app_reporte`;
CREATE TABLE `app_reporte` (
  `id` int(6) UNSIGNED NOT NULL,
  `nombre_reporte` varchar(250) NOT NULL,
  `show_on_app` int(11) DEFAULT NULL,
  `location` int(11) DEFAULT NULL,
  `content` text,
  `icon` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `app_reporte`
--

INSERT INTO `app_reporte` (`id`, `nombre_reporte`, `show_on_app`, `location`, `content`, `icon`) VALUES
(1, 'Patient Dashboard', 1, 1, '[{\"identifier\":\"Patient Dashboard\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"idp\":5,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Patients\",\"default\":\"\",\"identifier\":\"dropdown6\",\"src\":\"get_patient_id_name\",\"expanded\":true},{\"idp\":21,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show all patient information\",\"sps\":[],\"fluid\":true,\"color\":\"teal\",\"position\":\"center\",\"identifier\":\"show_patient_info\",\"expanded\":true},{\"idp\":20,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_patient\",\"trigger\":\"show_patient_info\",\"params\":[\"dropdown6\"],\"targets\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"get from dropdown\",\"expanded\":true},{\"idp\":22,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space23\",\"expanded\":true},{\"idp\":23,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space24\",\"expanded\":true},{\"identifier\":\"update_container\",\"expanded\":true,\"idp\":6,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":8,\"node\":\"child\",\"type\":\"header\",\"text\":\"Patient Information\",\"size\":\"h1\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header9\",\"expanded\":true,\"icon_header\":\"edit outline\"},{\"idp\":36,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"25\",\"identifier\":\"space37\",\"expanded\":true},{\"identifier\":\"container38\",\"expanded\":true,\"idp\":37,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"form10\",\"expanded\":true,\"idp\":9,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid25\",\"expanded\":true,\"idp\":24,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":19,\"node\":\"child\",\"type\":\"input\",\"label\":\"ID\",\"default\":\"\",\"identifier\":\"patient_id\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":11,\"node\":\"child\",\"type\":\"input\",\"label\":\"First Name\",\"default\":\"\",\"identifier\":\"first_name\",\"inputType\":\"text\",\"expanded\":true},{\"idp\":12,\"node\":\"child\",\"type\":\"input\",\"label\":\"Last Name\",\"default\":\"\",\"identifier\":\"last_name\",\"inputType\":\"text\",\"expanded\":true},{\"idp\":13,\"node\":\"child\",\"type\":\"input\",\"label\":\"Sex\",\"default\":\"\",\"identifier\":\"sex\",\"inputType\":\"text\",\"expanded\":false}]},{\"identifier\":\"grid32\",\"expanded\":false,\"idp\":31,\"node\":\"parent\",\"centered\":true,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":28,\"node\":\"child\",\"type\":\"input\",\"label\":\"RFC\",\"default\":\"\",\"identifier\":\"rfc\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":29,\"node\":\"child\",\"type\":\"input\",\"label\":\"Phone\",\"default\":\"\",\"identifier\":\"phone\",\"inputType\":\"number\",\"expanded\":true},{\"idp\":27,\"node\":\"child\",\"type\":\"input\",\"label\":\"City\",\"default\":\"\",\"identifier\":\"city\",\"inputType\":\"text\",\"expanded\":false}]},{\"identifier\":\"grid33\",\"expanded\":true,\"idp\":32,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":30,\"node\":\"child\",\"type\":\"input\",\"label\":\"Address\",\"default\":\"\",\"identifier\":\"street_address\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":33,\"node\":\"child\",\"type\":\"input\",\"label\":\"Email\",\"default\":\"\",\"identifier\":\"email\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":34,\"node\":\"child\",\"type\":\"input\",\"label\":\"Date of Birth\",\"default\":\"\",\"identifier\":\"dob\",\"inputType\":\"date\",\"expanded\":false}]}]},{\"identifier\":\"grid39\",\"expanded\":true,\"idp\":38,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":26,\"node\":\"child\",\"type\":\"button\",\"text\":\"Delete\",\"sps\":[],\"fluid\":false,\"color\":\"red\",\"position\":\"left\",\"identifier\":\"delete\",\"expanded\":true},{\"idp\":42,\"node\":\"child\",\"type\":\"button\",\"text\":\"Create\",\"sps\":[],\"fluid\":false,\"color\":\"green\",\"position\":\"center\",\"identifier\":\"create\",\"expanded\":false,\"icon_button\":\"\"},{\"idp\":43,\"node\":\"child\",\"type\":\"button\",\"text\":\"Update\",\"sps\":[],\"fluid\":false,\"color\":\"blue\",\"position\":\"right\",\"identifier\":\"update\",\"expanded\":false}]},{\"idp\":35,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"update_patient\",\"trigger\":\"update\",\"params\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"targets\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Patient updated correctly\",\"order\":\"\",\"identifier\":\"update exec\",\"expanded\":false},{\"idp\":44,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"create_patient\",\"trigger\":\"create\",\"params\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"targets\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Patient created succesfully\",\"order\":\"\",\"identifier\":\"create exec\",\"expanded\":false},{\"idp\":45,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"delete_patient\",\"trigger\":\"delete\",\"params\":[\"patient_id\"],\"targets\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Patient deleted successfully\",\"order\":\"6\",\"identifier\":\"del exec\",\"expanded\":false}]},{\"idp\":39,\"node\":\"child\",\"type\":\"button\",\"text\":\"Clear\",\"sps\":[],\"fluid\":true,\"color\":\"grey\",\"position\":\"center\",\"identifier\":\"clear\",\"expanded\":false},{\"idp\":47,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"clear_patient\",\"trigger\":\"clear\",\"params\":[],\"targets\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"onLoad\":true,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"clear exec\",\"expanded\":false}]},{\"idp\":15,\"node\":\"child\",\"type\":\"divider\",\"identifier\":\"divider16\",\"expanded\":true},{\"identifier\":\"grid17\",\"expanded\":true,\"idp\":16,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"identifier\":\"table_container\",\"expanded\":true,\"idp\":7,\"node\":\"parent\",\"stacked\":true,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":14,\"node\":\"child\",\"type\":\"header\",\"text\":\"Consults\",\"size\":\"h1\",\"position\":\"center\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header15\",\"expanded\":true,\"icon_header\":\"calendar check outline\"},{\"idp\":0,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_medical_records\",\"trigger\":\"show_patient_info\",\"params\":[\"dropdown6\"],\"onLoad\":true,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table1\",\"expanded\":true}]}]}],\"max\":48}]', 'user outline'),
(2, 'Expediente médico por paciente', 1, NULL, '[{\"identifier\":\"Expediente médico por paciente\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"grid5\",\"expanded\":true,\"idp\":4,\"node\":\"parent\",\"centered\":false,\"cols\":\"3\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":6,\"node\":\"child\",\"type\":\"input\",\"label\":\"Input field \",\"default\":\"\",\"identifier\":\"input7\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":5,\"node\":\"child\",\"type\":\"button\",\"text\":\"BUSCAR\",\"sps\":[],\"fluid\":false,\"color\":\"neutral\",\"position\":\"left\",\"identifier\":\"button6\",\"expanded\":true,\"icon_button\":\"search\"},{\"idp\":9,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_patient\",\"trigger\":\"button6\",\"params\":[\"input7\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table10\",\"expanded\":false}]},{\"idp\":2,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_medical_records\",\"trigger\":\"button6\",\"params\":[\"input7\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table3\",\"expanded\":false}],\"max\":10,\"icon\":\"archive\"}]', 'archive'),
(3, 'Diagnosis Quantity By Dates', 1, 5, '[{\"identifier\":\"Diagnosis Quantity By Dates\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"grid3\",\"expanded\":true,\"idp\":2,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":0,\"node\":\"child\",\"type\":\"input\",\"label\":\"Inicio\",\"default\":\"\",\"identifier\":\"Inicio\",\"inputType\":\"date\",\"expanded\":false},{\"idp\":1,\"node\":\"child\",\"type\":\"input\",\"label\":\"Fin\",\"default\":\"\",\"identifier\":\"Fin\",\"inputType\":\"date\",\"expanded\":false},{\"idp\":3,\"node\":\"child\",\"type\":\"button\",\"text\":\"Buscar\",\"sps\":[],\"fluid\":false,\"color\":\"neutral\",\"position\":\"left\",\"identifier\":\"Buscar\",\"expanded\":false}]},{\"idp\":4,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_diagnostic_by_dates\",\"trigger\":\"Buscar\",\"params\":[\"Inicio\",\"Fin\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table5\",\"expanded\":false}],\"max\":6}]', 'calendar outline'),
(4, 'Consults By Dates', 1, 5, '[{\"identifier\":\"Consults By Dates\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"container10\",\"expanded\":true,\"idp\":9,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"grid3\",\"expanded\":true,\"idp\":2,\"node\":\"parent\",\"centered\":true,\"cols\":\"equal\",\"stretched\":true,\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":3,\"node\":\"child\",\"type\":\"input\",\"label\":\"Inicio\",\"default\":\"\",\"identifier\":\"Inicio\",\"inputType\":\"date\",\"expanded\":false},{\"idp\":4,\"node\":\"child\",\"type\":\"input\",\"label\":\"Fin\",\"default\":\"\",\"identifier\":\"Fin\",\"inputType\":\"date\",\"expanded\":false},{\"idp\":8,\"node\":\"child\",\"type\":\"button\",\"text\":\"Search\",\"sps\":[],\"fluid\":false,\"color\":\"blue\",\"position\":\"right\",\"identifier\":\"BUSCAR\",\"expanded\":false}]},{\"idp\":5,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_consult_by_dates\",\"trigger\":\"BUSCAR\",\"params\":[\"Inicio\",\"Fin\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table6\",\"expanded\":false}]}],\"max\":10,\"icon\":\"stethoscope\"}]', 'stethoscope'),
(5, 'Prescription', 1, 4, '[{\"identifier\":\"Prescription\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"container7\",\"expanded\":true,\"idp\":6,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":31,\"node\":\"child\",\"type\":\"header\",\"text\":\"Show all prescriptions\",\"size\":\"h2\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header32\",\"expanded\":false,\"icon_header\":\"clipboard outline\"},{\"idp\":30,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space31\",\"expanded\":false},{\"idp\":0,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"\",\"default\":\"\",\"identifier\":\"Dropdown\",\"src\":\"get_patient_id_name\",\"expanded\":false,\"placeholder\":\"Patient\"},{\"idp\":7,\"node\":\"child\",\"type\":\"button\",\"text\":\"Preview Prescriptions\",\"sps\":[],\"fluid\":true,\"color\":\"blue\",\"position\":\"center\",\"identifier\":\"button8\",\"expanded\":true},{\"idp\":1,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_prescription_id_by_patient_id\",\"trigger\":\"button8\",\"params\":[\"Dropdown\"],\"onLoad\":true,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table2\",\"expanded\":true}]},{\"idp\":9,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space10\",\"expanded\":true},{\"idp\":10,\"node\":\"child\",\"type\":\"divider\",\"identifier\":\"divider11\",\"expanded\":false},{\"identifier\":\"container9\",\"expanded\":true,\"idp\":8,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":34,\"node\":\"child\",\"type\":\"header\",\"text\":\"Prescription Details\",\"size\":\"h2\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header35\",\"expanded\":false,\"icon_header\":\"first aid\"},{\"idp\":33,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space34\",\"expanded\":true},{\"identifier\":\"form6\",\"expanded\":true,\"idp\":5,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid26\",\"expanded\":true,\"idp\":25,\"node\":\"parent\",\"centered\":true,\"cols\":\"equal\",\"stretched\":true,\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":2,\"node\":\"child\",\"type\":\"input\",\"label\":\"Prescription ID\",\"default\":\"\",\"identifier\":\"prescription_id\",\"inputType\":\"text\",\"expanded\":true,\"placeholder\":\"0000\"},{\"idp\":13,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show Prescrition\",\"sps\":[],\"fluid\":true,\"color\":\"blue\",\"position\":\"right\",\"identifier\":\"Go\",\"expanded\":false}]}]},{\"idp\":27,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_prescription\",\"trigger\":\"Go\",\"params\":[\"prescription_id\"],\"targets\":[\"ID\",\"Med\",\"dose\",\"ingridients\",\"instructions\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"show prescription\",\"expanded\":true},{\"idp\":29,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_prescription\",\"trigger\":\"Go\",\"params\":[\"prescription_id\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table30\",\"expanded\":false}]},{\"idp\":28,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_prescription\",\"trigger\":\"button8\",\"params\":[\"Dropdown\"],\"targets\":[],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"execution_single29\",\"expanded\":false}],\"max\":35,\"icon\":\"pills\"}]', 'pills'),
(6, 'Tests', 1, 3, '[{\"identifier\":\"Tests\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"container1\",\"expanded\":true,\"idp\":0,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":11,\"node\":\"child\",\"type\":\"header\",\"text\":\"Test Instances By Patient\",\"size\":\"h2\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header12\",\"expanded\":false},{\"idp\":13,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space14\",\"expanded\":false},{\"idp\":1,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Test type\",\"default\":\"\",\"identifier\":\"dropdown2\",\"src\":\"get_test\",\"expanded\":false},{\"idp\":2,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Patient\",\"default\":\"\",\"identifier\":\"dropdown3\",\"src\":\"get_patient_id_name\",\"expanded\":false},{\"idp\":5,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show Test Instance\",\"sps\":[],\"fluid\":true,\"color\":\"blue\",\"position\":\"center\",\"identifier\":\"button6\",\"expanded\":false},{\"idp\":4,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_test_instances_by_patient\",\"trigger\":\"button6\",\"params\":[\"dropdown2\",\"dropdown3\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table5\",\"expanded\":false}]},{\"idp\":16,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"25\",\"identifier\":\"space17\",\"expanded\":false},{\"identifier\":\"container7\",\"expanded\":true,\"idp\":6,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":14,\"node\":\"child\",\"type\":\"header\",\"text\":\"Test Answers\",\"size\":\"h2\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header15\",\"expanded\":true},{\"idp\":17,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"20\",\"identifier\":\"space18\",\"expanded\":true},{\"identifier\":\"form24\",\"expanded\":true,\"idp\":23,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid10\",\"expanded\":true,\"idp\":9,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":7,\"node\":\"child\",\"type\":\"input\",\"label\":\"Instance ID\",\"default\":\"\",\"identifier\":\"instance_id\",\"inputType\":\"number\",\"expanded\":false,\"placeholder\":\"0000\"},{\"idp\":8,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show test answers\",\"sps\":[],\"fluid\":true,\"color\":\"blue\",\"position\":\"center\",\"identifier\":\"button9\",\"expanded\":false}]}]},{\"identifier\":\"grid19\",\"expanded\":true,\"idp\":18,\"node\":\"parent\",\"centered\":false,\"cols\":\"5\",\"stretched\":false,\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":19,\"node\":\"child\",\"type\":\"header\",\"text\":\"Result\",\"size\":\"h3\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"res\",\"expanded\":true},{\"idp\":20,\"node\":\"child\",\"type\":\"input\",\"label\":\"Result\",\"default\":\"\",\"identifier\":\"input21\",\"inputType\":\"text\",\"expanded\":true,\"placeholder\":\"0\"},{\"idp\":22,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_test_result\",\"trigger\":\"button9\",\"params\":[\"instance_id\"],\"targets\":[\"input21\",\"meaning\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"res exec\",\"expanded\":false},{\"idp\":21,\"node\":\"child\",\"type\":\"input\",\"label\":\"Meaning\",\"default\":\"\",\"identifier\":\"meaning\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"Not depressed\"}]},{\"idp\":10,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_test_instance\",\"trigger\":\"button9\",\"params\":[\"instance_id\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table11\",\"expanded\":false}]}],\"max\":24,\"icon\":\"clipboard check\"}]', 'clipboard check'),
(7, 'Doctor Dashboard', 1, 2, '[{\"identifier\":\"Doctor Dashboard\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"container4\",\"expanded\":true,\"idp\":3,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":4,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"\",\"default\":\"\",\"identifier\":\"dropdown5\",\"src\":\"get_doctor_id_name\",\"expanded\":true},{\"idp\":18,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show Doctor\",\"sps\":[],\"fluid\":true,\"color\":\"teal\",\"position\":\"center\",\"identifier\":\"show doctor\",\"expanded\":true},{\"idp\":19,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space20\",\"expanded\":false},{\"identifier\":\"container13\",\"expanded\":true,\"idp\":12,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"form6\",\"expanded\":true,\"idp\":5,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid14\",\"expanded\":true,\"idp\":13,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":7,\"node\":\"child\",\"type\":\"input\",\"label\":\"ID\",\"default\":\"\",\"identifier\":\"ID\",\"inputType\":\"number\",\"expanded\":false,\"placeholder\":\"0000\"},{\"idp\":8,\"node\":\"child\",\"type\":\"input\",\"label\":\"License\",\"default\":\"\",\"identifier\":\"license\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"0000\"}]},{\"identifier\":\"grid15\",\"expanded\":true,\"idp\":14,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":9,\"node\":\"child\",\"type\":\"input\",\"label\":\"First Name\",\"default\":\"\",\"identifier\":\"fname\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"Jon\"},{\"idp\":10,\"node\":\"child\",\"type\":\"input\",\"label\":\"Last Name\",\"default\":\"\",\"identifier\":\"lname\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"Doe\"}]},{\"idp\":11,\"node\":\"child\",\"type\":\"input\",\"label\":\"Phone\",\"default\":\"\",\"identifier\":\"phone\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"1234567890\"}]},{\"identifier\":\"grid18\",\"expanded\":true,\"idp\":17,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":15,\"node\":\"child\",\"type\":\"button\",\"text\":\"Delete\",\"sps\":[],\"fluid\":false,\"color\":\"red\",\"position\":\"left\",\"identifier\":\"delete\",\"expanded\":false},{\"idp\":22,\"node\":\"child\",\"type\":\"button\",\"text\":\"Create\",\"sps\":[],\"fluid\":false,\"color\":\"green\",\"position\":\"center\",\"identifier\":\"create\",\"expanded\":false},{\"idp\":16,\"node\":\"child\",\"type\":\"button\",\"text\":\"Update\",\"sps\":[],\"fluid\":false,\"color\":\"blue\",\"position\":\"right\",\"identifier\":\"update\",\"expanded\":false}]}]},{\"idp\":6,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_doctor_by_id\",\"trigger\":\"show doctor\",\"params\":[\"dropdown5\"],\"targets\":[\"ID\",\"license\",\"fname\",\"lname\",\"phone\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"show patient\",\"expanded\":true},{\"idp\":23,\"node\":\"child\",\"type\":\"button\",\"text\":\"Clear\",\"sps\":[],\"fluid\":true,\"color\":\"grey\",\"position\":\"center\",\"identifier\":\"clear\",\"expanded\":false}]},{\"idp\":20,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"clear_doctor\",\"trigger\":\"clear\",\"params\":[],\"targets\":[\"ID\",\"license\",\"fname\",\"lname\",\"phone\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"clear exec\",\"expanded\":false},{\"idp\":21,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"create_doctor\",\"trigger\":\"create\",\"params\":[\"ID\",\"fname\",\"lname\",\"phone\",\"license\"],\"targets\":[\"ID\",\"license\",\"fname\",\"lname\",\"phone\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"create exec\",\"expanded\":false},{\"idp\":24,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"delete_doctor\",\"trigger\":\"delete\",\"params\":[\"ID\"],\"targets\":[\"ID\",\"license\",\"fname\",\"lname\",\"phone\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"del exec\",\"expanded\":false},{\"idp\":25,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"update_doctor\",\"trigger\":\"update\",\"params\":[\"ID\",\"fname\",\"lname\",\"license\",\"phone\"],\"targets\":[\"ID\",\"license\",\"fname\",\"lname\",\"phone\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"update exec\",\"expanded\":false}],\"max\":26,\"icon\":\"user md\"}]', 'user md'),
(8, 'New Visit', 1, 6, '[{\"identifier\":\"New Visit\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"Consult cont\",\"expanded\":true,\"idp\":0,\"node\":\"parent\",\"stacked\":true,\"raised\":true,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"grid38\",\"expanded\":true,\"idp\":37,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":1,\"node\":\"child\",\"type\":\"header\",\"text\":\"Consult\",\"size\":\"h1\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"Consult\",\"expanded\":true,\"icon_header\":\"weight\"},{\"idp\":36,\"node\":\"child\",\"type\":\"input\",\"label\":\"Consult ID\",\"default\":\"\",\"identifier\":\"cons id\",\"inputType\":\"number\",\"expanded\":true,\"placeholder\":\"DO NOT FILL\"}]},{\"idp\":13,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space14\",\"expanded\":true},{\"identifier\":\"form3\",\"expanded\":true,\"idp\":2,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid5\",\"expanded\":true,\"idp\":4,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":7,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Patient\",\"default\":\"\",\"identifier\":\"patent\",\"src\":\"get_patient_id_name\",\"expanded\":false},{\"idp\":8,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Doctor\",\"default\":\"\",\"identifier\":\"doctor\",\"src\":\"get_doctor_id_name\",\"expanded\":false}]},{\"identifier\":\"grid4\",\"expanded\":true,\"idp\":3,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":6,\"node\":\"child\",\"type\":\"input\",\"label\":\"Hour scheduled \",\"default\":\"\",\"identifier\":\"hour\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"24:59\"},{\"idp\":9,\"node\":\"child\",\"type\":\"input\",\"label\":\"Date scheduled\",\"default\":\"\",\"identifier\":\"Date\",\"inputType\":\"date\",\"expanded\":false,\"placeholder\":\"\"}]},{\"idp\":10,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space11\",\"expanded\":false},{\"idp\":5,\"node\":\"child\",\"type\":\"input\",\"label\":\"Motive\",\"default\":\"\",\"identifier\":\"Motive\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"Pains\"},{\"idp\":12,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space13\",\"expanded\":false},{\"idp\":21,\"node\":\"child\",\"type\":\"button\",\"text\":\"Create consult\",\"sps\":[],\"fluid\":true,\"color\":\"green\",\"position\":\"left\",\"identifier\":\"consult\",\"expanded\":false}]},{\"idp\":35,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"create_consult\",\"trigger\":\"consult\",\"params\":[\"patent\",\"doctor\",\"Motive\",\"hour\",\"Date\"],\"targets\":[\"cons id\",\"hour\",\"Date\",\"Motive\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Consult created, you can now create a test instance\",\"order\":\"\",\"identifier\":\"consult new exec\",\"expanded\":false}]},{\"idp\":15,\"node\":\"child\",\"type\":\"divider\",\"identifier\":\"divider16\",\"expanded\":false},{\"identifier\":\"container15\",\"expanded\":true,\"idp\":14,\"node\":\"parent\",\"stacked\":false,\"raised\":true,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":16,\"node\":\"child\",\"type\":\"header\",\"text\":\"Test\",\"size\":\"h1\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header17\",\"expanded\":false,\"icon_header\":\"edit outline\"},{\"idp\":18,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space19\",\"expanded\":false},{\"idp\":17,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Choose test\",\"default\":\"\",\"identifier\":\"test drop\",\"src\":\"get_test\",\"expanded\":false},{\"idp\":19,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show test questions\",\"sps\":[],\"fluid\":true,\"color\":\"teal\",\"position\":\"left\",\"identifier\":\"test\",\"expanded\":false},{\"idp\":38,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"create_test_instance\",\"trigger\":\"instance\",\"params\":[\"test drop\",\"cons id\"],\"targets\":[\"instance id\",\"question id\",\"answer\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Instance created, you can now submit answers\",\"order\":\"\",\"identifier\":\"instance exec\",\"expanded\":false},{\"idp\":20,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"show_test_questions\",\"trigger\":\"test\",\"params\":[\"test drop\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"question t\",\"expanded\":false},{\"idp\":29,\"node\":\"child\",\"type\":\"button\",\"text\":\"Create new instance (just press once before submiting answers)\",\"sps\":[],\"fluid\":true,\"color\":\"olive\",\"position\":\"center\",\"identifier\":\"instance\",\"expanded\":true},{\"idp\":31,\"node\":\"child\",\"type\":\"divider\",\"identifier\":\"divider32\",\"expanded\":true},{\"identifier\":\"form23\",\"expanded\":true,\"idp\":22,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid27\",\"expanded\":false,\"idp\":26,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":30,\"node\":\"child\",\"type\":\"input\",\"label\":\"Instance ID\",\"default\":\"\",\"identifier\":\"instance id\",\"inputType\":\"number\",\"expanded\":false,\"placeholder\":\"0000\"},{\"idp\":23,\"node\":\"child\",\"type\":\"input\",\"label\":\"Question ID\",\"default\":\"\",\"identifier\":\"question id\",\"inputType\":\"number\",\"expanded\":false,\"placeholder\":\"0000\"},{\"idp\":24,\"node\":\"child\",\"type\":\"input\",\"label\":\"Answer Value\",\"default\":\"\",\"identifier\":\"answer\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"0\"}]},{\"idp\":25,\"node\":\"child\",\"type\":\"button\",\"text\":\"Submit answer\",\"sps\":[],\"fluid\":true,\"color\":\"orange\",\"position\":\"left\",\"identifier\":\"button26\",\"expanded\":false},{\"idp\":34,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"submit_answer\",\"trigger\":\"button26\",\"params\":[\"instance id\",\"question id\",\"answer\"],\"targets\":[\"instance id\",\"question id\",\"answer\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Answer submited successfully\",\"order\":\"-1\",\"identifier\":\"answer exec\",\"expanded\":false}]},{\"idp\":33,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"25\",\"identifier\":\"space34\",\"expanded\":true},{\"idp\":32,\"node\":\"child\",\"type\":\"header\",\"text\":\"Current Test Answers\",\"size\":\"h2\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header33\",\"expanded\":true,\"icon_header\":\"check square outline\"},{\"idp\":28,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_test_instance\",\"trigger\":\"button26\",\"params\":[\"instance id\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"0\",\"identifier\":\"current table\",\"expanded\":false},{\"idp\":44,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show test result\",\"sps\":[],\"fluid\":true,\"color\":\"blue\",\"position\":\"center\",\"identifier\":\"button45\",\"expanded\":false},{\"idp\":39,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"20\",\"identifier\":\"space40\",\"expanded\":false},{\"identifier\":\"grid41\",\"expanded\":false,\"idp\":40,\"node\":\"parent\",\"centered\":true,\"cols\":\"3\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":41,\"node\":\"child\",\"type\":\"header\",\"text\":\"Result\",\"size\":\"h2\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header42\",\"expanded\":false},{\"idp\":42,\"node\":\"child\",\"type\":\"input\",\"label\":\"Result\",\"default\":\"\",\"identifier\":\"amount\",\"inputType\":\"number\",\"expanded\":false,\"placeholder\":\"0\"},{\"idp\":43,\"node\":\"child\",\"type\":\"input\",\"label\":\"Description\",\"default\":\"\",\"identifier\":\"desc\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"Status\"},{\"idp\":47,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_test_result\",\"trigger\":\"button45\",\"params\":[\"instance id\"],\"targets\":[\"amount\",\"desc\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"execution_single48\",\"expanded\":false}]}]},{\"idp\":49,\"node\":\"child\",\"type\":\"divider\",\"identifier\":\"divider50\",\"expanded\":false},{\"identifier\":\"grid52\",\"expanded\":true,\"idp\":51,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"identifier\":\"container49\",\"expanded\":true,\"idp\":48,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":63,\"node\":\"child\",\"type\":\"header\",\"text\":\"Diagnostic\",\"size\":\"h1\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"diag h\",\"expanded\":false,\"icon_header\":\"stethoscope\"},{\"idp\":62,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"15\",\"identifier\":\"space63\",\"expanded\":true},{\"idp\":53,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Choose from catalog\",\"default\":\"\",\"identifier\":\"DIAG DROP\",\"src\":\"get_diagnostic_id_name\",\"expanded\":true},{\"idp\":69,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show from catalog\",\"sps\":[],\"fluid\":true,\"color\":\"violet\",\"position\":\"center\",\"identifier\":\"button70\",\"expanded\":false},{\"idp\":68,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"20\",\"identifier\":\"space69\",\"expanded\":true},{\"idp\":70,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_disease\",\"trigger\":\"button70\",\"params\":[\"DIAG DROP\"],\"targets\":[\"icd10\",\"icd9\",\"diag desc\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"dis exec\",\"expanded\":false},{\"identifier\":\"form56\",\"expanded\":true,\"idp\":55,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid60\",\"expanded\":true,\"idp\":59,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":56,\"node\":\"child\",\"type\":\"input\",\"label\":\"ICD10\",\"default\":\"\",\"identifier\":\"icd10\",\"inputType\":\"text\",\"expanded\":true},{\"idp\":57,\"node\":\"child\",\"type\":\"input\",\"label\":\"ICD9\",\"default\":\"\",\"identifier\":\"icd9\",\"inputType\":\"text\",\"expanded\":false}]},{\"idp\":61,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space62\",\"expanded\":true},{\"idp\":58,\"node\":\"child\",\"type\":\"input\",\"label\":\"Description\",\"default\":\"\",\"identifier\":\"diag desc\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":60,\"node\":\"child\",\"type\":\"button\",\"text\":\"Diagnose\",\"sps\":[],\"fluid\":true,\"color\":\"yellow\",\"position\":\"left\",\"identifier\":\"button61\",\"expanded\":false},{\"idp\":64,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"create_diagnosis\",\"trigger\":\"button61\",\"params\":[\"cons id\",\"DIAG DROP\"],\"targets\":[\"icd10\",\"icd9\",\"diag desc\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Diagnosis saved\",\"order\":\"\",\"identifier\":\"diag exec\",\"expanded\":false}]}]},{\"identifier\":\"container51\",\"expanded\":false,\"idp\":50,\"node\":\"parent\",\"stacked\":false,\"raised\":true,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"grid72\",\"expanded\":true,\"idp\":71,\"node\":\"parent\",\"centered\":true,\"cols\":\"2\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":74,\"node\":\"child\",\"type\":\"header\",\"text\":\"Prescription\",\"size\":\"h1\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header75\",\"expanded\":false,\"icon_header\":\"pills\"},{\"idp\":72,\"node\":\"child\",\"type\":\"input\",\"label\":\"Prescription ID\",\"default\":\"\",\"identifier\":\"presc id\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"DO NOT MODIFY\"}]},{\"idp\":73,\"node\":\"child\",\"type\":\"button\",\"text\":\"Create prescription ID (once before prescribing)\",\"sps\":[],\"fluid\":true,\"color\":\"violet\",\"position\":\"left\",\"identifier\":\"create presc\",\"expanded\":false},{\"idp\":78,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"create_prescription_id\",\"trigger\":\"create presc\",\"params\":[\"cons id\"],\"targets\":[\"presc id\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Prescription created successfully, you may now prescribe medication\",\"order\":\"\",\"identifier\":\"prescr exec\",\"expanded\":true},{\"identifier\":\"container86\",\"expanded\":true,\"idp\":85,\"node\":\"parent\",\"stacked\":false,\"raised\":true,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"container87\",\"expanded\":true,\"idp\":86,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":91,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_med_by_id\",\"trigger\":\"button81\",\"params\":[\"med drop\"],\"targets\":[\"ingridient\",\"dose\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"show med\",\"expanded\":false},{\"identifier\":\"grid80\",\"expanded\":true,\"idp\":79,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":76,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Medicine\",\"default\":\"\",\"identifier\":\"med drop\",\"src\":\"get_med_id_name\",\"expanded\":false},{\"idp\":80,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show details\",\"sps\":[],\"fluid\":false,\"color\":\"orange\",\"position\":\"left\",\"identifier\":\"button81\",\"expanded\":false}]}]},{\"idp\":87,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"20\",\"identifier\":\"space88\",\"expanded\":false},{\"identifier\":\"grid85\",\"expanded\":true,\"idp\":84,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":82,\"node\":\"child\",\"type\":\"input\",\"label\":\"Ingridient\",\"default\":\"\",\"identifier\":\"ingridient\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":83,\"node\":\"child\",\"type\":\"input\",\"label\":\"Dose\",\"default\":\"\",\"identifier\":\"dose\",\"inputType\":\"text\",\"expanded\":false}]},{\"idp\":95,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space96\",\"expanded\":false}]},{\"idp\":90,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"15\",\"identifier\":\"space91\",\"expanded\":false},{\"identifier\":\"container90\",\"expanded\":true,\"idp\":89,\"node\":\"parent\",\"stacked\":false,\"raised\":true,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"form82\",\"expanded\":true,\"idp\":81,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"idp\":88,\"node\":\"child\",\"type\":\"input\",\"label\":\"Instructions\",\"default\":\"\",\"identifier\":\"instructions\",\"inputType\":\"text\",\"expanded\":false,\"placeholder\":\"x per day, for y days \"},{\"idp\":77,\"node\":\"child\",\"type\":\"button\",\"text\":\"Prescribe Medication\",\"sps\":[],\"fluid\":true,\"color\":\"green\",\"position\":\"left\",\"identifier\":\"prescribe\",\"expanded\":true},{\"idp\":92,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"create_recipe\",\"trigger\":\"prescribe\",\"params\":[\"presc id\",\"med drop\",\"instructions\"],\"targets\":[\"instructions\"],\"onLoad\":false,\"showSuccess\":true,\"message\":\"Medicine prescribed successfully.\",\"order\":\"-1\",\"identifier\":\"create rep\",\"expanded\":false}]}]}]}]},{\"idp\":94,\"node\":\"child\",\"type\":\"space\",\"pixels\":\"15\",\"identifier\":\"space95\",\"expanded\":false},{\"identifier\":\"container94\",\"expanded\":true,\"idp\":93,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":96,\"node\":\"child\",\"type\":\"header\",\"text\":\"Current Prescription\",\"size\":\"h1\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"current presc\",\"expanded\":false,\"icon_header\":\"clipboard list\"},{\"idp\":97,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_prescription\",\"trigger\":\"prescribe\",\"params\":[\"presc id\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table98\",\"expanded\":false}]}],\"max\":98,\"icon\":\"plus\"}]', 'plus'),
(9, 'Home dashboard', 1, 0, '[{\"identifier\":\"Home dashboard\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"identifier\":\"container1\",\"expanded\":true,\"idp\":0,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"identifier\":\"grid5\",\"expanded\":true,\"idp\":4,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":3,\"node\":\"child\",\"type\":\"input\",\"label\":\"From \",\"default\":\"01 01 2018\",\"identifier\":\"from date\",\"inputType\":\"date\",\"expanded\":true,\"placeholder\":\"01 01 2018\"},{\"idp\":2,\"node\":\"child\",\"type\":\"input\",\"label\":\"To\",\"default\":\"12 31 2018\",\"identifier\":\"to date\",\"inputType\":\"date\",\"expanded\":true,\"placeholder\":\"12 31 2018\"},{\"idp\":5,\"node\":\"child\",\"type\":\"button\",\"text\":\"Search\",\"sps\":[],\"fluid\":true,\"color\":\"blue\",\"position\":\"center\",\"identifier\":\"update\",\"expanded\":false}]},{\"identifier\":\"grid9\",\"expanded\":true,\"idp\":8,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":9,\"node\":\"child\",\"type\":\"chart\",\"id\":\"\",\"src\":\"get_diagnostic_by_dates_chart\",\"trigger\":\"update\",\"params\":[\"from date\",\"to date\"],\"chartType\":\"bar\",\"onLoad\":true,\"order\":\"\",\"identifier\":\"chart10\",\"expanded\":false,\"luminosity\":\"dark\",\"hue\":\"blue\"},{\"idp\":10,\"node\":\"child\",\"type\":\"chart\",\"id\":\"\",\"src\":\"\",\"trigger\":\"\",\"params\":[],\"chartType\":\"line\",\"onLoad\":false,\"order\":0,\"identifier\":\"chart11\",\"expanded\":false}]},{\"identifier\":\"grid12\",\"expanded\":true,\"idp\":11,\"node\":\"parent\",\"centered\":false,\"cols\":\"2\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":12,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_diagnostic_by_dats_legend\",\"trigger\":\"update\",\"params\":[\"from date\",\"to date\"],\"onLoad\":false,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table13\",\"expanded\":false}]}]}],\"max\":13,\"icon\":\"home\"}]', 'home');

-- --------------------------------------------------------

--
-- Table structure for table `consult`
--

DROP TABLE IF EXISTS `consult`;
CREATE TABLE `consult` (
  `consult_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `doctor_id` int(11) NOT NULL,
  `peea` varchar(100) NOT NULL,
  `consult_schedule` char(5) NOT NULL,
  `consult_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `consult`
--

INSERT INTO `consult` (`consult_id`, `patient_id`, `doctor_id`, `peea`, `consult_schedule`, `consult_date`) VALUES
(1, 1, 1, 'chequeo anual', '8:30', '2018-01-15'),
(2, 2, 2, 'indicios de ezquisofrenia', '15:20', '2018-01-09'),
(3, 3, 3, 'indicios de afeccion mental', '19:40', '2018-01-16'),
(4, 4, 4, 'depresión clinica', '16:20', '2018-02-08'),
(5, 4, 5, 'intento de suicido', '8:30', '2018-02-28'),
(6, 3, 5, 'atacó al hijo', '15:20', '2018-03-17'),
(7, 2, 4, 'agudización de sintomas', '19:40', '2018-04-06'),
(8, 1, 3, 'depresión post relación amorosa', '16:20', '2018-04-05'),
(9, 1, 2, 'episodio psiquíco ', '8:30', '2018-04-07'),
(10, 2, 1, 'conducta violenta', '15:20', '2018-05-26'),
(11, 3, 4, 'conducta bipolar', '19:40', '2018-06-25'),
(12, 4, 3, 'aislamiento social', '16:20', '2018-07-15'),
(13, 4, 2, 'monitoreo y control', '8:30', '2018-08-09'),
(14, 3, 5, 'chequeo mensual', '15:20', '2018-08-16'),
(15, 2, 2, 'agresón contra un tercero', '19:40', '2018-09-08'),
(16, 1, 1, 'alucinaciones', '16:20', '2018-09-28'),
(25, 4, 3, 'Headache', '12:56', '2018-11-21'),
(26, 1, 3, 'Chest pains', '12:34', '0001-01-01'),
(27, 6, 1, 'Headache', '10:53', '2018-11-21');

-- --------------------------------------------------------

--
-- Table structure for table `diagnostic`
--

DROP TABLE IF EXISTS `diagnostic`;
CREATE TABLE `diagnostic` (
  `consult_id` int(11) NOT NULL,
  `disease_catalog_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `diagnostic`
--

INSERT INTO `diagnostic` (`consult_id`, `disease_catalog_id`) VALUES
(1, 1),
(2, 870),
(3, 770),
(4, 955),
(5, 870),
(6, 770),
(7, 955),
(8, 955),
(9, 1),
(10, 1),
(11, 870),
(12, 870),
(13, 870),
(14, 770),
(15, 1),
(16, 1),
(25, 1),
(26, 3),
(27, 1);

-- --------------------------------------------------------

--
-- Table structure for table `disease_catalog`
--

DROP TABLE IF EXISTS `disease_catalog`;
CREATE TABLE `disease_catalog` (
  `disease_catalog_id` int(11) NOT NULL,
  `icd10` char(7) DEFAULT NULL,
  `icd9` char(9) DEFAULT NULL,
  `frequent_diagnostic` char(1) DEFAULT NULL,
  `description` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `disease_catalog`
--

INSERT INTO `disease_catalog` (`disease_catalog_id`, `icd10`, `icd9`, `frequent_diagnostic`, `description`) VALUES
(1, 'Z55.9', 'V62.3', '0', 'Academic or educational problem'),
(2, 'Z60.3', 'V62.4', '0', 'Acculturation difficulty'),
(3, 'F43.0', '308.3', '0', 'Acute stress disorder'),
(4, 'NA', 'NA', '0', 'Adjustment disorder'),
(5, 'F43.20', '309.9', '0', 'Adjustment disorder, Unspecified'),
(6, 'F43.22', '309.24', '0', 'Adjustment disorder, With anxiety'),
(7, 'F43.21', '309', '0', 'Adjustment disorder, With depressed mood'),
(8, 'F43.24', '309.3', '0', 'Adjustment disorder, With disturbance of conduct'),
(9, 'F43.23', '309.28', '0', 'Adjustment disorder, With mixed anxiety and depressed mood'),
(10, 'F43.25', '309.4', '0', 'Adjustment disorder, With mixed disturbance of emotions and conduct'),
(11, 'Z72.811', 'V71.01', '0', 'Adult antisocial behavior'),
(12, 'NA', 'NA', '0', 'Adult physical abuse by nonspouse or nonpartner, Confirmed'),
(13, 'T74.11X', '995.81', '0', 'Adult physical abuse by nonspouse or nonpartner, Confirmed, Initial encounter'),
(14, 'T74.11X', '995.81', '0', 'Adult physical abuse by nonspouse or nonpartner, Confirmed, Subsequent encounter'),
(15, 'NA', 'NA', '0', 'Adult physical abuse by nonspouse or nonpartner, Suspected'),
(16, 'T76.11X', '995.81', '0', 'Adult physical abuse by nonspouse or nonpartner, Suspected, Initial encounter'),
(17, 'T76.11X', '995.81', '0', 'Adult physical abuse by nonspouse or nonpartner, Suspected, Subsequent encounter'),
(18, NULL, NULL, '0', 'Adult psychological abuse by nonspouse or nonpartner, Confirmed'),
(19, 'T74.31X', '995.82', '0', 'Adult psychological abuse by nonspouse or nonpartner, Confirmed, Initial encounter'),
(20, 'T74.31X', '995.82', '0', 'Adult psychological abuse by nonspouse or nonpartner, Confirmed, Subsequent encounter'),
(21, NULL, NULL, '0', 'Adult psychological abuse by nonspouse or nonpartner, Suspected'),
(22, 'T76.31X', '995.82', '0', 'Adult psychological abuse by nonspouse or nonpartner, Suspected, Initial encounter'),
(23, 'T76.31X', '995.82', '0', 'Adult psychological abuse by nonspouse or nonpartner, Suspected, Subsequent encounter'),
(24, NULL, NULL, '0', 'Adult sexual abuse by nonspouse or nonpartner, Confirmed'),
(25, 'T74.21X', '995.83', '0', 'Adult sexual abuse by nonspouse or nonpartner, Confirmed, Initial encounter'),
(26, 'T74.21X', '995.83', '0', 'Adult sexual abuse by nonspouse or nonpartner, Confirmed, Subsequent encounter'),
(27, NULL, NULL, '0', 'Adult sexual abuse by nonspouse or nonpartner, Suspected'),
(28, 'T76.21X', '995.83', '0', 'Adult sexual abuse by nonspouse or nonpartner, Suspected, Initial encounter'),
(29, 'T76.21X', '995.83', '0', 'Adult sexual abuse by nonspouse or nonpartner, Suspected, Subsequent encounter'),
(30, 'F98.5', '307', '0', 'Adult-onset fluency disorder'),
(31, 'F40.00', '300.22', '0', 'Agoraphobia'),
(32, NULL, '303', '0', 'Alcohol intoxication'),
(33, NULL, '291', '0', 'Alcohol intoxication delirium'),
(34, 'F10.121', NULL, '0', 'Alcohol intoxication delirium, With mild use disorder'),
(35, 'F10.221', NULL, '0', 'Alcohol intoxication delirium, With moderate or severe use disorder'),
(36, 'F10.921', NULL, '0', 'Alcohol intoxication delirium, Without use disorder'),
(37, 'F10.129', NULL, '0', 'Alcohol intoxication, With mild use disorder'),
(38, 'F10.229', NULL, '0', 'Alcohol intoxication, With moderate or severe use disorder'),
(39, 'F10.929', NULL, '0', 'Alcohol intoxication, Without use disorder'),
(40, NULL, NULL, '0', 'Alcohol use disorder'),
(41, 'F10.10', '305', '0', 'Alcohol use disorder, Mild'),
(42, 'F10.20', '303.9', '0', 'Alcohol use disorder, Moderate'),
(43, 'F10.20', '303.9', '0', 'Alcohol use disorder, Severe'),
(44, NULL, '291.81', '0', 'Alcohol withdrawal'),
(45, 'F10.231', '291', '0', 'Alcohol withdrawal delirium'),
(46, 'F10.232', NULL, '0', 'Alcohol withdrawal, With perceptual disturbances'),
(47, 'F10.239', NULL, '0', 'Alcohol withdrawal, Without perceptual disturbances'),
(48, NULL, '291.89', '0', 'Alcohol-induced anxiety disorder'),
(49, 'F10.180', NULL, '0', 'Alcohol-induced anxiety disorder, With mild use disorder'),
(50, 'F10.280', NULL, '0', 'Alcohol-induced anxiety disorder, With moderate or severe use disorder'),
(51, 'F10.980', NULL, '0', 'Alcohol-induced anxiety disorder, Without use disorder'),
(52, NULL, '291.89', '0', 'Alcohol-induced bipolar and related disorder'),
(53, 'F10.14', NULL, '0', 'Alcohol-induced bipolar and related disorder, With mild use disorder'),
(54, 'F10.24', NULL, '0', 'Alcohol-induced bipolar and related disorder, With moderate or severe use disorder'),
(55, 'F10.94', NULL, '0', 'Alcohol-induced bipolar and related disorder, Without use disorder'),
(56, NULL, '291.89', '0', 'Alcohol-induced depressive disorder'),
(57, 'F10.14', NULL, '0', 'Alcohol-induced depressive disorder, With mild use disorder'),
(58, 'F10.24', NULL, '0', 'Alcohol-induced depressive disorder, With moderate or severe use disorder'),
(59, 'F10.94', NULL, '0', 'Alcohol-induced depressive disorder, Without use disorder'),
(60, NULL, '291.1', '0', 'Alcohol-induced major neurocognitive disorder, Amnestic confabulatory type'),
(61, 'F10.26', NULL, '0', 'Alcohol-induced major neurocognitive disorder, Amnestic confabulatory type, With moderate or severe use disorder'),
(62, 'F10.96', NULL, '0', 'Alcohol-induced major neurocognitive disorder, Amnestic confabulatory type, Without use disorder'),
(63, NULL, '291.2', '0', 'Alcohol-induced major neurocognitive disorder, Nonamnestic confabulatory type'),
(64, 'F10.27', NULL, '0', 'Alcohol-induced major neurocognitive disorder, Nonamnestic confabulatory type, With moderate or severe use disorder'),
(65, 'F10.97', NULL, '0', 'Alcohol-induced major neurocognitive disorder, Nonamnestic confabulatory type, Without use disorder'),
(66, NULL, '291.89', '0', 'Alcohol-induced mild neurocognitive disorder'),
(67, 'F10.288', NULL, '0', 'Alcohol-induced mild neurocognitive disorder, With moderate or severe use disorder'),
(68, 'F10.988', NULL, '0', 'Alcohol-induced mild neurocognitive disorder, Without use disorder'),
(69, NULL, '291.9', '0', 'Alcohol-induced psychotic disorder'),
(70, 'F10.159', NULL, '0', 'Alcohol-induced psychotic disorder, With mild use disorder'),
(71, 'F10.259', NULL, '0', 'Alcohol-induced psychotic disorder, With moderate or severe use disorder'),
(72, 'F10.959', NULL, '0', 'Alcohol-induced psychotic disorder, Without use disorder'),
(73, NULL, '291.89', '0', 'Alcohol-induced sexual dysfunction'),
(74, 'F10.181', NULL, '0', 'Alcohol-induced sexual dysfunction, With mild use disorder'),
(75, 'F10.281', NULL, '0', 'Alcohol-induced sexual dysfunction, With moderate or severe use disorder'),
(76, 'F10.981', NULL, '0', 'Alcohol-induced sexual dysfunction, Without use disorder'),
(77, NULL, '291.82', '0', 'Alcohol-induced sleep disorder'),
(78, 'F10.182', NULL, '0', 'Alcohol-induced sleep disorder, With mild use disorder'),
(79, 'F10.282', NULL, '0', 'Alcohol-induced sleep disorder, With moderate or severe use disorder'),
(80, 'F10.982', NULL, '0', 'Alcohol-induced sleep disorder, Without use disorder'),
(81, NULL, '292.81', '0', 'Amphetamine (or other stimulant) intoxication delirium'),
(82, 'F15.121', NULL, '0', 'Amphetamine (or other stimulant) intoxication delirium, With mild use disorder'),
(83, 'F15.221', NULL, '0', 'Amphetamine (or other stimulant) intoxication delirium, With moderate or severe use disorder'),
(84, 'F15.921', NULL, '0', 'Amphetamine (or other stimulant) intoxication delirium, Without use disorder'),
(85, NULL, '292.89', '0', 'Amphetamine (or other stimulant)-induced anxiety disorder'),
(86, 'F15.180', NULL, '0', 'Amphetamine (or other stimulant)-induced anxiety disorder, With mild use disorder'),
(87, 'F15.280', NULL, '0', 'Amphetamine (or other stimulant)-induced anxiety disorder, With moderate or severe use disorder'),
(88, 'F15.980', NULL, '0', 'Amphetamine (or other stimulant)-induced anxiety disorder, Without use disorder'),
(89, NULL, '292.84', '0', 'Amphetamine (or other stimulant)-induced bipolar and related disorder'),
(90, 'F15.14', NULL, '0', 'Amphetamine (or other stimulant)-induced bipolar and related disorder, With mild use disorder'),
(91, 'F15.24', NULL, '0', 'Amphetamine (or other stimulant)-induced bipolar and related disorder, With moderate or severe use disorder'),
(92, 'F15.94', NULL, '0', 'Amphetamine (or other stimulant)-induced bipolar and related disorder, Without use disorder'),
(93, 'F15.921', NULL, '0', 'Amphetamine (or other stimulant)-induced delirium'),
(94, NULL, '292.84', '0', 'Amphetamine (or other stimulant)-induced depressive disorder'),
(95, 'F15.14', NULL, '0', 'Amphetamine (or other stimulant)-induced depressive disorder, With mild use disorder'),
(96, 'F15.24', NULL, '0', 'Amphetamine (or other stimulant)-induced depressive disorder, With moderate or severe use disorder'),
(97, 'F15.94', NULL, '0', 'Amphetamine (or other stimulant)-induced depressive disorder, Without use disorder'),
(98, NULL, '292.89', '0', 'Amphetamine (or other stimulant)-induced obsessive-compulsive and related disorder'),
(99, 'F15.188', NULL, '0', 'Amphetamine (or other stimulant)-induced obsessive-compulsive and related disorder, With mild use disorder'),
(100, 'F15.288', NULL, '0', 'Amphetamine (or other stimulant)-induced obsessive-compulsive and related disorder, With moderate or severe use disorder'),
(101, 'F15.988', NULL, '0', 'Amphetamine (or other stimulant)-induced obsessive-compulsive and related disorder, Without use disorder'),
(102, NULL, '292.9', '0', 'Amphetamine (or other stimulant)-induced psychotic disorder'),
(103, 'F15.159', NULL, '0', 'Amphetamine (or other stimulant)-induced psychotic disorder, With mild use disorder'),
(104, 'F15.259', NULL, '0', 'Amphetamine (or other stimulant)-induced psychotic disorder, With moderate or severe use disorder'),
(105, 'F15.959', NULL, '0', 'Amphetamine (or other stimulant)-induced psychotic disorder, Without use disorder'),
(106, NULL, '292.89', '0', 'Amphetamine (or other stimulant)-induced sexual dysfunction'),
(107, 'F15.181', NULL, '0', 'Amphetamine (or other stimulant)-induced sexual dysfunction, With mild use disorder'),
(108, 'F15.281', NULL, '0', 'Amphetamine (or other stimulant)-induced sexual dysfunction, With moderate or severe use disorder'),
(109, 'F15.981', NULL, '0', 'Amphetamine (or other stimulant)-induced sexual dysfunction, Without use disorder'),
(110, NULL, '292.85', '0', 'Amphetamine (or other stimulant)-induced sleep disorder'),
(111, 'F15.182', NULL, '0', 'Amphetamine (or other stimulant)-induced sleep disorder, With mild use disorder'),
(112, 'F15.282', NULL, '0', 'Amphetamine (or other stimulant)-induced sleep disorder, With moderate or severe use disorder'),
(113, 'F15.982', NULL, '0', 'Amphetamine (or other stimulant)-induced sleep disorder, Without use disorder'),
(114, NULL, '292.89', '0', 'Amphetamine or other stimulant intoxication'),
(115, NULL, NULL, '0', 'Amphetamine or other stimulant intoxication, With perceptual disturbances'),
(116, 'F15.122', NULL, '0', 'Amphetamine or other stimulant intoxication, With perceptual disturbances, With mild use disorder'),
(117, 'F15.222', NULL, '0', 'Amphetamine or other stimulant intoxication, With perceptual disturbances, With moderate or severe use disorder'),
(118, 'F15.922', NULL, '0', 'Amphetamine or other stimulant intoxication, With perceptual disturbances, Without use disorder'),
(119, NULL, NULL, '0', 'Amphetamine or other stimulant intoxication, Without perceptual disturbances'),
(120, 'F15.129', NULL, '0', 'Amphetamine or other stimulant intoxication, Without perceptual disturbances, With mild use disorder'),
(121, 'F15.229', NULL, '0', 'Amphetamine or other stimulant intoxication, Without perceptual disturbances, With moderate or severe use disorder'),
(122, 'F15.929', NULL, '0', 'Amphetamine or other stimulant intoxication, Without perceptual disturbances, Without use disorder'),
(123, 'F15.23', '292', '0', 'Amphetamine or other stimulant withdrawal'),
(124, NULL, NULL, '0', 'Amphetamine-type substance use disorder'),
(125, 'F15.10', '305.7', '0', 'Amphetamine-type substance use disorder, Mild'),
(126, 'F15.20', '304.4', '0', 'Amphetamine-type substance use disorder, Moderate'),
(127, 'F15.20', '304.4', '0', 'Amphetamine-type substance use disorder, Severe'),
(128, NULL, '307.1', '0', 'Anorexia nervosa'),
(129, 'F50.02', NULL, '0', 'Anorexia nervosa, Binge-eating/purging type'),
(130, 'F50.01', NULL, '0', 'Anorexia nervosa, Restricting type'),
(131, NULL, NULL, '0', 'Antidepressant discontinuation syndrome'),
(132, 'T43.205', '995.29', '0', 'Antidepressant discontinuation syndrome, Initial encounter'),
(133, 'T43.205', '995.29', '0', 'Antidepressant discontinuation syndrome, Sequelae'),
(134, 'T43.205', '995.29', '0', 'Antidepressant discontinuation syndrome, Subsequent encounter'),
(135, 'F60.2', '301.7', '0', 'Antisocial personality disorder'),
(136, 'F06.4', '293.84', '0', 'Anxiety disorder due to another medical condition'),
(137, NULL, NULL, '0', 'Attention-deficit/hyperactivity disorder'),
(138, 'F90.2', '314.01', '0', 'Attention-deficit/hyperactivity disorder, Combined presentation'),
(139, 'F90.1', '314.01', '0', 'Attention-deficit/hyperactivity disorder, Predominantly hyperactive/impulsive presentation'),
(140, 'F90.0', '314', '0', 'Attention-deficit/hyperactivity disorder, Predominantly inattentive presentation'),
(141, 'F84.0', '299', '0', 'Autism spectrum disorder'),
(142, 'G47.419', '347', '0', 'Autosomal dominant cerebellar ataxia, deafness, and narcolepsy'),
(143, 'G47.419', '347', '0', 'Autosomal dominant narcolepsy, obesity, and type 2 diabetes'),
(144, 'F60.6', '301.82', '0', 'Avoidant personality disorder'),
(145, 'F50.8', '307.59', '0', 'Avoidant/restrictive food intake disorder'),
(146, 'F50.8', '307.51', '0', 'Binge-eating disorder'),
(147, NULL, '293.83', '0', 'Bipolar and related disorder due to another medical condition'),
(148, 'F06.33', NULL, '0', 'Bipolar and related disorder due to another medical condition, With manic features'),
(149, 'F06.33', NULL, '0', 'Bipolar and related disorder due to another medical condition, With manic- or hypomanic-like episodes'),
(150, 'F06.34', NULL, '0', 'Bipolar and related disorder due to another medical condition, With mixed features'),
(151, NULL, NULL, '0', 'Bipolar I disorder, Current or most recent episode depressed'),
(152, 'F31.76', '296.56', '0', 'Bipolar I disorder, Current or most recent episode depressed, In full remission'),
(153, 'F31.75', '296.55', '0', 'Bipolar I disorder, Current or most recent episode depressed, In partial remission'),
(154, 'F31.31', '296.51', '0', 'Bipolar I disorder, Current or most recent episode depressed, Mild'),
(155, 'F31.32', '296.52', '0', 'Bipolar I disorder, Current or most recent episode depressed, Moderate'),
(156, 'F31.4', '296.53', '0', 'Bipolar I disorder, Current or most recent episode depressed, Severe'),
(157, 'F31.9', '296.5', '0', 'Bipolar I disorder, Current or most recent episode depressed, Unspecified'),
(158, 'F31.5', '296.54', '0', 'Bipolar I disorder, Current or most recent episode depressed, With psychotic features'),
(159, 'F31.0', '296.4', '0', 'Bipolar I disorder, Current or most recent episode hypomanic'),
(160, 'F31.74', '296.46', '0', 'Bipolar I disorder, Current or most recent episode hypomanic, In full remission'),
(161, 'F31.73', '296.45', '0', 'Bipolar I disorder, Current or most recent episode hypomanic, In partial remission'),
(162, 'F31.9', '296.4', '0', 'Bipolar I disorder, Current or most recent episode hypomanic, Unspecified'),
(163, NULL, NULL, '0', 'Bipolar I disorder, Current or most recent episode manic'),
(164, 'F31.74', '296.46', '0', 'Bipolar I disorder, Current or most recent episode manic, In full remission'),
(165, 'F31.73', '296.45', '0', 'Bipolar I disorder, Current or most recent episode manic, In partial remission'),
(166, 'F31.11', '296.41', '0', 'Bipolar I disorder, Current or most recent episode manic, Mild'),
(167, 'F31.12', '296.42', '0', 'Bipolar I disorder, Current or most recent episode manic, Moderate'),
(168, 'F31.13', '296.43', '0', 'Bipolar I disorder, Current or most recent episode manic, Severe'),
(169, 'F31.9', '296.4', '0', 'Bipolar I disorder, Current or most recent episode manic, Unspecified'),
(170, 'F31.2', '296.44', '0', 'Bipolar I disorder, Current or most recent episode manic, With psychotic features'),
(171, 'F31.9', '296.7', '0', 'Bipolar I disorder, Current or most recent episode unspecified'),
(172, 'F31.81', '296.89', '0', 'Bipolar II disorder'),
(173, 'F45.22', '300.7', '0', 'Body dysmorphic disorder'),
(174, 'R41.83', 'V62.89', '0', 'Borderline intellectual functioning'),
(175, 'F60.3', '301.83', '0', 'Borderline personality disorder'),
(176, 'F23', '298.8', '0', 'Brief psychotic disorder'),
(177, 'F50.2', '307.51', '0', 'Bulimia nervosa'),
(178, 'F15.929', '305.9', '0', 'Caffeine intoxication'),
(179, 'F15.93', '292', '0', 'Caffeine withdrawal'),
(180, NULL, '292.89', '0', 'Caffeine-induced anxiety disorder'),
(181, 'F15.180', NULL, '0', 'Caffeine-induced anxiety disorder, With mild use disorder'),
(182, 'F15.280', NULL, '0', 'Caffeine-induced anxiety disorder, With moderate or severe use disorder'),
(183, 'F15.980', NULL, '0', 'Caffeine-induced anxiety disorder, Without use disorder'),
(184, NULL, '292.85', '0', 'Caffeine-induced sleep disorder'),
(185, 'F15.182', NULL, '0', 'Caffeine-induced sleep disorder, With mild use disorder'),
(186, 'F15.282', NULL, '0', 'Caffeine-induced sleep disorder, With moderate or severe use disorder'),
(187, 'F15.982', NULL, '0', 'Caffeine-induced sleep disorder, Without use disorder'),
(188, NULL, '292.89', '0', 'Cannabis intoxication'),
(189, NULL, '292.81', '0', 'Cannabis intoxication delirium'),
(190, 'F12.121', NULL, '0', 'Cannabis intoxication delirium, With mild use disorder'),
(191, 'F12.221', NULL, '0', 'Cannabis intoxication delirium, With moderate or severe use disorder'),
(192, 'F12.921', NULL, '0', 'Cannabis intoxication delirium, Without use disorder'),
(193, NULL, NULL, '0', 'Cannabis intoxication, With perceptual disturbances'),
(194, 'F12.122', NULL, '0', 'Cannabis intoxication, With perceptual disturbances, With mild use disorder'),
(195, 'F12.222', NULL, '0', 'Cannabis intoxication, With perceptual disturbances, With moderate or severe use disorder'),
(196, 'F12.922', NULL, '0', 'Cannabis intoxication, With perceptual disturbances, Without use disorder'),
(197, NULL, NULL, '0', 'Cannabis intoxication, Without perceptual disturbances'),
(198, 'F12.129', NULL, '0', 'Cannabis intoxication, Without perceptual disturbances, With mild use disorder'),
(199, 'F12.229', NULL, '0', 'Cannabis intoxication, Without perceptual disturbances, With moderate or severe use disorder'),
(200, 'F12.929', NULL, '0', 'Cannabis intoxication, Without perceptual disturbances, Without use disorder'),
(201, NULL, NULL, '0', 'Cannabis use disorder'),
(202, 'F12.10', '305.2', '0', 'Cannabis use disorder, Mild'),
(203, 'F12.20', '304.3', '0', 'Cannabis use disorder, Moderate'),
(204, 'F12.20', '304.3', '0', 'Cannabis use disorder, Severe'),
(205, 'F12.288', '292', '0', 'Cannabis withdrawal'),
(206, NULL, '292.89', '0', 'Cannabis-induced anxiety disorder'),
(207, 'F12.180', NULL, '0', 'Cannabis-induced anxiety disorder, With mild use disorder'),
(208, 'F12.280', NULL, '0', 'Cannabis-induced anxiety disorder, With moderate or severe use disorder'),
(209, 'F12.980', NULL, '0', 'Cannabis-induced anxiety disorder, Without use disorder'),
(210, NULL, '292.9', '0', 'Cannabis-induced psychotic disorder'),
(211, 'F12.159', NULL, '0', 'Cannabis-induced psychotic disorder, With mild use disorder'),
(212, 'F12.259', NULL, '0', 'Cannabis-induced psychotic disorder, With moderate or severe use disorder'),
(213, 'F12.959', NULL, '0', 'Cannabis-induced psychotic disorder, Without use disorder'),
(214, NULL, '292.85', '0', 'Cannabis-induced sleep disorder'),
(215, 'F12.188', NULL, '0', 'Cannabis-induced sleep disorder, With mild use disorder'),
(216, 'F12.288', NULL, '0', 'Cannabis-induced sleep disorder, With moderate or severe use disorder'),
(217, 'F12.988', NULL, '0', 'Cannabis-induced sleep disorder, Without use disorder'),
(218, 'F06.1', '293.89', '0', 'Catatonia associated with another mental disorder (catatonia specifier)'),
(219, 'F06.1', '293.89', '0', 'Catatonic disorder due to another medical condition'),
(220, NULL, NULL, '0', 'Central sleep apnea'),
(221, 'G47.37', '780.57', '0', 'Central sleep apnea comorbid with opioid use'),
(222, 'R06.3', '786.04', '0', 'Cheyne-Stokes breathing'),
(223, 'Z62.898', 'V61.29', '0', 'Child affected by parental relationship distress'),
(224, NULL, NULL, '0', 'Child neglect, Confirmed'),
(225, 'T74.02X', '995.52', '0', 'Child neglect, Confirmed, Initial encounter'),
(226, 'T74.02X', '995.52', '0', 'Child neglect, Confirmed, Subsequent encounter'),
(227, NULL, NULL, '0', 'Child neglect, Suspected'),
(228, 'T76.02X', '995.52', '0', 'Child neglect, Suspected, Initial encounter'),
(229, 'T76.02X', '995.52', '0', 'Child neglect, Suspected, Subsequent encounter'),
(230, 'Z72.810', 'V71.02', '0', 'Child or adolescent antisocial behavior'),
(231, NULL, NULL, '0', 'Child physical abuse, Confirmed'),
(232, 'T74.12X', '995.54', '0', 'Child physical abuse, Confirmed, Initial encounter'),
(233, 'T74.12X', '995.54', '0', 'Child physical abuse, Confirmed, Subsequent encounter'),
(234, NULL, NULL, '0', 'Child physical abuse, Suspected'),
(235, 'T76.12X', '995.54', '0', 'Child physical abuse, Suspected, Initial encounter'),
(236, 'T76.12X', '995.54', '0', 'Child physical abuse, Suspected, Subsequent encounter'),
(237, NULL, NULL, '0', 'Child psychological abuse, Confirmed'),
(238, 'T74.32X', '995.51', '0', 'Child psychological abuse, Confirmed, Initial encounter'),
(239, 'T74.32X', '995.51', '0', 'Child psychological abuse, Confirmed, Subsequent encounter'),
(240, NULL, NULL, '0', 'Child psychological abuse, Suspected'),
(241, 'T76.32X', '995.51', '0', 'Child psychological abuse, Suspected, Initial encounter'),
(242, 'T76.32X', '995.51', '0', 'Child psychological abuse, Suspected, Subsequent encounter'),
(243, NULL, NULL, '0', 'Child sexual abuse, Confirmed'),
(244, 'T74.22X', '995.53', '0', 'Child sexual abuse, Confirmed, Initial encounter'),
(245, 'T74.22X', '995.53', '0', 'Child sexual abuse, Confirmed, Subsequent encounter'),
(246, NULL, NULL, '0', 'Child sexual abuse, Suspected'),
(247, 'T76.22X', '995.53', '0', 'Child sexual abuse, Suspected, Initial encounter'),
(248, 'T76.22X', '995.53', '0', 'Child sexual abuse, Suspected, Subsequent encounter'),
(249, 'F80.81', '315.35', '0', 'Childhood-onset fluency disorder (stuttering)'),
(250, NULL, NULL, '0', 'Circadian rhythm sleep-wake disorders'),
(251, 'G47.22', '307.45', '0', 'Circadian rhythm sleep-wake disorders, Advanced sleep phase type'),
(252, 'G47.21', '307.45', '0', 'Circadian rhythm sleep-wake disorders, Delayed sleep phase type'),
(253, 'G47.23', '307.45', '0', 'Circadian rhythm sleep-wake disorders, Irregular sleep-wake type'),
(254, 'G47.24', '307.45', '0', 'Circadian rhythm sleep-wake disorders, Non-24-hour sleep-wake type'),
(255, 'G47.26', '307.45', '0', 'Circadian rhythm sleep-wake disorders, Shift work type'),
(256, 'G47.20', '307.45', '0', 'Circadian rhythm sleep-wake disorders, Unspecified type'),
(257, NULL, '292.89', '0', 'Cocaine intoxication'),
(258, NULL, '292.81', '0', 'Cocaine intoxication delirium'),
(259, 'F14.121', NULL, '0', 'Cocaine intoxication delirium, With mild use disorder'),
(260, 'F14.221', NULL, '0', 'Cocaine intoxication delirium, With moderate or severe use disorder'),
(261, 'F14.921', NULL, '0', 'Cocaine intoxication delirium, Without use disorder'),
(262, NULL, NULL, '0', 'Cocaine intoxication, With perceptual disturbances'),
(263, 'F14.122', NULL, '0', 'Cocaine intoxication, With perceptual disturbances, With mild use disorder'),
(264, 'F14.222', NULL, '0', 'Cocaine intoxication, With perceptual disturbances, With moderate or severe use disorder'),
(265, 'F14.922', NULL, '0', 'Cocaine intoxication, With perceptual disturbances, Without use disorder'),
(266, NULL, NULL, '0', 'Cocaine intoxication, Without perceptual disturbances'),
(267, 'F14.129', NULL, '0', 'Cocaine intoxication, Without perceptual disturbances, With mild use disorder'),
(268, 'F14.229', NULL, '0', 'Cocaine intoxication, Without perceptual disturbances, With moderate or severe use disorder'),
(269, 'F14.929', NULL, '0', 'Cocaine intoxication, Without perceptual disturbances, Without use disorder'),
(270, NULL, NULL, '0', 'Cocaine use disorder'),
(271, 'F14.10', '305.6', '0', 'Cocaine use disorder, Mild'),
(272, 'F14.20', '304.2', '0', 'Cocaine use disorder, Moderate'),
(273, 'F14.20', '304.2', '0', 'Cocaine use disorder, Severe'),
(274, 'F14.23', '292', '0', 'Cocaine withdrawal'),
(275, NULL, '292.89', '0', 'Cocaine-induced anxiety disorder'),
(276, 'F14.180', NULL, '0', 'Cocaine-induced anxiety disorder, With mild use disorder'),
(277, 'F14.280', NULL, '0', 'Cocaine-induced anxiety disorder, With moderate or severe use disorder'),
(278, 'F14.980', NULL, '0', 'Cocaine-induced anxiety disorder, Without use disorder'),
(279, NULL, '292.84', '0', 'Cocaine-induced bipolar and related disorder'),
(280, 'F14.14', NULL, '0', 'Cocaine-induced bipolar and related disorder, With mild use disorder'),
(281, 'F14.24', NULL, '0', 'Cocaine-induced bipolar and related disorder, With moderate or severe use disorder'),
(282, 'F14.94', NULL, '0', 'Cocaine-induced bipolar and related disorder, Without use disorder'),
(283, NULL, '292.84', '0', 'Cocaine-induced depressive disorder'),
(284, 'F14.14', NULL, '0', 'Cocaine-induced depressive disorder, With mild use disorder'),
(285, 'F14.24', NULL, '0', 'Cocaine-induced depressive disorder, With moderate or severe use disorder'),
(286, 'F14.94', NULL, '0', 'Cocaine-induced depressive disorder, Without use disorder'),
(287, NULL, '292.89', '0', 'Cocaine-induced obsessive-compulsive and related disorder'),
(288, 'F14.188', NULL, '0', 'Cocaine-induced obsessive-compulsive and related disorder, With mild use disorder'),
(289, 'F14.288', NULL, '0', 'Cocaine-induced obsessive-compulsive and related disorder, With moderate or severe use disorder'),
(290, 'F14.988', NULL, '0', 'Cocaine-induced obsessive-compulsive and related disorder, Without use disorder'),
(291, NULL, '292.9', '0', 'Cocaine-induced psychotic disorder'),
(292, 'F14.159', NULL, '0', 'Cocaine-induced psychotic disorder, With mild use disorder'),
(293, 'F14.259', NULL, '0', 'Cocaine-induced psychotic disorder, With moderate or severe use disorder'),
(294, 'F14.959', NULL, '0', 'Cocaine-induced psychotic disorder, Without use disorder'),
(295, NULL, '292.89', '0', 'Cocaine-induced sexual dysfunction'),
(296, 'F14.181', NULL, '0', 'Cocaine-induced sexual dysfunction, With mild use disorder'),
(297, 'F14.281', NULL, '0', 'Cocaine-induced sexual dysfunction, With moderate or severe use disorder'),
(298, 'F14.981', NULL, '0', 'Cocaine-induced sexual dysfunction, Without use disorder'),
(299, NULL, '292.85', '0', 'Cocaine-induced sleep disorder'),
(300, 'F14.182', NULL, '0', 'Cocaine-induced sleep disorder, With mild use disorder'),
(301, 'F14.282', NULL, '0', 'Cocaine-induced sleep disorder, With moderate or severe use disorder'),
(302, 'F14.982', NULL, '0', 'Cocaine-induced sleep disorder, Without use disorder'),
(303, 'G47.36', '327.26', '0', 'Comorbid sleep-related hypoventilation'),
(304, NULL, NULL, '0', 'Conduct disorder'),
(305, 'F91.2', '312.82', '0', 'Conduct disorder, Adolescent-onset type'),
(306, 'F91.1', '312.81', '0', 'Conduct disorder, Childhood-onset type'),
(307, 'F91.9', '312.89', '0', 'Conduct disorder, Unspecified onset'),
(308, 'G47.35', '327.25', '0', 'Congenital central alveolar hypoventilation'),
(309, NULL, '300.11', '0', 'Conversion disorder (functional neurological symptom disorder)'),
(310, 'F44.4', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With abnormal movement'),
(311, 'F44.6', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With anesthesia or sensory loss'),
(312, 'F44.5', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With attacks or seizures'),
(313, 'F44.7', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With mixed symptoms'),
(314, 'F44.6', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With special sensory symptoms'),
(315, 'F44.4', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With speech symptoms'),
(316, 'F44.4', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With swallowing symptoms'),
(317, 'F44.4', NULL, '0', 'Conversion disorder (functional neurological symptom disorder), With weakness/paralysis'),
(318, 'Z65.0', 'V62.5', '0', 'Conviction in civil or criminal proceedings without imprisonment'),
(319, 'F34.0', '301.13', '0', 'Cyclothymic disorder'),
(320, 'F52.32', '302.74', '0', 'Delayed ejaculation'),
(321, NULL, NULL, '0', 'Delirium'),
(322, 'F05', '293', '0', 'Delirium due to another medical condition'),
(323, 'F05', '293', '0', 'Delirium due to multiple etiologies'),
(324, 'F22', '297.1', '0', 'Delusional disorder'),
(325, 'F60.7', '301.6', '0', 'Dependent personality disorder'),
(326, 'F48.1', '300.6', '0', 'Depersonalization/derealization disorder'),
(327, NULL, '293.83', '0', 'Depressive disorder due to another medical condition'),
(328, 'F06.31', NULL, '0', 'Depressive disorder due to another medical condition, With depressive features'),
(329, 'F06.32', NULL, '0', 'Depressive disorder due to another medical condition, With major depressive-like episode'),
(330, 'F06.34', NULL, '0', 'Depressive disorder due to another medical condition, With mixed features'),
(331, 'F82', '315.4', '0', 'Developmental coordination disorder'),
(332, 'Z59.2', 'V60.89', '0', 'Discord with neighbor, lodger, or landlord'),
(333, 'Z64.4', 'V62.89', '0', 'Discord with social service provider, including probation officer, case manager, or social services worker'),
(334, 'F94.2', '313.89', '0', 'Disinhibited social engagement disorder'),
(335, 'Z63.5', 'V61.03', '0', 'Disruption of family by separation or divorce'),
(336, 'F34.8', '296.99', '0', 'Disruptive mood dysregulation disorder'),
(337, 'F44.0', '300.12', '0', 'Dissociative amnesia'),
(338, 'F44.1', '300.13', '0', 'Dissociative amnesia, with dissociative fugue'),
(339, 'F44.81', '300.14', '0', 'Dissociative identity disorder'),
(340, 'F98.1', '307.7', '0', 'Encopresis'),
(341, 'F98.0', '307.6', '0', 'Enuresis'),
(342, 'F52.21', '302.72', '0', 'Erectile disorder'),
(343, 'L98.1', '698.4', '0', 'Excoriation (skin-picking) disorder'),
(344, 'F65.2', '302.4', '0', 'Exhibitionistic disorder'),
(345, 'Z65.5', 'V62.22', '0', 'Exposure to disaster, war, or other hostilities'),
(346, 'Z59.5', 'V60.2', '0', 'Extreme poverty'),
(347, 'F68.10', '300.19', '0', 'Factitious disorder'),
(348, 'F52.31', '302.73', '0', 'Female orgasmic disorder'),
(349, 'F52.22', '302.72', '0', 'Female sexual interest/arousal disorder'),
(350, 'F65.0', '302.81', '0', 'Fetishistic disorder'),
(351, 'F65.81', '302.89', '0', 'Frotteuristic disorder'),
(352, 'F63.0', '312.31', '1', 'Gambling disorder'),
(353, 'F64.1', '302.85', '0', 'Gender dysphoria in adolescents and adults'),
(354, 'F64.2', '302.6', '0', 'Gender dysphoria in children'),
(355, 'F41.1', '300.02', '0', 'Generalized anxiety disorder'),
(356, 'F52.6', '302.76', '0', 'Genito-pelvic pain/penetration disorder'),
(357, 'F88', '315.8', '0', 'Global developmental delay'),
(358, 'F16.983', '292.89', '0', 'Hallucinogen persisting perception disorder'),
(359, 'Z63.8', 'V61.8', '0', 'High expressed emotion level within family'),
(360, 'F60.4', '301.5', '0', 'Histrionic personality disorder'),
(361, 'F42', '300.3', '0', 'Hoarding disorder'),
(362, 'Z59.0', 'V60.0', '0', 'Homelessness'),
(363, 'G47.10', '780.54', '0', 'Hypersomnolence disorder'),
(364, 'G47.31', '327.21', '0', 'Idiopathic central sleep apnea'),
(365, 'G47.34', '327.24', '0', 'Idiopathic hypoventilation'),
(366, 'F45.21', '300.7', '0', 'Illness anxiety disorder'),
(367, 'Z65.1', 'V62.5', '0', 'Imprisonment or other incarceration'),
(368, 'Z59.1', 'V60.1', '0', 'Inadequate housing'),
(369, NULL, '292.89', '0', 'Inhalant intoxication'),
(370, NULL, '292.81', '0', 'Inhalant intoxication delirium'),
(371, 'F18.121', NULL, '0', 'Inhalant intoxication delirium, With mild use disorder'),
(372, 'F18.221', NULL, '0', 'Inhalant intoxication delirium, With moderate or severe use disorder'),
(373, 'F18.921', NULL, '0', 'Inhalant intoxication delirium, Without use disorder'),
(374, 'F18.129', NULL, '0', 'Inhalant intoxication, With mild use disorder'),
(375, 'F18.229', NULL, '0', 'Inhalant intoxication, With moderate or severe use disorder'),
(376, 'F18.929', NULL, '0', 'Inhalant intoxication, Without use disorder'),
(377, NULL, NULL, '0', 'Inhalant use disorder'),
(378, 'F18.10', '305.9', '0', 'Inhalant use disorder, Mild'),
(379, 'F18.20', '304.6', '0', 'Inhalant use disorder, Moderate'),
(380, 'F18.20', '304.6', '0', 'Inhalant use disorder, Severe'),
(381, NULL, '292.89', '0', 'Inhalant-induced anxiety disorder'),
(382, 'F18.180', NULL, '0', 'Inhalant-induced anxiety disorder, With mild use disorder'),
(383, 'F18.280', NULL, '0', 'Inhalant-induced anxiety disorder, With moderate or severe use disorder'),
(384, 'F18.980', NULL, '0', 'Inhalant-induced anxiety disorder, Without use disorder'),
(385, NULL, '292.84', '0', 'Inhalant-induced depressive disorder'),
(386, 'F18.14', NULL, '0', 'Inhalant-induced depressive disorder, With mild use disorder'),
(387, 'F18.24', NULL, '0', 'Inhalant-induced depressive disorder, With moderate or severe use disorder'),
(388, 'F18.94', NULL, '0', 'Inhalant-induced depressive disorder, Without use disorder'),
(389, NULL, '292.82', '0', 'Inhalant-induced major neurocognitive disorder'),
(390, 'F18.17', NULL, '0', 'Inhalant-induced major neurocognitive disorder, With mild use disorder'),
(391, 'F18.27', NULL, '0', 'Inhalant-induced major neurocognitive disorder, With moderate or severe use disorder'),
(392, 'F18.97', NULL, '0', 'Inhalant-induced major neurocognitive disorder, Without use disorder'),
(393, NULL, '292.89', '0', 'Inhalant-induced mild neurocognitive disorder'),
(394, 'F18.188', NULL, '0', 'Inhalant-induced mild neurocognitive disorder, With mild use disorder'),
(395, 'F18.288', NULL, '0', 'Inhalant-induced mild neurocognitive disorder, With moderate or severe use disorder'),
(396, 'F18.988', NULL, '0', 'Inhalant-induced mild neurocognitive disorder, Without use disorder'),
(397, NULL, '292.9', '0', 'Inhalant-induced psychotic disorder'),
(398, 'F18.159', NULL, '0', 'Inhalant-induced psychotic disorder, With mild use disorder'),
(399, 'F18.259', NULL, '0', 'Inhalant-induced psychotic disorder, With moderate or severe use disorder'),
(400, 'F18.959', NULL, '0', 'Inhalant-induced psychotic disorder, Without use disorder'),
(401, 'G47.00', '780.52', '0', 'Insomnia disorder'),
(402, 'Z59.7', 'V60.2', '0', 'Insufficient social insurance or welfare support'),
(403, NULL, '319', '0', 'Intellectual disability (intellectual developmental disorder)'),
(404, 'F70', '317', '0', 'Intellectual disability (intellectual developmental disorder), Mild'),
(405, 'F71', '318', '0', 'Intellectual disability (intellectual developmental disorder), Moderate'),
(406, 'F73', '318.2', '0', 'Intellectual disability (intellectual developmental disorder), Profound'),
(407, 'F72', '318.1', '0', 'Intellectual disability (intellectual developmental disorder), Severe'),
(408, 'F63.81', '312.34', '0', 'Intermittent explosive disorder'),
(409, 'F63.2', '312.32', '0', 'Kleptomania'),
(410, 'Z59.4', 'V60.2', '0', 'Lack of adequate food or safe drinking water'),
(411, 'F80.9', '315.39', '0', 'Language disorder'),
(412, 'Z59.6', 'V60.2', '0', 'Low income'),
(413, NULL, NULL, '0', 'Major depressive disorder, Recurrent episode'),
(414, 'F33.42', '296.36', '0', 'Major depressive disorder, Recurrent episode, In full remission'),
(415, 'F33.41', '296.35', '0', 'Major depressive disorder, Recurrent episode, In partial remission'),
(416, 'F33.0', '296.31', '0', 'Major depressive disorder, Recurrent episode, Mild'),
(417, 'F33.1', '296.32', '0', 'Major depressive disorder, Recurrent episode, Moderate'),
(418, 'F33.2', '296.33', '0', 'Major depressive disorder, Recurrent episode, Severe'),
(419, 'F33.9', '296.3', '0', 'Major depressive disorder, Recurrent episode, Unspecified'),
(420, 'F33.3', '296.34', '0', 'Major depressive disorder, Recurrent episode, With psychotic features'),
(421, NULL, NULL, '0', 'Major depressive disorder, Single episode'),
(422, 'F32.5', '296.26', '0', 'Major depressive disorder, Single episode, In full remission'),
(423, 'F32.4', '296.25', '0', 'Major depressive disorder, Single episode, In partial remission'),
(424, 'F32.0', '296.21', '0', 'Major depressive disorder, Single episode, Mild'),
(425, 'F32.1', '296.22', '0', 'Major depressive disorder, Single episode, Moderate'),
(426, 'F32.2', '296.23', '0', 'Major depressive disorder, Single episode, Severe'),
(427, 'F32.9', '296.2', '0', 'Major depressive disorder, Single episode, Unspecified'),
(428, 'F32.3', '296.24', '0', 'Major depressive disorder, Single episode, With psychotic features'),
(429, 'G31.9', '331.9', '0', 'Major frontotemporal neurocognitive disorder, Possible'),
(430, NULL, NULL, '0', '[Frontotemporal disease +] Major frontotemporal neurocognitive disorder, Probable'),
(431, '[G31.09', '[331.19 +', '0', '[Frontotemporal disease +] Major frontotemporal neurocognitive disorder, Probable, With behavioral disturbance'),
(432, '[G31.09', '[331.19 +', '0', '[Frontotemporal disease +] Major frontotemporal neurocognitive disorder, Probable, Without behavioral disturbance'),
(433, '[G31.09', '[331.19 +', '0', 'Major neurocognitive disorder due to Alzheimer\'s disease, Possible'),
(434, NULL, NULL, '0', '[Alzheimer\'s disease +] Major neurocognitive disorder due to Alzheimer\'s disease, Probable'),
(435, '[G30.9', '[331.0 +]', '0', '[Alzheimer\'s disease +] Major neurocognitive disorder due to Alzheimer\'s disease, Probable, With behavioral disturbance'),
(436, '[G30.9', '[331.0 +]', '0', '[Alzheimer\'s disease +] Major neurocognitive disorder due to Alzheimer\'s disease, Probable, Without behavioral disturbance'),
(437, NULL, NULL, '0', 'Major neurocognitive disorder due to another medical condition'),
(438, 'F02.81', '294.11', '0', 'Major neurocognitive disorder due to another medical condition, With behavioral disturbance'),
(439, 'F02.80', '294.1', '0', 'Major neurocognitive disorder due to another medical condition, Without behavioral disturbance'),
(440, NULL, NULL, '0', '[HIV infection +] Major neurocognitive disorder due to HIV infection'),
(441, '[B20 +]', '[042 +] 2', '0', '[HIV infection +] Major neurocognitive disorder due to HIV infection, With behavioral disturbance'),
(442, '[B20 +]', '[042 +] 2', '0', '[HIV infection +] Major neurocognitive disorder due to HIV infection, Without behavioral disturbance'),
(443, NULL, NULL, '0', '[Huntington\'s disease +] Major neurocognitive disorder due to Huntington\'s disease'),
(444, '[G10 +]', '[333.4 +]', '0', '[Huntington\'s disease +] Major neurocognitive disorder due to Huntington\'s disease, With behavioral disturbance'),
(445, '[G10 +]', '[333.4 +]', '0', '[Huntington\'s disease +] Major neurocognitive disorder due to Huntington\'s disease, Without behavioral disturbance'),
(446, NULL, NULL, '0', 'Major neurocognitive disorder due to multiple etiologies'),
(447, 'F02.81', '294.11', '0', 'Major neurocognitive disorder due to multiple etiologies, With behavioral disturbance'),
(448, 'F02.80', '294.1', '0', 'Major neurocognitive disorder due to multiple etiologies, Without behavioral disturbance'),
(449, 'G31.9', '331.9', '0', 'Major neurocognitive disorder due to Parkinson\'s disease, Possible'),
(450, NULL, NULL, '0', '[Parkinson\'s disease +] Major neurocognitive disorder due to Parkinson\'s disease, Probable'),
(451, '[G20 +]', '[332.0 +]', '0', '[Parkinson\'s disease +] Major neurocognitive disorder due to Parkinson\'s disease, Probable, With behavioral disturbance'),
(452, '[G20 +]', '[332.0 +]', '0', '[Parkinson\'s disease +] Major neurocognitive disorder due to Parkinson\'s disease, Probable, Without behavioral disturbance'),
(453, NULL, NULL, '0', '[Prion disease +] Major neurocognitive disorder due to prion disease'),
(454, '[A81.9', '[046.79 +', '0', '[Prion disease +] Major neurocognitive disorder due to prion disease, With behavioral disturbance'),
(455, '[A81.9', '[046.79 +', '0', '[Prion disease +] Major neurocognitive disorder due to prion disease, Without behavioral disturbance'),
(456, NULL, NULL, '0', '[Late effect of intracranial injury without skull fracture (ICD-9-CM) / Diffuse traumatic brain injury with loss of consciousness of unspecified durat'),
(457, '[S06.2X', '[907.0 +]', '0', '[Late effect of intracranial injury without skull fracture (ICD-9-CM) / Diffuse traumatic brain injury with loss of consciousness of unspecified durat'),
(458, '[S06.2X', '[907.0 +]', '0', '[Late effect of intracranial injury without skull fracture (ICD-9-CM) / Diffuse traumatic brain injury with loss of consciousness of unspecified durat'),
(459, 'G31.9', '331.9', '0', 'Major neurocognitive disorder with Lewy bodies, Possible'),
(460, NULL, NULL, '0', '[Lewy body disease +] Major neurocognitive disorder with Lewy bodies, Probable'),
(461, '[G31.83', '[331.82 +', '0', '[Lewy body disease +] Major neurocognitive disorder with Lewy bodies, Probable, With behavioral disturbance'),
(462, '[G31.83', '[331.82 +', '0', '[Lewy body disease +] Major neurocognitive disorder with Lewy bodies, Probable, Without behavioral disturbance'),
(463, 'G31.9', '331.9', '0', 'Major vascular neurocognitive disorder, Possible'),
(464, NULL, NULL, '0', 'Major vascular neurocognitive disorder, Probable'),
(465, 'F01.51', '290.4', '0', 'Major vascular neurocognitive disorder, Probable, With behavioral disturbance'),
(466, 'F01.50', '290.4', '0', 'Major vascular neurocognitive disorder, Probable, Without behavioral disturbance'),
(467, 'F52.0', '302.71', '0', 'Male hypoactive sexual desire disorder'),
(468, 'Z76.5', 'V65.2', '0', 'Malingering'),
(469, 'G25.71', '333.99', '0', 'Medication-induced acute akathisia'),
(470, 'G24.02', '333.72', '0', 'Medication-induced acute dystonia'),
(471, 'see spe', '292.81', '0', 'Medication-induced delirium'),
(472, 'see spe', '292.81', '0', 'Medication-induced delirium'),
(473, 'G25.1', '333.1', '0', 'Medication-induced postural tremor'),
(474, 'G31.84', '331.83', '0', 'Mild frontotemporal neurocognitive disorder'),
(475, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to Alzheimer\'s disease'),
(476, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to another medical condition'),
(477, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to HIV infection'),
(478, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to Huntington\'s disease'),
(479, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to multiple etiologies'),
(480, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to Parkinson\'s disease'),
(481, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to prion disease'),
(482, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder due to traumatic brain injury'),
(483, 'G31.84', '331.83', '0', 'Mild neurocognitive disorder with Lewy bodies'),
(484, 'G31.84', '331.83', '0', 'Mild vascular neurocognitive disorder'),
(485, 'F60.81', '301.81', '0', 'Narcissistic personality disorder'),
(486, NULL, NULL, '0', 'Narcolepsy'),
(487, 'G47.429', '347.1', '0', 'Narcolepsy secondary to another medical condition'),
(488, 'G47.411', '347.01', '0', 'Narcolepsy with cataplexy but without hypocretin deficiency'),
(489, 'G47.419', '347', '0', 'Narcolepsy without cataplexy but with hypocretin deficiency'),
(490, 'G21.0', '333.92', '0', 'Neuroleptic malignant syndrome'),
(491, 'G21.11', '332.1', '0', 'Neuroleptic-induced parkinsonism'),
(492, 'F51.5', '307.47', '0', 'Nightmare disorder'),
(493, 'Z03.89', 'V71.09', '0', 'No Diagnosis or Condition on Axis I / No Diagnosis on Axis II [DSM-IV]'),
(494, 'Z91.19', 'V15.81', '0', 'Nonadherence to medical treatment'),
(495, NULL, NULL, '0', 'Non-rapid eye movement sleep arousal disorders'),
(496, 'F51.4', '307.46', '0', 'Non-rapid eye movement sleep arousal disorders, Sleep terror type'),
(497, 'F51.3', '307.46', '0', 'Non-rapid eye movement sleep arousal disorders, Sleepwalking type'),
(498, 'F06.8', '294.8', '0', 'Obsessive-compulsive and related disorder due to another medical condition'),
(499, 'F42', '300.3', '1', 'Obsessive-compulsive disorder'),
(500, 'F60.5', '301.4', '0', 'Obsessive-compulsive personality disorder'),
(501, 'G47.33', '327.23', '0', 'Obstructive sleep apnea hypopnea'),
(502, NULL, '292.89', '0', 'Opioid intoxication'),
(503, NULL, '292.81', '0', 'Opioid intoxication delirium'),
(504, 'F11.121', NULL, '0', 'Opioid intoxication delirium, With mild use disorder'),
(505, 'F11.221', NULL, '0', 'Opioid intoxication delirium, With moderate or severe use disorder'),
(506, 'F11.921', NULL, '0', 'Opioid intoxication delirium, Without use disorder'),
(507, NULL, NULL, '0', 'Opioid intoxication, With perceptual disturbances'),
(508, 'F11.122', NULL, '0', 'Opioid intoxication, With perceptual disturbances, With mild use disorder'),
(509, 'F11.222', NULL, '0', 'Opioid intoxication, With perceptual disturbances, With moderate or severe use disorder'),
(510, 'F11.922', NULL, '0', 'Opioid intoxication, With perceptual disturbances, Without use disorder'),
(511, NULL, NULL, '0', 'Opioid intoxication, Without perceptual disturbances'),
(512, 'F11.129', NULL, '0', 'Opioid intoxication, Without perceptual disturbances, With mild use disorder'),
(513, 'F11.229', NULL, '0', 'Opioid intoxication, Without perceptual disturbances, With moderate or severe use disorder'),
(514, 'F11.929', NULL, '0', 'Opioid intoxication, Without perceptual disturbances, Without use disorder'),
(515, NULL, NULL, '0', 'Opioid use disorder'),
(516, 'F11.10', '305.5', '0', 'Opioid use disorder, Mild'),
(517, 'F11.20', '304', '0', 'Opioid use disorder, Moderate'),
(518, 'F11.20', '304', '0', 'Opioid use disorder, Severe'),
(519, 'F11.23', '292', '0', 'Opioid withdrawal'),
(520, 'F11.23', '292', '0', 'Opioid withdrawal delirium'),
(521, NULL, '292.89', '0', 'Opioid-induced anxiety disorder'),
(522, 'F11.188', NULL, '0', 'Opioid-induced anxiety disorder, With mild use disorder'),
(523, 'F11.288', NULL, '0', 'Opioid-induced anxiety disorder, With moderate or severe use disorder'),
(524, 'F11.988', NULL, '0', 'Opioid-induced anxiety disorder, Without use disorder'),
(525, 'F11.921', NULL, '0', 'Opioid-induced delirium'),
(526, NULL, '292.84', '0', 'Opioid-induced depressive disorder'),
(527, 'F11.14', NULL, '0', 'Opioid-induced depressive disorder, With mild use disorder'),
(528, 'F11.24', NULL, '0', 'Opioid-induced depressive disorder, With moderate or severe use disorder'),
(529, 'F11.94', NULL, '0', 'Opioid-induced depressive disorder, Without use disorder'),
(530, NULL, '292.89', '0', 'Opioid-induced sexual dysfunction'),
(531, 'F11.181', NULL, '0', 'Opioid-induced sexual dysfunction, With mild use disorder'),
(532, 'F11.281', NULL, '0', 'Opioid-induced sexual dysfunction, With moderate or severe use disorder'),
(533, 'F11.981', NULL, '0', 'Opioid-induced sexual dysfunction, Without use disorder'),
(534, NULL, '292.85', '0', 'Opioid-induced sleep disorder'),
(535, 'F11.182', NULL, '0', 'Opioid-induced sleep disorder, With mild use disorder'),
(536, 'F11.282', NULL, '0', 'Opioid-induced sleep disorder, With moderate or severe use disorder'),
(537, 'F11.982', NULL, '0', 'Opioid-induced sleep disorder, Without use disorder'),
(538, 'F91.3', '313.81', '0', 'Oppositional defiant disorder'),
(539, NULL, '292.89', '0', 'Other (or unknown) substance intoxication'),
(540, NULL, '292.81', '0', 'Other (or unknown) substance intoxication delirium'),
(541, 'F19.121', NULL, '0', 'Other (or unknown) substance intoxication delirium, With mild use disorder'),
(542, 'F19.221', NULL, '0', 'Other (or unknown) substance intoxication delirium, With moderate or severe use disorder'),
(543, 'F19.921', NULL, '0', 'Other (or unknown) substance intoxication delirium, Without use disorder'),
(544, 'F19.129', NULL, '0', 'Other (or unknown) substance intoxication, With mild use disorder'),
(545, 'F19.229', NULL, '0', 'Other (or unknown) substance intoxication, With moderate or severe use disorder'),
(546, 'F19.929', NULL, '0', 'Other (or unknown) substance intoxication, Without use disorder'),
(547, NULL, NULL, '0', 'Other (or unknown) substance use disorder'),
(548, 'F19.10', '305.9', '0', 'Other (or unknown) substance use disorder, Mild'),
(549, 'F19.20', '304.9', '0', 'Other (or unknown) substance use disorder, Moderate'),
(550, 'F19.20', '304.9', '0', 'Other (or unknown) substance use disorder, Severe'),
(551, 'F19.239', '292', '0', 'Other (or unknown) substance withdrawal'),
(552, 'F19.231', '292', '0', 'Other (or unknown) substance withdrawal delirium'),
(553, NULL, '292.89', '0', 'Other (or unknown) substance-induced anxiety disorder'),
(554, 'F19.180', NULL, '0', 'Other (or unknown) substance-induced anxiety disorder, With mild use disorder'),
(555, 'F19.280', NULL, '0', 'Other (or unknown) substance-induced anxiety disorder, With moderate or severe use disorder'),
(556, 'F19.980', NULL, '0', 'Other (or unknown) substance-induced anxiety disorder, Without use disorder'),
(557, NULL, '292.84', '1', 'Other (or unknown) substance-induced bipolar and related disorder'),
(558, 'F19.14', NULL, '0', 'Other (or unknown) substance-induced bipolar and related disorder, With mild use disorder'),
(559, 'F19.24', NULL, '0', 'Other (or unknown) substance-induced bipolar and related disorder, With moderate or severe use disorder'),
(560, 'F19.94', NULL, '0', 'Other (or unknown) substance-induced bipolar and related disorder, Without use disorder'),
(561, 'F19.921', NULL, '0', 'Other (or unknown) substance-induced delirium'),
(562, NULL, '292.84', '1', 'Other (or unknown) substance-induced depressive disorder'),
(563, 'F19.14', NULL, '0', 'Other (or unknown) substance-induced depressive disorder, With mild use disorder'),
(564, 'F19.24', NULL, '0', 'Other (or unknown) substance-induced depressive disorder, With moderate or severe use disorder'),
(565, 'F19.94', NULL, '0', 'Other (or unknown) substance-induced depressive disorder, Without use disorder'),
(566, NULL, '292.82', '0', 'Other (or unknown) substance-induced major neurocognitive disorder'),
(567, 'F19.17', NULL, '0', 'Other (or unknown) substance-induced major neurocognitive disorder, With mild use disorder');
INSERT INTO `disease_catalog` (`disease_catalog_id`, `icd10`, `icd9`, `frequent_diagnostic`, `description`) VALUES
(568, 'F19.27', NULL, '0', 'Other (or unknown) substance-induced major neurocognitive disorder, With moderate or severe use disorder'),
(569, 'F19.97', NULL, '0', 'Other (or unknown) substance-induced major neurocognitive disorder, Without use disorder'),
(570, NULL, '292.89', '0', 'Other (or unknown) substance-induced mild neurocognitive disorder'),
(571, 'F19.188', NULL, '0', 'Other (or unknown) substance-induced mild neurocognitive disorder, With mild use disorder'),
(572, 'F19.288', NULL, '0', 'Other (or unknown) substance-induced mild neurocognitive disorder, With moderate or severe use disorder'),
(573, 'F19.988', NULL, '0', 'Other (or unknown) substance-induced mild neurocognitive disorder, Without use disorder'),
(574, NULL, '292.89', '0', 'Other (or unknown) substance-induced obsessive-compulsive and related disorder'),
(575, 'F19.188', NULL, '0', 'Other (or unknown) substance-induced obsessive-compulsive and related disorder, With mild use disorder'),
(576, 'F19.288', NULL, '0', 'Other (or unknown) substance-induced obsessive-compulsive and related disorder, With moderate or severe use disorder'),
(577, 'F19.988', NULL, '0', 'Other (or unknown) substance-induced obsessive-compulsive and related disorder, Without use disorder'),
(578, NULL, '292.9', '0', 'Other (or unknown) substance-induced psychotic disorder'),
(579, 'F19.159', NULL, '0', 'Other (or unknown) substance-induced psychotic disorder, With mild use disorder'),
(580, 'F19.259', NULL, '0', 'Other (or unknown) substance-induced psychotic disorder, With moderate or severe use disorder'),
(581, 'F19.959', NULL, '0', 'Other (or unknown) substance-induced psychotic disorder, Without use disorder'),
(582, NULL, '292.89', '0', 'Other (or unknown) substance-induced sexual dysfunction'),
(583, 'F19.181', NULL, '0', 'Other (or unknown) substance-induced sexual dysfunction, With mild use disorder'),
(584, 'F19.281', NULL, '0', 'Other (or unknown) substance-induced sexual dysfunction, With moderate or severe use disorder'),
(585, 'F19.981', NULL, '0', 'Other (or unknown) substance-induced sexual dysfunction, Without use disorder'),
(586, NULL, '292.85', '0', 'Other (or unknown) substance-induced sleep disorder'),
(587, 'F19.182', NULL, '0', 'Other (or unknown) substance-induced sleep disorder, With mild use disorder'),
(588, 'F19.282', NULL, '0', 'Other (or unknown) substance-induced sleep disorder, With moderate or severe use disorder'),
(589, 'F19.982', NULL, '0', 'Other (or unknown) substance-induced sleep disorder, Without use disorder'),
(590, NULL, NULL, '0', 'Other adverse effect of medication'),
(591, 'T50.905', '995.2', '0', 'Other adverse effect of medication, Initial encounter'),
(592, 'T50.905', '995.2', '0', 'Other adverse effect of medication, Sequelae'),
(593, 'T50.905', '995.2', '0', 'Other adverse effect of medication, Subsequent encounter'),
(594, NULL, NULL, '0', 'Other circumstances related to adult abuse by nonspouse or nonpartner'),
(595, 'Z69.82', 'V62.83', '0', 'Other circumstances related to adult abuse by nonspouse or nonpartner, Encounter for mental health services for perpetrator of nonspousal adult abuse'),
(596, 'Z69.81', 'V65.49', '0', 'Other circumstances related to adult abuse by nonspouse or nonpartner, Encounter for mental health services for victim of nonspousal adult abuse'),
(597, NULL, NULL, '0', 'Other circumstances related to child neglect'),
(598, 'Z69.021', 'V62.83', '0', 'Other circumstances related to child neglect, Encounter for mental health services for perpetrator of nonparental child neglect'),
(599, 'Z69.011', 'V61.22', '0', 'Other circumstances related to child neglect, Encounter for mental health services for perpetrator of parental child neglect'),
(600, 'Z69.010', 'V61.21', '0', 'Other circumstances related to child neglect, Encounter for mental health services for victim of child neglect by parent'),
(601, 'Z69.020', 'V61.21', '0', 'Other circumstances related to child neglect, Encounter for mental health services for victim of nonparental child neglect'),
(602, NULL, NULL, '0', 'Other circumstances related to child physical abuse'),
(603, 'Z69.021', 'V62.83', '0', 'Other circumstances related to child physical abuse, Encounter for mental health services for perpetrator of nonparental child abuse'),
(604, 'Z69.011', 'V61.22', '0', 'Other circumstances related to child physical abuse, Encounter for mental health services for perpetrator of parental child abuse'),
(605, 'Z69.010', 'V61.21', '0', 'Other circumstances related to child physical abuse, Encounter for mental health services for victim of child abuse by parent'),
(606, 'Z69.020', 'V61.21', '0', 'Other circumstances related to child physical abuse, Encounter for mental health services for victim of nonparental child abuse'),
(607, NULL, NULL, '0', 'Other circumstances related to child psychological abuse'),
(608, 'Z69.021', 'V62.83', '0', 'Other circumstances related to child psychological abuse, Encounter for mental health services for perpetrator of nonparental child psychological abus'),
(609, 'Z69.011', 'V61.22', '0', 'Other circumstances related to child psychological abuse, Encounter for mental health services for perpetrator of parental child psychological abuse'),
(610, 'Z69.010', 'V61.21', '0', 'Other circumstances related to child psychological abuse, Encounter for mental health services for victim of child psychological abuse by parent'),
(611, 'Z69.020', 'V61.21', '0', 'Other circumstances related to child psychological abuse, Encounter for mental health services for victim of nonparental child psychological abuse'),
(612, NULL, NULL, '0', 'Other circumstances related to child sexual abuse'),
(613, 'Z69.021', 'V62.83', '0', 'Other circumstances related to child sexual abuse, Encounter for mental health services for perpetrator of nonparental child sexual abuse'),
(614, 'Z69.011', 'V61.22', '0', 'Other circumstances related to child sexual abuse, Encounter for mental health services for perpetrator of parental child sexual abuse'),
(615, 'Z69.010', 'V61.21', '0', 'Other circumstances related to child sexual abuse, Encounter for mental health services for victim of child sexual abuse by parent'),
(616, 'Z69.020', 'V61.21', '0', 'Other circumstances related to child sexual abuse, Encounter for mental health services for victim of nonparental child sexual abuse'),
(617, NULL, NULL, '0', 'Other circumstances related to spouse or partner abuse, Psychological'),
(618, 'Z69.12', 'V61.12', '0', 'Other circumstances related to spouse or partner abuse, Psychological, Encounter for mental health services for perpetrator of spouse or partner psych'),
(619, 'Z69.11', 'V61.11', '0', 'Other circumstances related to spouse or partner abuse, Psychological, Encounter for mental health services for victim of spouse or partner psychologi'),
(620, NULL, NULL, '0', 'Other circumstances related to spouse or partner neglect'),
(621, 'Z69.12', 'V61.12', '0', 'Other circumstances related to spouse or partner neglect, Encounter for mental health services for perpetrator of spouse or partner neglect'),
(622, 'Z69.11', 'V61.11', '0', 'Other circumstances related to spouse or partner neglect, Encounter for mental health services for victim of spouse or partner neglect'),
(623, NULL, NULL, '0', 'Other circumstances related to spouse or partner violence, Physical'),
(624, 'Z69.12', 'V61.12', '0', 'Other circumstances related to spouse or partner violence, Physical, Encounter for mental health services for perpetrator of spouse or partner violenc'),
(625, 'Z69.11', 'V61.11', '0', 'Other circumstances related to spouse or partner violence, Physical, Encounter for mental health services for victim of spouse or partner violence'),
(626, NULL, NULL, '0', 'Other circumstances related to spouse or partner violence, Sexual'),
(627, 'Z69.12', 'V61.12', '0', 'Other circumstances related to spouse or partner violence, Sexual, Encounter for mental health services for perpetrator of spouse or partner violence'),
(628, 'Z69.81', 'V61.11', '0', 'Other circumstances related to spouse or partner violence, Sexual, Encounter for mental health services for victim of spouse or partner violence'),
(629, 'Z71.9', 'V65.40', '0', 'Other counseling or consultation'),
(630, NULL, '292.89', '0', 'Other hallucinogen intoxication'),
(631, NULL, '292.81', '0', 'Other hallucinogen intoxication delirium'),
(632, 'F16.121', NULL, '0', 'Other hallucinogen intoxication delirium, With mild use disorder'),
(633, 'F16.221', NULL, '0', 'Other hallucinogen intoxication delirium, With moderate or severe use disorder'),
(634, 'F16.921', NULL, '0', 'Other hallucinogen intoxication delirium, Without use disorder'),
(635, 'F16.129', NULL, '0', 'Other hallucinogen intoxication, With mild use disorder'),
(636, 'F16.229', NULL, '0', 'Other hallucinogen intoxication, With moderate or severe use disorder'),
(637, 'F16.929', NULL, '0', 'Other hallucinogen intoxication, Without use disorder'),
(638, NULL, NULL, '0', 'Other hallucinogen use disorder'),
(639, 'F16.10', '305.3', '0', 'Other hallucinogen use disorder, Mild'),
(640, 'F16.20', '304.5', '0', 'Other hallucinogen use disorder, Moderate'),
(641, 'F16.20', '304.5', '0', 'Other hallucinogen use disorder, Severe'),
(642, NULL, '292.89', '0', 'Other hallucinogen-induced anxiety disorder'),
(643, 'F16.180', NULL, '0', 'Other hallucinogen-induced anxiety disorder, With mild use disorder'),
(644, 'F16.280', NULL, '0', 'Other hallucinogen-induced anxiety disorder, With moderate or severe use disorder'),
(645, 'F16.980', NULL, '0', 'Other hallucinogen-induced anxiety disorder, Without use disorder'),
(646, NULL, '292.84', '0', 'Other hallucinogen-induced bipolar and related disorder'),
(647, 'F16.14', NULL, '0', 'Other hallucinogen-induced bipolar and related disorder, With mild use disorder'),
(648, 'F16.24', NULL, '0', 'Other hallucinogen-induced bipolar and related disorder, With moderate or severe use disorder'),
(649, 'F16.94', NULL, '0', 'Other hallucinogen-induced bipolar and related disorder, Without use disorder'),
(650, NULL, '292.84', '0', 'Other hallucinogen-induced depressive disorder'),
(651, 'F16.14', NULL, '0', 'Other hallucinogen-induced depressive disorder, With mild use disorder'),
(652, 'F16.24', NULL, '0', 'Other hallucinogen-induced depressive disorder, With moderate or severe use disorder'),
(653, 'F16.94', NULL, '0', 'Other hallucinogen-induced depressive disorder, Without use disorder'),
(654, NULL, '292.9', '0', 'Other hallucinogen-induced psychotic disorder'),
(655, 'F16.159', NULL, '0', 'Other hallucinogen-induced psychotic disorder, With mild use disorder'),
(656, 'F16.259', NULL, '0', 'Other hallucinogen-induced psychotic disorder, With moderate or severe use disorder'),
(657, 'F16.959', NULL, '0', 'Other hallucinogen-induced psychotic disorder, Without use disorder'),
(658, 'G25.79', '333.99', '0', 'Other medication-induced movement disorder'),
(659, 'G21.19', '332.1', '0', 'Other medication-induced parkinsonism'),
(660, NULL, NULL, '0', 'Other or unspecified stimulant use disorder'),
(661, 'F15.10', '305.7', '0', 'Other or unspecified stimulant use disorder, Mild'),
(662, 'F15.20', '304.4', '0', 'Other or unspecified stimulant use disorder, Moderate'),
(663, 'F15.20', '304.4', '0', 'Other or unspecified stimulant use disorder, Severe'),
(664, 'Z91.49', 'V15.49', '0', 'Other personal history of psychological trauma'),
(665, 'Z91.89', 'V15.89', '0', 'Other personal risk factors'),
(666, 'Z56.9', 'V62.29', '0', 'Other problem related to employment'),
(667, 'Z65.8', 'V62.89', '0', 'Other problem related to psychosocial circumstances'),
(668, 'F41.8', '300.09', '0', 'Other specified anxiety disorder'),
(669, 'F90.8', '314.01', '0', 'Other specified attention-deficit/hyperactivity disorder'),
(670, 'F31.89', '296.89', '0', 'Other specified bipolar and related disorder'),
(671, 'R41.0', '780.09', '0', 'Other specified delirium'),
(672, 'F32.8', '311', '0', 'Other specified depressive disorder'),
(673, 'F91.8', '312.89', '0', 'Other specified disruptive, impulse-control, and conduct disorder'),
(674, 'F44.89', '300.15', '0', 'Other specified dissociative disorder'),
(675, NULL, NULL, '0', 'Other specified elimination disorder'),
(676, 'R15.9', '787.6', '0', 'Other specified elimination disorder, With fecal symptoms'),
(677, 'N39.498', '788.39', '0', 'Other specified elimination disorder, With urinary symptoms'),
(678, 'F50.8', '307.59', '0', 'Other specified feeding or eating disorder'),
(679, 'F64.8', '302.6', '0', 'Other specified gender dysphoria'),
(680, 'G47.19', '780.54', '0', 'Other specified hypersomnolence disorder'),
(681, 'G47.09', '780.52', '0', 'Other specified insomnia disorder'),
(682, 'F99', '300.9', '0', 'Other specified mental disorder'),
(683, 'F06.8', '294.8', '0', 'Other specified mental disorder due to another medical condition'),
(684, 'F88', '315.8', '0', 'Other specified neurodevelopmental disorder'),
(685, 'F42', '300.3', '0', 'Other specified obsessive-compulsive and related disorder'),
(686, 'F65.89', '302.89', '0', 'Other specified paraphilic disorder'),
(687, 'F60.89', '301.89', '0', 'Other specified personality disorder'),
(688, 'F28', '298.8', '0', 'Other specified schizophrenia spectrum and other psychotic disorder'),
(689, 'F52.8', '302.79', '0', 'Other specified sexual dysfunction'),
(690, 'G47.8', '780.59', '0', 'Other specified sleep-wake disorder'),
(691, 'F45.8', '300.89', '0', 'Other specified somatic symptom and related disorder'),
(692, 'F95.8', '307.2', '0', 'Other specified tic disorder'),
(693, 'F43.8', '309.89', '0', 'Other specified trauma- and stressor-related disorder'),
(694, 'E66.9', '278', '0', 'Overweight or obesity'),
(695, NULL, NULL, '0', 'Panic attack specifier'),
(696, 'F41.0', '300.01', '1', 'Panic disorder'),
(697, 'F60.0', '301', '0', 'Paranoid personality disorder'),
(698, 'Z62.820', 'V61.20', '0', 'Parent-child relational problem'),
(699, 'F65.4', '302.2', '0', 'Pedophilic disorder'),
(700, 'F95.1', '307.22', '0', 'Persistent (chronic) motor or vocal tic disorder'),
(701, 'F34.1', '300.4', '0', 'Persistent depressive disorder (dysthymia)'),
(702, 'Z62.812', 'V15.42', '0', 'Personal history (past history) of neglect in childhood'),
(703, 'Z62.810', 'V15.41', '0', 'Personal history (past history) of physical abuse in childhood'),
(704, 'Z62.811', 'V15.42', '0', 'Personal history (past history) of psychological abuse in childhood'),
(705, 'Z62.810', 'V15.41', '0', 'Personal history (past history) of sexual abuse in childhood'),
(706, 'Z91.412', 'V15.42', '0', 'Personal history (past history) of spouse or partner neglect'),
(707, 'Z91.411', 'V15.42', '0', 'Personal history (past history) of spouse or partner psychological abuse'),
(708, 'Z91.410', 'V15.41', '0', 'Personal history (past history) of spouse or partner violence, Physical'),
(709, 'Z91.410', 'V15.41', '0', 'Personal history (past history) of spouse or partner violence, Sexual'),
(710, 'Z91.82', 'V62.22', '0', 'Personal history of military deployment'),
(711, 'Z91.5', 'V15.59', '0', 'Personal history of self-harm'),
(712, 'F07.0', '310.1', '0', 'Personality change due to another medical condition'),
(713, 'Z60.0', 'V62.89', '0', 'Phase of life problem'),
(714, NULL, '292.89', '0', 'Phencyclidine intoxication'),
(715, NULL, '292.81', '0', 'Phencyclidine intoxication delirium'),
(716, 'F16.121', NULL, '0', 'Phencyclidine intoxication delirium, With mild use disorder'),
(717, 'F16.221', NULL, '0', 'Phencyclidine intoxication delirium, With moderate or severe use disorder'),
(718, 'F16.921', NULL, '0', 'Phencyclidine intoxication delirium, Without use disorder'),
(719, 'F16.129', NULL, '0', 'Phencyclidine intoxication, With mild use disorder'),
(720, 'F16.229', NULL, '0', 'Phencyclidine intoxication, With moderate or severe use disorder'),
(721, 'F16.929', NULL, '0', 'Phencyclidine intoxication, Without use disorder'),
(722, NULL, NULL, '0', 'Phencyclidine use disorder'),
(723, 'F16.10', '305.9', '0', 'Phencyclidine use disorder, Mild'),
(724, 'F16.20', '304.6', '0', 'Phencyclidine use disorder, Moderate'),
(725, 'F16.20', '304.6', '0', 'Phencyclidine use disorder, Severe'),
(726, NULL, '292.89', '0', 'Phencyclidine-induced anxiety disorder'),
(727, 'F16.180', NULL, '0', 'Phencyclidine-induced anxiety disorder, With mild use disorder'),
(728, 'F16.280', NULL, '0', 'Phencyclidine-induced anxiety disorder, With moderate or severe use disorder'),
(729, 'F16.980', NULL, '0', 'Phencyclidine-induced anxiety disorder, Without use disorder'),
(730, NULL, '292.84', '0', 'Phencyclidine-induced bipolar and related disorder'),
(731, 'F16.14', NULL, '0', 'Phencyclidine-induced bipolar and related disorder, With mild use disorder'),
(732, 'F16.24', NULL, '0', 'Phencyclidine-induced bipolar and related disorder, With moderate or severe use disorder'),
(733, 'F16.94', NULL, '0', 'Phencyclidine-induced bipolar and related disorder, Without use disorder'),
(734, NULL, '292.84', '0', 'Phencyclidine-induced depressive disorder'),
(735, 'F16.14', NULL, '0', 'Phencyclidine-induced depressive disorder, With mild use disorder'),
(736, 'F16.24', NULL, '0', 'Phencyclidine-induced depressive disorder, With moderate or severe use disorder'),
(737, 'F16.94', NULL, '0', 'Phencyclidine-induced depressive disorder, Without use disorder'),
(738, NULL, '292.9', '0', 'Phencyclidine-induced psychotic disorder'),
(739, 'F16.159', NULL, '0', 'Phencyclidine-induced psychotic disorder, With mild use disorder'),
(740, 'F16.259', NULL, '0', 'Phencyclidine-induced psychotic disorder, With moderate or severe use disorder'),
(741, 'F16.959', NULL, '0', 'Phencyclidine-induced psychotic disorder, Without use disorder'),
(742, NULL, '307.52', '0', 'Pica'),
(743, 'F50.8', NULL, '0', 'Pica, In adults'),
(744, 'F98.3', NULL, '0', 'Pica, In children'),
(745, 'F43.10', '309.81', '0', 'Posttraumatic stress disorder'),
(746, 'F52.4', '302.75', '0', 'Premature (early) ejaculation'),
(747, 'N94.3', '625.4', '0', 'Premenstrual dysphoric disorder'),
(748, 'Z56.82', 'V62.21', '0', 'Problem related to current military deployment status'),
(749, 'Z72.9', 'V69.9', '0', 'Problem related to lifestyle'),
(750, 'Z60.2', 'V60.3', '0', 'Problem related to living alone'),
(751, 'Z59.3', 'V60.6', '0', 'Problem related to living in a residential institution'),
(752, 'Z64.1', 'V61.5', '0', 'Problems related to multiparity'),
(753, 'Z65.3', 'V62.5', '0', 'Problems related to other legal circumstances'),
(754, 'Z65.2', 'V62.5', '0', 'Problems related to release from prison'),
(755, 'Z64.0', 'V61.7', '0', 'Problems related to unwanted pregnancy'),
(756, 'F95.0', '307.21', '0', 'Provisional tic disorder'),
(757, 'F54', '316', '0', 'Psychological factors affecting other medical conditions'),
(758, NULL, NULL, '0', 'Psychotic disorder due to another medical condition'),
(759, 'F06.2', '293.81', '0', 'Psychotic disorder due to another medical condition, With delusions'),
(760, 'F06.0', '293.82', '0', 'Psychotic disorder due to another medical condition, With hallucinations'),
(761, 'F63.1', '312.33', '0', 'Pyromania'),
(762, 'G47.52', '327.42', '0', 'Rapid eye movement sleep behavior disorder'),
(763, 'F94.1', '313.89', '0', 'Reactive attachment disorder'),
(764, 'Z63.0', 'V61.10', '0', 'Relationship distress with spouse or intimate partner'),
(765, 'Z65.8', 'V62.89', '0', 'Religious or spiritual problem'),
(766, 'G25.81', '333.94', '0', 'Restless legs syndrome'),
(767, 'F98.21', '307.53', '0', 'Rumination disorder'),
(768, NULL, NULL, '0', 'Schizoaffective disorder'),
(769, 'F25.0', '295.7', '0', 'Schizoaffective disorder, Bipolar type'),
(770, 'F25.1', '295.7', '1', 'Schizoaffective disorder, Depressive type'),
(771, 'F60.1', '301.2', '0', 'Schizoid personality disorder'),
(772, 'F20.9', '295.9', '1', 'Schizophrenia'),
(773, 'F20.81', '295.4', '0', 'Schizophreniform disorder'),
(774, 'F21', '301.22', '0', 'Schizotypal personality disorder'),
(775, NULL, '292.89', '0', 'Sedative, hypnotic, or anxiolytic intoxication'),
(776, NULL, '292.81', '0', 'Sedative, hypnotic, or anxiolytic intoxication delirium'),
(777, 'F13.121', NULL, '0', 'Sedative, hypnotic, or anxiolytic intoxication delirium, With mild use disorder'),
(778, 'F13.221', NULL, '0', 'Sedative, hypnotic, or anxiolytic intoxication delirium, With moderate or severe use disorder'),
(779, 'F13.921', NULL, '0', 'Sedative, hypnotic, or anxiolytic intoxication delirium, Without use disorder'),
(780, 'F13.129', NULL, '0', 'Sedative, hypnotic, or anxiolytic intoxication, With mild use disorder'),
(781, 'F13.229', NULL, '0', 'Sedative, hypnotic, or anxiolytic intoxication, With moderate or severe use disorder'),
(782, 'F13.929', NULL, '0', 'Sedative, hypnotic, or anxiolytic intoxication, Without use disorder'),
(783, NULL, NULL, '0', 'Sedative, hypnotic, or anxiolytic use disorder'),
(784, 'F13.10', '305.4', '0', 'Sedative, hypnotic, or anxiolytic use disorder, Mild'),
(785, 'F13.20', '304.1', '0', 'Sedative, hypnotic, or anxiolytic use disorder, Moderate'),
(786, 'F13.20', '304.1', '0', 'Sedative, hypnotic, or anxiolytic use disorder, Severe'),
(787, NULL, '292', '0', 'Sedative, hypnotic, or anxiolytic withdrawal'),
(788, 'F13.231', '292', '0', 'Sedative, hypnotic, or anxiolytic withdrawal delirium'),
(789, 'F13.232', NULL, '0', 'Sedative, hypnotic, or anxiolytic withdrawal, With perceptual disturbances'),
(790, 'F13.239', NULL, '0', 'Sedative, hypnotic, or anxiolytic withdrawal, Without perceptual disturbances'),
(791, NULL, '292.89', '0', 'Sedative-, hypnotic-, or anxiolytic-induced anxiety disorder'),
(792, 'F13.180', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced anxiety disorder, With mild use disorder'),
(793, 'F13.280', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced anxiety disorder, With moderate or severe use disorder'),
(794, 'F13.980', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced anxiety disorder, Without use disorder'),
(795, NULL, '292.84', '0', 'Sedative-, hypnotic-, or anxiolytic-induced bipolar and related disorder'),
(796, 'F13.14', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced bipolar and related disorder, With mild use disorder'),
(797, 'F13.24', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced bipolar and related disorder, With moderate or severe use disorder'),
(798, 'F13.94', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced bipolar and related disorder, Without use disorder'),
(799, 'F13.921', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced delirium'),
(800, NULL, '292.84', '0', 'Sedative-, hypnotic-, or anxiolytic-induced depressive disorder'),
(801, 'F13.14', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced depressive disorder, With mild use disorder'),
(802, 'F13.24', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced depressive disorder, With moderate or severe use disorder'),
(803, 'F13.94', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced depressive disorder, Without use disorder'),
(804, NULL, '292.82', '0', 'Sedative-, hypnotic-, or anxiolytic-induced major neurocognitive disorder'),
(805, 'F13.27', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced major neurocognitive disorder, With moderate or severe use disorder'),
(806, 'F13.97', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced major neurocognitive disorder, Without use disorder'),
(807, NULL, '292.89', '0', 'Sedative-, hypnotic-, or anxiolytic-induced mild neurocognitive disorder'),
(808, 'F13.288', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced mild neurocognitive disorder, With moderate or severe use disorder'),
(809, 'F13.988', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced mild neurocognitive disorder, Without use disorder'),
(810, NULL, '292.9', '0', 'Sedative-, hypnotic-, or anxiolytic-induced psychotic disorder'),
(811, 'F13.159', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced psychotic disorder, With mild use disorder'),
(812, 'F13.259', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced psychotic disorder, With moderate or severe use disorder'),
(813, 'F13.959', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced psychotic disorder, Without use disorder'),
(814, NULL, '292.89', '0', 'Sedative-, hypnotic-, or anxiolytic-induced sexual dysfunction'),
(815, 'F13.181', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced sexual dysfunction, With mild use disorder'),
(816, 'F13.281', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced sexual dysfunction, With moderate or severe use disorder'),
(817, 'F13.981', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced sexual dysfunction, Without use disorder'),
(818, NULL, '292.85', '0', 'Sedative-, hypnotic-, or anxiolytic-induced sleep disorder'),
(819, 'F13.182', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced sleep disorder, With mild use disorder'),
(820, 'F13.282', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced sleep disorder, With moderate or severe use disorder'),
(821, 'F13.982', NULL, '0', 'Sedative-, hypnotic-, or anxiolytic-induced sleep disorder, Without use disorder'),
(822, 'F94.0', '313.23', '0', 'Selective mutism'),
(823, 'F93.0', '309.21', '0', 'Separation anxiety disorder'),
(824, 'Z70.9', 'V65.49', '0', 'Sex counseling'),
(825, 'F65.51', '302.83', '0', 'Sexual masochism disorder'),
(826, 'F65.52', '302.84', '0', 'Sexual sadism disorder'),
(827, 'Z62.891', 'V61.8', '0', 'Sibling relational problem'),
(828, NULL, NULL, '0', 'Sleep-related hypoventilation'),
(829, 'F80.89', '315.39', '0', 'Social (pragmatic) communication disorder'),
(830, 'F40.10', '300.23', '0', 'Social anxiety disorder (social phobia)'),
(831, 'Z60.4', 'V62.4', '0', 'Social exclusion or rejection'),
(832, 'F45.1', '300.82', '0', 'Somatic symptom disorder'),
(833, NULL, NULL, '0', 'Specific learning disorder'),
(834, 'F81.2', '315.1', '0', 'Specific learning disorder, With impairment in mathematics'),
(835, 'F81.0', '315', '0', 'Specific learning disorder, With impairment in reading'),
(836, 'F81.81', '315.2', '0', 'Specific learning disorder, With impairment in written expression'),
(837, NULL, NULL, '0', 'Specific phobia'),
(838, 'F40.218', '300.29', '0', 'Specific phobia, Animal'),
(839, NULL, '300.29', '0', 'Specific phobia, Blood-injection-injury'),
(840, 'F40.230', NULL, '0', 'Specific phobia, Fear of blood'),
(841, 'F40.231', NULL, '0', 'Specific phobia, Fear of injections and transfusions'),
(842, 'F40.233', NULL, '0', 'Specific phobia, Fear of injury'),
(843, 'F40.232', NULL, '0', 'Specific phobia, Fear of other medical care'),
(844, 'F40.228', '300.29', '0', 'Specific phobia, Natural environment'),
(845, 'F40.298', '300.29', '0', 'Specific phobia, Other'),
(846, 'F40.248', '300.29', '0', 'Specific phobia, Situational'),
(847, 'F80.0', '315.39', '0', 'Speech sound disorder'),
(848, NULL, NULL, '0', 'Spouse or partner abuse, Psychological, Confirmed'),
(849, 'T74.31X', '995.82', '0', 'Spouse or partner abuse, Psychological, Confirmed, Initial encounter'),
(850, 'T74.31X', '995.82', '0', 'Spouse or partner abuse, Psychological, Confirmed, Subsequent encounter'),
(851, NULL, NULL, '0', 'Spouse or partner abuse, Psychological, Suspected'),
(852, 'T76.31X', '995.82', '0', 'Spouse or partner abuse, Psychological, Suspected, Initial encounter'),
(853, 'T76.31X', '995.82', '0', 'Spouse or partner abuse, Psychological, Suspected, Subsequent encounter'),
(854, NULL, NULL, '0', 'Spouse or partner neglect, Confirmed'),
(855, 'T74.01X', '995.85', '0', 'Spouse or partner neglect, Confirmed, Initial encounter'),
(856, 'T74.01X', '995.85', '0', 'Spouse or partner neglect, Confirmed, Subsequent encounter'),
(857, NULL, NULL, '0', 'Spouse or partner neglect, Suspected'),
(858, 'T76.01X', '995.85', '0', 'Spouse or partner neglect, Suspected, Initial encounter'),
(859, 'T76.01X', '995.85', '0', 'Spouse or partner neglect, Suspected, Subsequent encounter'),
(860, NULL, NULL, '0', 'Spouse or partner violence, Physical, Confirmed'),
(861, 'T74.11X', '995.81', '0', 'Spouse or partner violence, Physical, Confirmed, Initial encounter'),
(862, 'T74.11X', '995.81', '0', 'Spouse or partner violence, Physical, Confirmed, Subsequent encounter'),
(863, NULL, NULL, '0', 'Spouse or partner Violence, Physical, Suspected'),
(864, 'T76.11X', '995.81', '0', 'Spouse or partner Violence, Physical, Suspected, Initial encounter'),
(865, 'T76.11X', '995.81', '0', 'Spouse or partner Violence, Physical, Suspected, Subsequent encounter'),
(866, NULL, NULL, '0', 'Spouse or partner Violence, Sexual, Confirmed'),
(867, 'T74.21X', '995.83', '0', 'Spouse or partner Violence, Sexual, Confirmed, Initial encounter'),
(868, 'T74.21X', '995.83', '0', 'Spouse or partner Violence, Sexual, Confirmed, Subsequent encounter'),
(869, NULL, NULL, '0', 'Spouse or partner Violence, Sexual, Suspected'),
(870, 'T76.21X', '995.83', '0', 'Spouse or partner Violence, Sexual, Suspected, Initial encounter'),
(871, 'T76.21X', '995.83', '0', 'Spouse or partner Violence, Sexual, Suspected, Subsequent encounter'),
(872, 'F98.4', '307.3', '0', 'Stereotypic movement disorder'),
(873, 'see spe', 'see speci', '0', 'Stimulant intoxication'),
(874, 'see spe', 'see speci', '0', 'Stimulant use disorder'),
(875, 'see spe', 'see speci', '0', 'Stimulant withdrawal'),
(876, 'see spe', 'see speci', '0', 'Substance intoxication delirium'),
(877, 'see spe', 'see speci', '0', 'Substance intoxication delirium'),
(878, 'see spe', 'see speci', '0', 'Substance withdrawal delirium'),
(879, 'see spe', 'see speci', '0', 'Substance withdrawal delirium'),
(880, 'see spe', 'see speci', '0', 'Substance/medication-induced anxiety disorder'),
(881, 'see spe', 'see speci', '0', 'Substance/medication-induced bipolar and related disorder'),
(882, 'see spe', 'see speci', '0', 'Substance/medication-induced depressive disorder'),
(883, 'see spe', 'see speci', '0', 'Substance/medication-induced major or mild neurocognitive disorder'),
(884, 'see spe', 'see speci', '0', 'Substance/medication-induced obsessive-compulsive and related disorder'),
(885, 'see spe', 'see speci', '0', 'Substance/medication-induced psychotic disorder'),
(886, 'see spe', 'see speci', '0', 'Substance/medication-induced sexual dysfunction'),
(887, 'see spe', 'see speci', '0', 'Substance/medication-induced sleep disorder'),
(888, 'G25.71', '333.99', '0', 'Tardive akathisia'),
(889, 'G24.01', '333.85', '0', 'Tardive dyskinesia'),
(890, 'G24.09', '333.72', '0', 'Tardive dystonia'),
(891, 'Z60.5', 'V62.4', '0', 'Target of (perceived) adverse discrimination or persecution'),
(892, NULL, NULL, '0', 'Tobacco use disorder'),
(893, 'Z72.0', '305.1', '0', 'Tobacco use disorder, Mild'),
(894, 'F17.200', '305.1', '0', 'Tobacco use disorder, Moderate'),
(895, 'F17.200', '305.1', '0', 'Tobacco use disorder, Severe'),
(896, 'F17.203', '292', '0', 'Tobacco withdrawal'),
(897, NULL, '292.85', '0', 'Tobacco-induced sleep disorder'),
(898, 'F17.208', NULL, '0', 'Tobacco-induced sleep disorder, With moderate or severe use disorder'),
(899, 'F95.2', '307.23', '0', 'Tourette\'s disorder'),
(900, 'F65.1', '302.3', '0', 'Transvestic disorder'),
(901, 'F63.3', '312.39', '0', 'Trichotillomania (hair-pulling disorder)'),
(902, 'Z75.3', 'V63.9', '0', 'Unavailability or inaccessibility of health care facilities'),
(903, 'Z75.4', 'V63.8', '0', 'Unavailability or inaccessibility of other helping agencies'),
(904, 'Z63.4', 'V62.82', '0', 'Uncomplicated bereavement'),
(905, 'F10.99', '291.9', '0', 'Unspecified alcohol-related disorder'),
(906, 'F15.99', NULL, '0', 'Unspecified amphetamine or other stimulant-related disorder'),
(907, 'F41.9', '300', '0', 'Unspecified anxiety disorder'),
(908, 'F90.9', '314.01', '0', 'Unspecified attention-deficit/hyperactivity disorder'),
(909, 'F31.9', '296.8', '0', 'Unspecified bipolar and related disorder'),
(910, 'F15.99', '292.9', '0', 'Unspecified caffeine-related disorder'),
(911, 'F12.99', '292.9', '0', 'Unspecified cannabis-related disorder'),
(912, '[R29.81', '[781.99 +', '0', '[Other symptoms involving nervous and musculoskeletal systems +] Unspecified catatonia'),
(913, 'F14.99', NULL, '0', 'Unspecified cocaine-related disorder'),
(914, 'F80.9', '307.9', '0', 'Unspecified communication disorder'),
(915, 'R41.0', '780.09', '0', 'Unspecified delirium'),
(916, 'F32.9', '311', '0', 'Unspecified depressive disorder'),
(917, 'F91.9', '312.9', '0', 'Unspecified disruptive, impulse-control, and conduct disorder'),
(918, 'F44.9', '300.15', '0', 'Unspecified dissociative disorder'),
(919, NULL, NULL, '0', 'Unspecified elimination disorder'),
(920, 'R15.9', '787.6', '0', 'Unspecified elimination disorder, With fecal symptoms'),
(921, 'R32', '788.3', '0', 'Unspecified elimination disorder, With urinary symptoms'),
(922, 'F50.9', '307.5', '0', 'Unspecified feeding or eating disorder'),
(923, 'F64.9', '302.6', '0', 'Unspecified gender dysphoria'),
(924, 'F16.99', '292.9', '0', 'Unspecified hallucinogen-related disorder'),
(925, 'Z59.9', 'V60.9', '0', 'Unspecified housing or economic problem'),
(926, 'G47.10', '780.54', '0', 'Unspecified hypersomnolence disorder'),
(927, 'F18.99', '292.9', '0', 'Unspecified inhalant-related disorder'),
(928, 'G47.00', '780.52', '0', 'Unspecified insomnia disorder'),
(929, 'F79', '319', '0', 'Unspecified intellectual disability (intellectual developmental disorder)'),
(930, 'F99', '300.9', '0', 'Unspecified mental disorder'),
(931, 'F09', '294.9', '0', 'Unspecified mental disorder due to another medical condition'),
(932, 'R41.9', '799.59', '0', 'Unspecified neurocognitive disorder'),
(933, 'F89', '315.9', '0', 'Unspecified neurodevelopmental disorder'),
(934, 'F42', '300.3', '0', 'Unspecified obsessive-compulsive and related disorder'),
(935, 'F11.99', '292.9', '0', 'Unspecified opioid-related disorder'),
(936, 'F19.99', '292.9', '0', 'Unspecified other (or unknown) substance-related disorder'),
(937, 'F65.9', '302.9', '0', 'Unspecified paraphilic disorder'),
(938, 'F60.9', '301.9', '0', 'Unspecified personality disorder'),
(939, 'F16.99', '292.9', '0', 'Unspecified phencyclidine-related disorder'),
(940, 'Z60.9', 'V62.9', '0', 'Unspecified problem related to social environment'),
(941, 'Z65.9', 'V62.9', '0', 'Unspecified problem related to unspecified psychosocial circumstances'),
(942, 'F29', '298.9', '0', 'Unspecified schizophrenia spectrum and other psychotic disorder'),
(943, 'F13.99', '292.9', '0', 'Unspecified sedative-, hypnotic-, or anxiolytic-related disorder'),
(944, 'F52.9', '302.7', '0', 'Unspecified sexual dysfunction'),
(945, 'G47.9', '780.59', '0', 'Unspecified sleep-wake disorder'),
(946, 'F45.9', '300.82', '0', 'Unspecified somatic symptom and related disorder'),
(947, NULL, '292.9', '0', 'Unspecified stimulant-related disorder'),
(948, 'F95.9', '307.2', '0', 'Unspecified tic disorder'),
(949, 'F17.209', '292.9', '0', 'Unspecified tobacco-related disorder'),
(950, 'F43.9', '309.9', '0', 'Unspecified trauma- and stressor-related disorder'),
(951, 'Z62.29', 'V61.8', '0', 'Upbringing away from parents'),
(952, 'Z65.4', 'V62.89', '0', 'Victim of crime'),
(953, 'Z65.4', 'V62.89', '0', 'Victim of terrorism or torture'),
(954, 'F65.3', '302.82', '0', 'Voyeuristic disorder'),
(955, 'Z91.83', 'V40.31', '0', 'Wandering associated with a mental disorder');

-- --------------------------------------------------------

--
-- Table structure for table `doctor`
--

DROP TABLE IF EXISTS `doctor`;
CREATE TABLE `doctor` (
  `doctor_id` int(11) NOT NULL,
  `license` varchar(8) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `phone` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `doctor`
--

INSERT INTO `doctor` (`doctor_id`, `license`, `first_name`, `last_name`, `phone`) VALUES
(1, '76541234', 'Emilio', 'Villa', '8123456897'),
(2, '59328522', 'Guillermina', 'Juarez', '8182421800'),
(3, '68192093', 'Kurt', 'Fernádez', '8117676076'),
(4, '81092482', 'Ramon', 'Carballar', '4777632171'),
(5, '48439049', 'Kimberly', 'Elvira', '5549891022');

-- --------------------------------------------------------

--
-- Table structure for table `medicine`
--

DROP TABLE IF EXISTS `medicine`;
CREATE TABLE `medicine` (
  `medicine_id` int(11) NOT NULL,
  `medicine_name` varchar(15) NOT NULL,
  `ingredient` varchar(15) NOT NULL,
  `dose` varchar(8) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `medicine`
--

INSERT INTO `medicine` (`medicine_id`, `medicine_name`, `ingredient`, `dose`) VALUES
(1, 'Aripiprazol', 'Abilify', '15'),
(2, 'Olanzapina', 'Zyprexa', '10'),
(3, 'Quetiapina', 'Seroquel', '300'),
(4, 'Risperidona', 'Risperdal', '2'),
(5, 'Ziprasidona', 'Geodon', '160');

-- --------------------------------------------------------

--
-- Table structure for table `patient`
--

DROP TABLE IF EXISTS `patient`;
CREATE TABLE `patient` (
  `patient_id` int(11) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `sex` char(1) NOT NULL,
  `rfc` varchar(13) DEFAULT NULL,
  `phone` varchar(15) NOT NULL,
  `city` varchar(20) NOT NULL,
  `street_address` varchar(50) NOT NULL,
  `email` varchar(30) NOT NULL,
  `date_of_birth` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `patient`
--

INSERT INTO `patient` (`patient_id`, `first_name`, `last_name`, `sex`, `rfc`, `phone`, `city`, `street_address`, `email`, `date_of_birth`) VALUES
(1, 'Josefa', 'Perez', 'F', 'JFPA520201', '8129806590', 'Monterrey', 'Col. Salinas', 'guillermo@gmail.com', '1952-02-01'),
(2, 'Alejandra', 'Manzanares', 'F', 'AFMM551205', '8449028940', 'Saltillo', 'Col. Los Liriositos', 'manzanares@yahoo.com', '1955-12-05'),
(3, 'Monste', 'Aguayo', 'F', 'MMA651103', '8219948051', 'Allende', 'Col. Leal', 'm_aguayo@hotmail.com', '1965-11-03'),
(4, 'Ramon', 'Montreal', 'M', 'GFMA790918', '8113040583', 'Monterrey', 'Col. Independencia', 'g79montreal@gmail.com', '1979-09-18'),
(5, 'Rogelio', 'Lopez', 'M', 'PAT1231231', '8181181881', 'Saltillo', 'Col. Herradura', 'rlopez@hotmail.com', '1999-10-10'),
(6, ' David', 'Cantu', 'M', 'DAC0004211234', '8115822719', 'Monterrey', 'Cumbres', 'dcantu@gmail.com', '2000-04-21');

-- --------------------------------------------------------

--
-- Table structure for table `prescription`
--

DROP TABLE IF EXISTS `prescription`;
CREATE TABLE `prescription` (
  `prescription_id` int(11) NOT NULL,
  `consult_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `prescription`
--

INSERT INTO `prescription` (`prescription_id`, `consult_id`) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10),
(11, 11),
(12, 12),
(13, 13),
(14, 14),
(15, 15),
(16, 16),
(17, 26),
(18, 27);

-- --------------------------------------------------------

--
-- Table structure for table `questions`
--

DROP TABLE IF EXISTS `questions`;
CREATE TABLE `questions` (
  `question_id` int(11) NOT NULL,
  `test_id` int(11) DEFAULT NULL,
  `Question` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `questions`
--

INSERT INTO `questions` (`question_id`, `test_id`, `Question`) VALUES
(1, 1, 'Humor depresivo:\r\n\r\n0 Ausente\r\n1 Estas sensaciones las expresa solamente si le preguntan como se siente\r\n2 Estas sensaciones las relata espontáneamente\r\n3 Sensaciones no comunicadas verbalmente (expresión facial, postura, voz, tendencia al\r\nllanto)\r\n4 Manifiesta estas sensaciones en su comunicación verbal y no verbal en forma espontánea'),
(2, 1, 'Sentimientos de culpa:\r\n\r\n0 Ausente\r\n1 Se culpa a si mismo, cree haber decepcionado a la gente\r\n2 Tiene ideas de culpabilidad o medita sobre errores pasados o malas acciones\r\n3 Siente que la enfermedad actual es un castigo\r\n4 Oye voces acusatorias o de denuncia y/o experimenta alucinaciones visuales de amenaza'),
(3, 1, 'Suicidio:\r\n\r\n0 Ausente\r\n1 Le parece que la vida no vale la pena ser vivida\r\n2 Desearía estar muerto o tiene pensamientos sobre la posibilidad de morirse\r\n3 Ideas de suicidio o amenazas\r\n4 Intentos de suicidio (cualquier intento serio)'),
(4, 1, 'Insomnio precoz:\r\n\r\n0 No tiene dificultad\r\n1 Dificultad ocasional para dormir, por ej. más de media hora el conciliar el sueño\r\n2 Dificultad para dormir cada noche'),
(5, 1, 'Insomino intermedio:\r\n\r\n0 No hay dificultad\r\n1 Esta desvelado e inquieto o se despierta varias veces durante la noche\r\n2 Esta despierto durante la noche, cualquier ocasión de levantarse de la cama se clasifica en 2 (excepto por motivos de evacuar)'),
(6, 1, 'Insomnio tardio:\r\n\r\n0 No hay dificultad\r\n1 Se despierta a primeras horas de la madrugada, pero se vuelve a dormir\r\n2 No puede volver a dormirse si se levanta de la cama'),
(7, 1, 'Trabajo y actividades:\r\n\r\n0 No hay dificultad\r\n1 Ideas y sentimientos de incapacidad, fatiga o debilidad (trabajos, pasatiempos)\r\n2 Pérdida de interés en su actividad (disminución de la atención, indecisión y vacilación)\r\n3 Disminución del tiempo actual dedicado a actividades o disminución de la productividad\r\n4 Dejó de trabajar por la presente enfermedad. Solo se compromete en las pequeñas tareas, o no puede realizar estas sin ayuda.'),
(8, 1, 'Inhibicion psicomotora (lentitud de pensamiento y lenguaje, facultad de\r\nconcentración disminuida, disminución de la actividad motora):\r\n\r\n0 Palabra y pensamiento normales\r\n1 Ligero retraso en el habla\r\n2 Evidente retraso en el habla\r\n3 Dificultad para expresarse\r\n4 Incapacidad para expresarse'),
(9, 1, 'Agitacion psicomotora:\r\n\r\n0 Ninguna\r\n1 Juega con sus dedos\r\n2 Juega con sus manos, cabello, etc.\r\n3 No puede quedarse quieto ni permanecer sentado\r\n4 Retuerce las manos, se muerde las uñas, se tira de los cabellos, se muerde los labios'),
(10, 1, 'Ansiedad psíquica:\r\n\r\n0 No hay dificultad\r\n1 Tensión subjetiva e irritabilidad\r\n2 Preocupación por pequeñas cosas\r\n3 Actitud aprensiva en la expresión o en el habla\r\n4 Expresa sus temores sin que le pregunten'),
(11, 1, 'Ansiedad somatica (signos físicos de ansiedad: gastrointestinales: sequedad de boca, diarrea, eructos, indigestión, etc; cardiovasculares: palpitaciones, cefaleas; respiratorios: hiperventilación, suspiros; frecuencia de micción incrementada; transpiración):\r\n\r\n0 Ausente\r\n1 Ligera\r\n2 Moderada\r\n3 Severa\r\n4 Incapacitante'),
(12, 1, 'Sintomas somaticos gastrointestinales:\r\n\r\n0 Ninguno\r\n1 Pérdida del apetito pero come sin necesidad de que lo estimulen. \r\n2 Sensación de pesadez en el abdomen\r\n3 Dificultad en comer si no se le insiste. \r\n4 Solicita laxantes o medicación intestinal para sus síntomas gastrointestinales'),
(13, 1, 'Sintomas somaticos generales:\r\n\r\n0 Ninguno\r\n1 Pesadez en las extremidades, espalda o cabeza. Dorsalgias. Cefaleas, algias musculares. Pérdida de energía y fatigabilidad.\r\n2 Cualquier síntoma bien definido se clasifica en 2'),
(14, 1, 'Sintomas genitales:\r\n\r\n0 Ausente\r\n1 Débil\r\n2 Grave'),
(15, 1, 'Hipocondria:\r\n\r\n0 Ausente\r\n1 Preocupado de si mismo (corporalmente)\r\n2 Preocupado por su salud\r\n3 Se lamenta constantemente, solicita ayuda'),
(16, 1, 'Perdida de peso:\r\n\r\n0 Pérdida de peso inferior a 500 gr. en una semana\r\n1 Pérdida de más de 500 gr. en una semana\r\n2 Pérdida de más de 1 Kg. en una semana'),
(17, 1, 'Introspeccion (insight):\r\n\r\n0 Se da cuenta que esta deprimido y enfermo\r\n1 Se da cuenta de su enfermedad pero atribuye la causa a la mala alimentación, clima, exceso de trabajo, virus, necesidad de descanso, etc.\r\n2 No se da cuenta que está enfermo'),
(18, 2, 'Estado de ánimo ansioso. \r\nPreocupaciones, anticipación de lo peor, aprensión (anticipación temerosa), irritabilidad \r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(19, 2, 'Tensión. \r\nSensación de tensión, imposibilidad de relajarse, reacciones con sobresalto, llanto fácil, temblores, sensación de inquietud.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(20, 2, 'Temores. \r\nA la oscuridad, a los desconocidos, a quedarse solo, a los animales grandes, al tráfico, a las multitudes.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(21, 2, 'Insomnio. \r\nDificultad para dormirse, sueño interrumpido, sueño insatisfactorio y cansancio al despertar.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(22, 2, 'Intelectual (cognitivo) \r\nDificultad para concentrarse, mala memoria.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(23, 2, 'Estado de ánimo deprimido. \r\nPérdida de interés, insatisfacción en las diversiones, depresión, despertar prematuro, cambios de humor durante el día.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(24, 2, 'Síntomas somáticos generales (musculares)\r\nDolores y molestias musculares, rigidez muscular, contracciones musculares, sacudidas clónicas, crujir de dientes, voz temblorosa.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante\r\n'),
(25, 2, 'Síntomas somáticos generales (sensoriales) \r\nZumbidos de oídos, visión borrosa, sofocos y escalofríos, sensación de debilidad, sensación de hormigueo.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(26, 2, 'Síntomas cardiovasculares. \r\nTaquicardia, palpitaciones, dolor en el pecho, latidos vasculares, sensación de desmayo, extrasístole.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(27, 2, 'Síntomas respiratorios. \r\nOpresión o constricción en el pecho, sensación de ahogo, suspiros, disnea.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(28, 2, 'Síntomas gastrointestinales. \r\nDificultad para tragar, gases, dispepsia: dolor antes y después de comer, sensación de ardor, sensación de estómago lleno, vómitos acuosos, vómitos, sensación de estómago vacío, digestión lenta, borborigmos (ruido intestinal), diarrea, pérdida de peso, estreñimiento.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(29, 2, 'Síntomas genitourinarios. \r\nMicción frecuente, micción urgente, amenorrea, menorragia, aparición de la frigidez, eyaculación precoz, ausencia de erección, impotencia.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(30, 2, 'Síntomas autónomos. \r\nBoca seca, rubor, palidez, tendencia a sudar, vértigos, cefaleas de tensión, piloerección (pelos de punta)\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante'),
(31, 2, 'Comportamiento en la entrevista (general y fisiológico)\r\nTenso, no relajado, agitación nerviosa: manos, dedos cogidos, apretados, tics, enrollar un pañuelo; inquietud; pasearse de un lado a otro, temblor de manos, ceño fruncido, cara tirante, aumento del tono muscular, suspiros, palidez facial.\r\nTragar saliva, eructar, taquicardia de reposo, frecuencia respiratoria por encima de 20 res/min, sacudidas enérgicas de tendones, temblor, pupilas dilatadas, exoftalmos (proyección anormal del globo del ojo), sudor, tics en los párpados.\r\n\r\n0 Ausente\r\n1 Leve\r\n2 Moderado\r\n3 Grave\r\n4 Muy grave/ Incapacitante');

-- --------------------------------------------------------

--
-- Table structure for table `recipe`
--

DROP TABLE IF EXISTS `recipe`;
CREATE TABLE `recipe` (
  `medicine_id` int(11) NOT NULL,
  `prescription_id` int(11) NOT NULL,
  `instructions` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `recipe`
--

INSERT INTO `recipe` (`medicine_id`, `prescription_id`, `instructions`) VALUES
(1, 1, 'tomar una diaria durante 5 días'),
(1, 2, 'tomar una diaria durante 5 días'),
(1, 3, 'tomar una diaria durante 5 días'),
(1, 4, 'tomar una diaria durante 5 días'),
(1, 18, '2 every day for 8 days'),
(2, 1, 'aumentar iterativamente en dosis de 5 mg'),
(2, 3, 'aumentar iterativamente en dosis de 5 mg'),
(2, 17, '2 per day for 10 days'),
(2, 18, '1 every 8 hours for 10 days'),
(3, 1, 'tomar una en lanoche y una en la mañana'),
(3, 2, 'tomar una en lanoche y una en la mañana'),
(3, 3, 'tomar una en lanoche y una en la mañana'),
(3, 4, 'tomar una en la noche y una en la mañana'),
(4, 1, 'tomar antes y después de cada comida'),
(4, 2, 'tomar antes y después de cada comida'),
(4, 3, 'tomar antes y después de cada comida'),
(4, 4, 'tomar antes y después de cada comida'),
(5, 2, 'tomar una cada 12 hrs'),
(5, 4, 'tomar una cada 12 hrs'),
(5, 17, '1 per week');

-- --------------------------------------------------------

--
-- Table structure for table `test`
--

DROP TABLE IF EXISTS `test`;
CREATE TABLE `test` (
  `test_id` int(11) NOT NULL,
  `test_name` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `test`
--

INSERT INTO `test` (`test_id`, `test_name`) VALUES
(1, 'Escala de depresion de Hamilton'),
(2, 'Escala de ansiedad de Hamilton');

-- --------------------------------------------------------

--
-- Table structure for table `test_instance`
--

DROP TABLE IF EXISTS `test_instance`;
CREATE TABLE `test_instance` (
  `instance_id` int(11) NOT NULL,
  `test_id` int(11) DEFAULT NULL,
  `consult_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `test_instance`
--

INSERT INTO `test_instance` (`instance_id`, `test_id`, `consult_id`) VALUES
(1, 1, 1),
(2, 1, 8),
(3, 1, 9),
(4, 1, 16),
(5, 1, 4),
(6, 1, 5),
(7, 1, 12),
(8, 1, 13),
(9, 2, 2),
(10, 2, 7),
(11, 2, 10),
(12, 2, 15),
(13, 2, 3),
(14, 2, 6),
(15, 2, 11),
(16, 2, 14),
(21, 2, 25),
(22, 2, 26),
(24, 2, 27);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `answer`
--
ALTER TABLE `answer`
  ADD PRIMARY KEY (`answer_id`),
  ADD KEY `question_id` (`question_id`),
  ADD KEY `answer_ibfk_1` (`instance_id`);

--
-- Indexes for table `app_info`
--
ALTER TABLE `app_info`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `app_nombre` (`app_nombre`);

--
-- Indexes for table `app_reporte`
--
ALTER TABLE `app_reporte`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre_reporte` (`nombre_reporte`);

--
-- Indexes for table `consult`
--
ALTER TABLE `consult`
  ADD PRIMARY KEY (`consult_id`),
  ADD KEY `doctor_id` (`doctor_id`),
  ADD KEY `consult_ibfk_1` (`patient_id`);

--
-- Indexes for table `diagnostic`
--
ALTER TABLE `diagnostic`
  ADD PRIMARY KEY (`consult_id`,`disease_catalog_id`),
  ADD KEY `disease_catalog_id` (`disease_catalog_id`);

--
-- Indexes for table `disease_catalog`
--
ALTER TABLE `disease_catalog`
  ADD PRIMARY KEY (`disease_catalog_id`);

--
-- Indexes for table `doctor`
--
ALTER TABLE `doctor`
  ADD PRIMARY KEY (`doctor_id`);

--
-- Indexes for table `medicine`
--
ALTER TABLE `medicine`
  ADD PRIMARY KEY (`medicine_id`);

--
-- Indexes for table `patient`
--
ALTER TABLE `patient`
  ADD PRIMARY KEY (`patient_id`);

--
-- Indexes for table `prescription`
--
ALTER TABLE `prescription`
  ADD PRIMARY KEY (`prescription_id`),
  ADD KEY `prescription_ibfk_1` (`consult_id`);

--
-- Indexes for table `questions`
--
ALTER TABLE `questions`
  ADD PRIMARY KEY (`question_id`),
  ADD KEY `test_id` (`test_id`);

--
-- Indexes for table `recipe`
--
ALTER TABLE `recipe`
  ADD PRIMARY KEY (`medicine_id`,`prescription_id`),
  ADD KEY `recipe_ibfk_2` (`prescription_id`);

--
-- Indexes for table `test`
--
ALTER TABLE `test`
  ADD PRIMARY KEY (`test_id`);

--
-- Indexes for table `test_instance`
--
ALTER TABLE `test_instance`
  ADD PRIMARY KEY (`instance_id`),
  ADD KEY `test_id` (`test_id`),
  ADD KEY `test_instance_ibfk_2` (`consult_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `answer`
--
ALTER TABLE `answer`
  MODIFY `answer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=290;

--
-- AUTO_INCREMENT for table `app_reporte`
--
ALTER TABLE `app_reporte`
  MODIFY `id` int(6) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `consult`
--
ALTER TABLE `consult`
  MODIFY `consult_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `patient`
--
ALTER TABLE `patient`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `prescription`
--
ALTER TABLE `prescription`
  MODIFY `prescription_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `test_instance`
--
ALTER TABLE `test_instance`
  MODIFY `instance_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `answer`
--
ALTER TABLE `answer`
  ADD CONSTRAINT `answer_ibfk_1` FOREIGN KEY (`instance_id`) REFERENCES `test_instance` (`instance_id`),
  ADD CONSTRAINT `answer_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `questions` (`question_id`);

--
-- Constraints for table `consult`
--
ALTER TABLE `consult`
  ADD CONSTRAINT `consult_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
  ADD CONSTRAINT `consult_ibfk_2` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`);

--
-- Constraints for table `diagnostic`
--
ALTER TABLE `diagnostic`
  ADD CONSTRAINT `diagnostic_ibfk_1` FOREIGN KEY (`consult_id`) REFERENCES `consult` (`consult_id`),
  ADD CONSTRAINT `diagnostic_ibfk_2` FOREIGN KEY (`disease_catalog_id`) REFERENCES `disease_catalog` (`disease_catalog_id`);

--
-- Constraints for table `prescription`
--
ALTER TABLE `prescription`
  ADD CONSTRAINT `prescription_ibfk_1` FOREIGN KEY (`consult_id`) REFERENCES `consult` (`consult_id`);

--
-- Constraints for table `questions`
--
ALTER TABLE `questions`
  ADD CONSTRAINT `questions_ibfk_1` FOREIGN KEY (`test_id`) REFERENCES `test` (`test_id`);

--
-- Constraints for table `recipe`
--
ALTER TABLE `recipe`
  ADD CONSTRAINT `recipe_ibfk_1` FOREIGN KEY (`medicine_id`) REFERENCES `medicine` (`medicine_id`),
  ADD CONSTRAINT `recipe_ibfk_2` FOREIGN KEY (`prescription_id`) REFERENCES `prescription` (`prescription_id`);

--
-- Constraints for table `test_instance`
--
ALTER TABLE `test_instance`
  ADD CONSTRAINT `test_instance_ibfk_1` FOREIGN KEY (`test_id`) REFERENCES `test` (`test_id`),
  ADD CONSTRAINT `test_instance_ibfk_2` FOREIGN KEY (`consult_id`) REFERENCES `consult` (`consult_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
