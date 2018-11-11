-- phpMyAdmin SQL Dump
-- version 4.8.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Nov 11, 2018 at 02:39 AM
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
-- Table structure for table `app_info`
--

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
(0, 'App', '#451515', '#ffffff', 'Home', 'home', 'Patient Dashboard', 'none', 1, 'Button 2', 'none', 0, 'Button 3', 'none', 0, 'Button 4', 'none', 0, 'Button 5', 'none', 0, 'Button 6', 'none', 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `app_info`
--
ALTER TABLE `app_info`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `app_nombre` (`app_nombre`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
