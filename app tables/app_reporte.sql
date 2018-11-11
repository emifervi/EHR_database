-- phpMyAdmin SQL Dump
-- version 4.8.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Nov 11, 2018 at 02:40 AM
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

-- --------------------------------------------------------

--
-- Table structure for table `app_reporte`
--

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
(1, 'Patient Dashboard', 1, 1, '[{\"identifier\":\"Patient Dashboard\",\"expanded\":true,\"idp\":-1,\"node\":\"parent\",\"type\":\"report\",\"report\":[{\"idp\":5,\"node\":\"child\",\"type\":\"dropdown\",\"label\":\"Patients\",\"default\":\"\",\"identifier\":\"dropdown6\",\"src\":\"get_patient_id_name\",\"expanded\":true},{\"idp\":21,\"node\":\"child\",\"type\":\"button\",\"text\":\"Show all patient information\",\"sps\":[],\"fluid\":false,\"color\":\"green\",\"position\":\"center\",\"identifier\":\"show_patient_info\",\"expanded\":true},{\"idp\":22,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space23\",\"expanded\":false},{\"idp\":23,\"node\":\"child\",\"type\":\"space\",\"pixels\":10,\"identifier\":\"space24\",\"expanded\":false},{\"identifier\":\"update_container\",\"expanded\":true,\"idp\":6,\"node\":\"parent\",\"stacked\":false,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":8,\"node\":\"child\",\"type\":\"header\",\"text\":\"Patient Information\",\"size\":\"h1\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header9\",\"expanded\":true},{\"identifier\":\"form10\",\"expanded\":true,\"idp\":9,\"node\":\"parent\",\"type\":\"form\",\"form\":[{\"identifier\":\"grid25\",\"expanded\":false,\"idp\":24,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":19,\"node\":\"child\",\"type\":\"input\",\"label\":\"ID\",\"default\":\"\",\"identifier\":\"patient_id\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":11,\"node\":\"child\",\"type\":\"input\",\"label\":\"First Name\",\"default\":\"\",\"identifier\":\"first_name\",\"inputType\":\"text\",\"expanded\":true},{\"idp\":12,\"node\":\"child\",\"type\":\"input\",\"label\":\"Last Name\",\"default\":\"\",\"identifier\":\"last_name\",\"inputType\":\"text\",\"expanded\":true},{\"idp\":13,\"node\":\"child\",\"type\":\"input\",\"label\":\"Sex\",\"default\":\"\",\"identifier\":\"sex\",\"inputType\":\"text\",\"expanded\":false}]},{\"identifier\":\"grid32\",\"expanded\":false,\"idp\":31,\"node\":\"parent\",\"centered\":true,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":28,\"node\":\"child\",\"type\":\"input\",\"label\":\"RFC\",\"default\":\"\",\"identifier\":\"rfc\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":29,\"node\":\"child\",\"type\":\"input\",\"label\":\"Phone\",\"default\":\"\",\"identifier\":\"phone\",\"inputType\":\"number\",\"expanded\":true},{\"idp\":27,\"node\":\"child\",\"type\":\"input\",\"label\":\"City\",\"default\":\"\",\"identifier\":\"city\",\"inputType\":\"text\",\"expanded\":false}]},{\"identifier\":\"grid33\",\"expanded\":true,\"idp\":32,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"idp\":30,\"node\":\"child\",\"type\":\"input\",\"label\":\"Address\",\"default\":\"\",\"identifier\":\"street_address\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":33,\"node\":\"child\",\"type\":\"input\",\"label\":\"Email\",\"default\":\"\",\"identifier\":\"email\",\"inputType\":\"text\",\"expanded\":false},{\"idp\":34,\"node\":\"child\",\"type\":\"input\",\"label\":\"Date of Birth\",\"default\":\"\",\"identifier\":\"dob\",\"inputType\":\"text\",\"expanded\":false}]},{\"idp\":26,\"node\":\"child\",\"type\":\"button\",\"text\":\"Update\",\"sps\":[],\"fluid\":false,\"color\":\"blue\",\"position\":\"right\",\"identifier\":\"update_button\",\"expanded\":true},{\"idp\":20,\"node\":\"child\",\"type\":\"execution_single\",\"id\":\"\",\"src\":\"get_patient\",\"trigger\":\"show_patient_info\",\"params\":[\"dropdown6\"],\"targets\":[\"patient_id\",\"first_name\",\"last_name\",\"sex\",\"rfc\",\"phone\",\"city\",\"street_address\",\"email\",\"dob\"],\"onLoad\":false,\"showSuccess\":false,\"message\":\"Success message\",\"order\":\"\",\"identifier\":\"execution_single21\",\"expanded\":false}]}]},{\"idp\":15,\"node\":\"child\",\"type\":\"divider\",\"identifier\":\"divider16\",\"expanded\":true},{\"identifier\":\"grid17\",\"expanded\":true,\"idp\":16,\"node\":\"parent\",\"centered\":false,\"cols\":\"equal\",\"divided\":false,\"type\":\"grid\",\"grid\":[{\"identifier\":\"table_container\",\"expanded\":true,\"idp\":7,\"node\":\"parent\",\"stacked\":true,\"raised\":false,\"basic\":false,\"type\":\"container\",\"container\":[{\"idp\":14,\"node\":\"child\",\"type\":\"header\",\"text\":\"All patients\",\"size\":\"h2\",\"position\":\"left\",\"icon_button\":\"\",\"upper_icon\":false,\"subtext\":\"\",\"color\":\"black\",\"identifier\":\"header15\",\"expanded\":false},{\"idp\":0,\"node\":\"child\",\"type\":\"table\",\"id\":\"\",\"src\":\"get_all_patients\",\"trigger\":\"\",\"params\":[],\"onLoad\":true,\"xlsName\":\"data\",\"order\":\"\",\"identifier\":\"table1\",\"expanded\":false}]}]}],\"max\":35}]', '');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `app_reporte`
--
ALTER TABLE `app_reporte`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre_reporte` (`nombre_reporte`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `app_reporte`
--
ALTER TABLE `app_reporte`
  MODIFY `id` int(6) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
