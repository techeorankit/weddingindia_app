-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jul 08, 2026 at 12:32 PM
-- Server version: 11.8.8-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u107196136_wedingindia`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(150) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `last_login` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`id`, `username`, `password`, `name`, `is_active`, `last_login`, `created_at`) VALUES
(1, 'admin', '$2a$12$wIfhThvNeO0PEplcGwJAWOhual0YhbnmZtA0Fj4sTV6wmrg.X4w6C', 'Super Admin', 1, '2026-07-08 12:21:57', '2026-07-08 12:18:18');

-- --------------------------------------------------------

--
-- Table structure for table `blood_groups`
--

CREATE TABLE `blood_groups` (
  `id` int(11) NOT NULL,
  `name` varchar(10) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `blood_groups`
--

INSERT INTO `blood_groups` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'A+', 1, 1),
(2, 'A-', 2, 1),
(3, 'B+', 3, 1),
(4, 'B-', 4, 1),
(5, 'AB+', 5, 1),
(6, 'AB-', 6, 1),
(7, 'O+', 7, 1),
(8, 'O-', 8, 1);

-- --------------------------------------------------------

--
-- Table structure for table `body_types`
--

CREATE TABLE `body_types` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `body_types`
--

INSERT INTO `body_types` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Slim', 1, 1),
(2, 'Average', 2, 1),
(3, 'Athletic', 3, 1),
(4, 'Heavy', 4, 1);

-- --------------------------------------------------------

--
-- Table structure for table `complexions`
--

CREATE TABLE `complexions` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `complexions`
--

INSERT INTO `complexions` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Very Fair', 1, 1),
(2, 'Fair', 2, 1),
(3, 'Wheatish', 3, 1),
(4, 'Dark', 4, 1);

-- --------------------------------------------------------

--
-- Table structure for table `country_codes`
--

CREATE TABLE `country_codes` (
  `id` int(11) NOT NULL,
  `country_name` varchar(100) NOT NULL,
  `code` varchar(10) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `country_codes`
--

INSERT INTO `country_codes` (`id`, `country_name`, `code`, `sort_order`, `is_active`) VALUES
(1, 'India', '+91', 1, 1),
(2, 'USA', '+1', 2, 1),
(3, 'UK', '+44', 3, 1),
(4, 'Australia', '+61', 4, 1);

-- --------------------------------------------------------

--
-- Table structure for table `disabilities`
--

CREATE TABLE `disabilities` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `disabilities`
--

INSERT INTO `disabilities` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'None', 1, 1),
(2, 'Physically Challenged', 2, 1),
(3, 'Visually Impaired', 3, 1),
(4, 'Hearing Impaired', 4, 1),
(5, 'Other', 5, 1);

-- --------------------------------------------------------

--
-- Table structure for table `drinking_habits`
--

CREATE TABLE `drinking_habits` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `drinking_habits`
--

INSERT INTO `drinking_habits` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'No', 1, 1),
(2, 'Occasionally', 2, 1),
(3, 'Yes', 3, 1);

-- --------------------------------------------------------

--
-- Table structure for table `eating_habits`
--

CREATE TABLE `eating_habits` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `eating_habits`
--

INSERT INTO `eating_habits` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Vegetarian', 1, 1),
(2, 'Non-Vegetarian', 2, 1),
(3, 'Eggetarian', 3, 1),
(4, 'Vegan', 4, 1);

-- --------------------------------------------------------

--
-- Table structure for table `education_levels`
--

CREATE TABLE `education_levels` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `education_levels`
--

INSERT INTO `education_levels` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Below 10th', 1, 1),
(2, '10th Pass', 2, 1),
(3, '12th Pass', 3, 1),
(4, 'Diploma', 4, 1),
(5, 'Graduate', 5, 1),
(6, 'Post Graduate', 6, 1),
(7, 'Doctorate', 7, 1),
(8, 'Other', 8, 1);

-- --------------------------------------------------------

--
-- Table structure for table `heights`
--

CREATE TABLE `heights` (
  `id` int(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `cm_value` int(11) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `heights`
--

INSERT INTO `heights` (`id`, `name`, `cm_value`, `sort_order`, `is_active`) VALUES
(1, '4\'6\"', 137, 1, 1),
(2, '4\'7\"', 140, 2, 1),
(3, '4\'8\"', 142, 3, 1),
(4, '4\'9\"', 145, 4, 1),
(5, '4\'10\"', 147, 5, 1),
(6, '4\'11\"', 150, 6, 1),
(7, '5\'0\"', 152, 7, 1),
(8, '5\'1\"', 155, 8, 1),
(9, '5\'2\"', 157, 9, 1),
(10, '5\'3\"', 160, 10, 1),
(11, '5\'4\"', 163, 11, 1),
(12, '5\'5\"', 165, 12, 1),
(13, '5\'6\"', 168, 13, 1),
(14, '5\'7\"', 170, 14, 1),
(15, '5\'8\"', 173, 15, 1),
(16, '5\'9\"', 175, 16, 1),
(17, '5\'10\"', 178, 17, 1),
(18, '5\'11\"', 180, 18, 1),
(19, '6\'0\"', 183, 19, 1),
(20, '6\'1\"', 185, 20, 1),
(21, '6\'2\"', 188, 21, 1),
(22, '6\'3\"', 191, 22, 1),
(23, '6\'4\"', 193, 23, 1);

-- --------------------------------------------------------

--
-- Table structure for table `income_ranges`
--

CREATE TABLE `income_ranges` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `income_ranges`
--

INSERT INTO `income_ranges` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'No Income', 1, 1),
(2, 'Below 1 Lakh', 2, 1),
(3, '1-2 Lakh', 3, 1),
(4, '2-5 Lakh', 4, 1),
(5, '5-10 Lakh', 5, 1),
(6, '10-20 Lakh', 6, 1),
(7, '20-50 Lakh', 7, 1),
(8, '50 Lakh - 1 Crore', 8, 1),
(9, '1-2 Crore', 9, 1),
(10, '2-3 Crore', 10, 1),
(11, '3-4 Crore', 11, 1),
(12, '4-5 Crore', 12, 1),
(13, '5+ Crore', 13, 1);

-- --------------------------------------------------------

--
-- Table structure for table `marital_statuses`
--

CREATE TABLE `marital_statuses` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `marital_statuses`
--

INSERT INTO `marital_statuses` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Never Married', 1, 1),
(2, 'Divorced', 2, 1),
(3, 'Widowed', 3, 1),
(4, 'Awaiting Divorce', 4, 1);

-- --------------------------------------------------------

--
-- Table structure for table `mother_tongues`
--

CREATE TABLE `mother_tongues` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `mother_tongues`
--

INSERT INTO `mother_tongues` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Hindi', 1, 1),
(2, 'Marathi', 2, 1),
(3, 'Gujarati', 3, 1),
(4, 'Bengali', 4, 1),
(5, 'Tamil', 5, 1),
(6, 'Telugu', 6, 1),
(7, 'Kannada', 7, 1),
(8, 'Malayalam', 8, 1),
(9, 'Punjabi', 9, 1),
(10, 'Odia', 10, 1),
(11, 'Urdu', 11, 1),
(12, 'Assamese', 12, 1),
(13, 'Maithili', 13, 1),
(14, 'Sanskrit', 14, 1),
(15, 'English', 15, 1),
(16, 'Other', 16, 1);

-- --------------------------------------------------------

--
-- Table structure for table `profile_for_options`
--

CREATE TABLE `profile_for_options` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `profile_for_options`
--

INSERT INTO `profile_for_options` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Myself', 1, 1),
(2, 'Son', 2, 1),
(3, 'Daughter', 3, 1),
(4, 'Brother', 4, 1),
(5, 'Sister', 5, 1),
(6, 'Friend', 6, 1);

-- --------------------------------------------------------

--
-- Table structure for table `religions`
--

CREATE TABLE `religions` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `religions`
--

INSERT INTO `religions` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Hindu', 1, 1),
(2, 'Muslim', 2, 1),
(3, 'Christian', 3, 1),
(4, 'Sikh', 4, 1),
(5, 'Jain', 5, 1),
(6, 'Buddhist', 6, 1),
(7, 'Other', 7, 1);

-- --------------------------------------------------------

--
-- Table structure for table `smoking_habits`
--

CREATE TABLE `smoking_habits` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `smoking_habits`
--

INSERT INTO `smoking_habits` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'No', 1, 1),
(2, 'Occasionally', 2, 1),
(3, 'Yes', 3, 1);

-- --------------------------------------------------------

--
-- Table structure for table `states`
--

CREATE TABLE `states` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `states`
--

INSERT INTO `states` (`id`, `name`, `sort_order`, `is_active`) VALUES
(1, 'Andhra Pradesh', 1, 1),
(2, 'Arunachal Pradesh', 2, 1),
(3, 'Assam', 3, 1),
(4, 'Bihar', 4, 1),
(5, 'Chhattisgarh', 5, 1),
(6, 'Goa', 6, 1),
(7, 'Gujarat', 7, 1),
(8, 'Haryana', 8, 1),
(9, 'Himachal Pradesh', 9, 1),
(10, 'Jharkhand', 10, 1),
(11, 'Karnataka', 11, 1),
(12, 'Kerala', 12, 1),
(13, 'Madhya Pradesh', 13, 1),
(14, 'Maharashtra', 14, 1),
(15, 'Manipur', 15, 1),
(16, 'Meghalaya', 16, 1),
(17, 'Mizoram', 17, 1),
(18, 'Nagaland', 18, 1),
(19, 'Odisha', 19, 1),
(20, 'Punjab', 20, 1),
(21, 'Rajasthan', 21, 1),
(22, 'Sikkim', 22, 1),
(23, 'Tamil Nadu', 23, 1),
(24, 'Telangana', 24, 1),
(25, 'Tripura', 25, 1),
(26, 'Uttar Pradesh', 26, 1),
(27, 'Uttarakhand', 27, 1),
(28, 'West Bengal', 28, 1),
(29, 'Delhi', 29, 1),
(30, 'Other', 30, 1);

-- --------------------------------------------------------

--
-- Table structure for table `upgrade_features`
--

CREATE TABLE `upgrade_features` (
  `id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `description` varchar(255) NOT NULL,
  `icon` varchar(50) NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `upgrade_features`
--

INSERT INTO `upgrade_features` (`id`, `title`, `description`, `icon`, `sort_order`, `is_active`) VALUES
(1, 'See who viewed you', 'Know exactly who visited your profile', 'visibility', 1, 1),
(2, 'Unlimited Interests', 'Send interest to as many profiles as you want', 'send', 2, 1),
(3, 'Unlimited Messaging', 'Chat without any restrictions', 'chat', 3, 1),
(4, 'Profile Highlight', 'Get highlighted in search results', 'verified', 4, 1),
(5, 'Ad Free', 'Enjoy an ad-free experience', 'block', 5, 1),
(6, 'Priority Support', '24/7 dedicated customer support', 'star', 6, 1);

-- --------------------------------------------------------

--
-- Table structure for table `upgrade_plans`
--

CREATE TABLE `upgrade_plans` (
  `id` int(11) NOT NULL,
  `label` varchar(50) NOT NULL,
  `price` varchar(20) NOT NULL,
  `original_price` varchar(20) NOT NULL,
  `discount` varchar(20) NOT NULL,
  `is_best_value` tinyint(1) DEFAULT 0,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `upgrade_plans`
--

INSERT INTO `upgrade_plans` (`id`, `label`, `price`, `original_price`, `discount`, `is_best_value`, `sort_order`, `is_active`) VALUES
(1, '1 Month', '₹999', '₹1,999', '50% OFF', 0, 1, 1),
(2, '3 Months', '₹1,999', '₹5,499', '22% OFF', 1, 2, 1),
(3, '6 Months', '₹2,999', '₹9,999', '70% OFF', 0, 3, 1);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `country_code` varchar(10) DEFAULT '+91',
  `otp` varchar(6) DEFAULT NULL,
  `otp_expires_at` datetime DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT 0,
  `auth_token` varchar(255) DEFAULT NULL,
  `token_expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `phone`, `country_code`, `otp`, `otp_expires_at`, `is_verified`, `auth_token`, `token_expires_at`, `created_at`, `updated_at`) VALUES
(1, '9999999999', '+91', NULL, NULL, 1, 'MXwxNzgzMzE3NTIxfDEzNzRlZTU1NGNlNTRhMTU5YTEzNzdiMDk1NWQxOTIz', '2026-08-05 05:58:41', '2026-07-03 13:00:51', '2026-07-06 05:58:41'),
(2, '8860472433', '+91', NULL, NULL, 1, 'MnwxNzgzNTEwODM0fDgxY2ZjZDdkNDNlMDcwMjUyNzJiNDVkZDFjYmFlZDZj', '2026-08-07 11:40:34', '2026-07-03 13:04:19', '2026-07-08 11:40:34'),
(3, '9876543210', '+91', NULL, NULL, 1, 'M3wxNzgzMzE2OTY3fDQwNWM5MDQ4YzNmNjFmMTQwNTYwZmIzMjdkMDBjMGYx', '2026-08-05 05:49:27', '2026-07-06 05:49:03', '2026-07-06 05:49:27'),
(4, '8860172433', '+91', NULL, NULL, 1, 'NHwxNzgzMzE3Mzk0fDEyNWVlZGVjMTFjNTdjN2I1ODdiYjQ5YTViODZjYWRm', '2026-08-05 05:56:34', '2026-07-06 05:56:29', '2026-07-06 05:56:34'),
(5, '9215886655', '+91', NULL, NULL, 1, 'NXwxNzgzMzE3NDgxfDZmMGQ5MGU4MWU1MTA1Mjc3NDZmZGZhMmU5Y2IxZjIx', '2026-08-05 05:58:01', '2026-07-06 05:57:58', '2026-07-06 05:58:01'),
(101, '9111111101', '+91', NULL, NULL, 1, NULL, NULL, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(102, '9111111102', '+91', NULL, NULL, 1, NULL, NULL, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(103, '9111111103', '+91', NULL, NULL, 1, NULL, NULL, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(104, '9111111104', '+91', NULL, NULL, 1, NULL, NULL, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(105, '9111111105', '+91', NULL, NULL, 1, NULL, NULL, '2026-07-08 07:17:16', '2026-07-08 07:17:16');

-- --------------------------------------------------------

--
-- Table structure for table `user_education`
--

CREATE TABLE `user_education` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `education_id` int(11) DEFAULT NULL,
  `profession` varchar(150) DEFAULT NULL,
  `income_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_education`
--

INSERT INTO `user_education` (`id`, `user_id`, `education_id`, `profession`, `income_id`, `created_at`, `updated_at`) VALUES
(1, 2, 1, 'delhi', 11, '2026-07-03 13:04:53', '2026-07-03 13:04:53'),
(2, 101, 5, 'Software Engineer', 5, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(3, 102, 5, 'Marketing Manager', 6, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(4, 103, 6, 'Doctor', 7, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(5, 104, 5, 'Teacher', 4, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(6, 105, 6, 'Finance Analyst', 6, '2026-07-08 07:17:16', '2026-07-08 07:17:16');

-- --------------------------------------------------------

--
-- Table structure for table `user_habits`
--

CREATE TABLE `user_habits` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `height_id` int(11) DEFAULT NULL,
  `weight` varchar(20) DEFAULT NULL,
  `eating_habit_id` int(11) DEFAULT NULL,
  `smoking_habit_id` int(11) DEFAULT NULL,
  `drinking_habit_id` int(11) DEFAULT NULL,
  `disability_id` int(11) DEFAULT NULL,
  `marital_status_id` int(11) DEFAULT NULL,
  `body_type_id` int(11) DEFAULT NULL,
  `complexion_id` int(11) DEFAULT NULL,
  `blood_group_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_habits`
--

INSERT INTO `user_habits` (`id`, `user_id`, `height_id`, `weight`, `eating_habit_id`, `smoking_habit_id`, `drinking_habit_id`, `disability_id`, `marital_status_id`, `body_type_id`, `complexion_id`, `blood_group_id`, `created_at`, `updated_at`) VALUES
(1, 2, 6, '46 kg', 2, 3, 2, 2, 3, 2, 1, 5, '2026-07-03 13:05:21', '2026-07-03 13:05:21'),
(2, 101, 9, '52 kg', 1, 1, 1, 1, 1, 2, 2, 3, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(3, 102, 12, '55 kg', 1, 1, 1, 1, 1, 1, 1, 1, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(4, 103, 8, '50 kg', 1, 1, 1, 1, 1, 2, 3, 7, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(5, 104, 11, '58 kg', 1, 1, 2, 1, 1, 2, 2, 5, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(6, 105, 10, '48 kg', 2, 1, 1, 1, 1, 1, 1, 3, '2026-07-08 07:17:16', '2026-07-08 07:17:16');

-- --------------------------------------------------------

--
-- Table structure for table `user_interactions`
--

CREATE TABLE `user_interactions` (
  `id` int(11) NOT NULL,
  `from_user_id` int(11) NOT NULL,
  `to_user_id` int(11) NOT NULL,
  `type` enum('interest','shortlist','ignore','chat') NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_interactions`
--

INSERT INTO `user_interactions` (`id`, `from_user_id`, `to_user_id`, `type`, `created_at`, `updated_at`) VALUES
(4, 2, 105, 'interest', '2026-07-08 08:02:59', '2026-07-08 08:02:59'),
(5, 2, 101, 'ignore', '2026-07-08 08:03:31', '2026-07-08 08:03:31'),
(11, 2, 101, 'interest', '2026-07-08 11:43:42', '2026-07-08 11:43:42');

-- --------------------------------------------------------

--
-- Table structure for table `user_location`
--

CREATE TABLE `user_location` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `state_id` int(11) DEFAULT NULL,
  `city` varchar(150) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_location`
--

INSERT INTO `user_location` (`id`, `user_id`, `state_id`, `city`, `created_at`, `updated_at`) VALUES
(1, 2, 23, 'banglore', '2026-07-03 13:04:45', '2026-07-03 13:04:45'),
(2, 101, 29, 'Delhi', '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(3, 102, 14, 'Mumbai', '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(4, 103, 26, 'Lucknow', '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(5, 104, 8, 'Gurugram', '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(6, 105, 7, 'Ahmedabad', '2026-07-08 07:17:16', '2026-07-08 07:17:16');

-- --------------------------------------------------------

--
-- Table structure for table `user_partner_preference`
--

CREATE TABLE `user_partner_preference` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `age_min` int(11) DEFAULT 18,
  `age_max` int(11) DEFAULT 35,
  `religion_id` int(11) DEFAULT NULL,
  `min_height_id` int(11) DEFAULT NULL,
  `max_height_id` int(11) DEFAULT NULL,
  `income_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_partner_preference`
--

INSERT INTO `user_partner_preference` (`id`, `user_id`, `age_min`, `age_max`, `religion_id`, `min_height_id`, `max_height_id`, `income_id`, `created_at`, `updated_at`) VALUES
(1, 2, 22, 35, NULL, NULL, NULL, NULL, '2026-07-03 13:05:57', '2026-07-03 13:05:57');

-- --------------------------------------------------------

--
-- Table structure for table `user_photos`
--

CREATE TABLE `user_photos` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `photo_path` varchar(255) NOT NULL,
  `is_primary` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_profiles`
--

CREATE TABLE `user_profiles` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `profile_for` varchar(50) DEFAULT NULL,
  `full_name` varchar(150) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `profile_photo` varchar(255) DEFAULT NULL,
  `is_profile_complete` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_profiles`
--

INSERT INTO `user_profiles` (`id`, `user_id`, `profile_for`, `full_name`, `dob`, `gender`, `bio`, `profile_photo`, `is_profile_complete`, `created_at`, `updated_at`) VALUES
(1, 2, 'Myself', 'nitin', '2000-01-01', 'Male', NULL, 'usernitin.png', 1, '2026-07-03 13:04:25', '2026-07-08 11:21:26'),
(3, 4, 'Myself', 'komal', '2026-07-09', 'Female', NULL, '8b4bb548d4086f8e0fe30d4fad859238.jpg', 1, '2026-07-06 05:56:45', '2026-07-08 07:35:34'),
(4, 101, 'Myself', 'Priya Sharma', '1998-03-15', 'Female', 'Simple and family-oriented girl from Delhi.', 'images (1).png', 1, '2026-07-08 07:17:16', '2026-07-08 07:35:49'),
(5, 102, 'Myself', 'Anjali Singh', '1997-07-22', 'Female', 'Software engineer who loves music and travel.', 'images.png', 1, '2026-07-08 07:17:16', '2026-07-08 07:36:08'),
(6, 103, 'Myself', 'Neha Gupta', '1999-11-05', 'Female', 'Doctor by profession, caring and humble.', 'pexels-mehedi-36114636.jpg', 1, '2026-07-08 07:17:16', '2026-07-08 07:36:22'),
(7, 104, 'Myself', 'Pooja Verma', '1996-01-30', 'Female', 'Teacher, loves reading and cooking.', 'premium_photo-1668896122554-2a4456667f65.png', 1, '2026-07-08 07:17:16', '2026-07-08 07:37:56'),
(8, 105, 'Myself', 'Riya Patel', '2000-06-18', 'Female', 'MBA graduate, working in finance sector.', 'woman-outdoors-nature-painting_23-2148740763.png', 1, '2026-07-08 07:17:16', '2026-07-08 07:38:13');

-- --------------------------------------------------------

--
-- Table structure for table `user_religion`
--

CREATE TABLE `user_religion` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `religion_id` int(11) DEFAULT NULL,
  `caste` varchar(150) DEFAULT NULL,
  `mother_tongue_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_religion`
--

INSERT INTO `user_religion` (`id`, `user_id`, `religion_id`, `caste`, `mother_tongue_id`, `created_at`, `updated_at`) VALUES
(1, 2, 1, 'Delhi', 1, '2026-07-03 13:04:38', '2026-07-03 13:05:23'),
(2, 101, 1, 'Brahmin', 1, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(3, 102, 1, 'Rajput', 1, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(4, 103, 1, 'Gupta', 1, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(5, 104, 1, 'Verma', 1, '2026-07-08 07:17:16', '2026-07-08 07:17:16'),
(6, 105, 1, 'Patel', 3, '2026-07-08 07:17:16', '2026-07-08 07:17:16');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `blood_groups`
--
ALTER TABLE `blood_groups`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `body_types`
--
ALTER TABLE `body_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `complexions`
--
ALTER TABLE `complexions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `country_codes`
--
ALTER TABLE `country_codes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `disabilities`
--
ALTER TABLE `disabilities`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `drinking_habits`
--
ALTER TABLE `drinking_habits`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `eating_habits`
--
ALTER TABLE `eating_habits`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `education_levels`
--
ALTER TABLE `education_levels`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `heights`
--
ALTER TABLE `heights`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `income_ranges`
--
ALTER TABLE `income_ranges`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `marital_statuses`
--
ALTER TABLE `marital_statuses`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mother_tongues`
--
ALTER TABLE `mother_tongues`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `profile_for_options`
--
ALTER TABLE `profile_for_options`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `religions`
--
ALTER TABLE `religions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `smoking_habits`
--
ALTER TABLE `smoking_habits`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `states`
--
ALTER TABLE `states`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `upgrade_features`
--
ALTER TABLE `upgrade_features`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `upgrade_plans`
--
ALTER TABLE `upgrade_plans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone` (`phone`);

--
-- Indexes for table `user_education`
--
ALTER TABLE `user_education`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `education_id` (`education_id`),
  ADD KEY `income_id` (`income_id`);

--
-- Indexes for table `user_habits`
--
ALTER TABLE `user_habits`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `height_id` (`height_id`),
  ADD KEY `eating_habit_id` (`eating_habit_id`),
  ADD KEY `smoking_habit_id` (`smoking_habit_id`),
  ADD KEY `drinking_habit_id` (`drinking_habit_id`),
  ADD KEY `disability_id` (`disability_id`),
  ADD KEY `marital_status_id` (`marital_status_id`),
  ADD KEY `body_type_id` (`body_type_id`),
  ADD KEY `complexion_id` (`complexion_id`),
  ADD KEY `blood_group_id` (`blood_group_id`);

--
-- Indexes for table `user_interactions`
--
ALTER TABLE `user_interactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_interaction` (`from_user_id`,`to_user_id`,`type`),
  ADD KEY `to_user_id` (`to_user_id`);

--
-- Indexes for table `user_location`
--
ALTER TABLE `user_location`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `state_id` (`state_id`);

--
-- Indexes for table `user_partner_preference`
--
ALTER TABLE `user_partner_preference`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `religion_id` (`religion_id`),
  ADD KEY `min_height_id` (`min_height_id`),
  ADD KEY `max_height_id` (`max_height_id`),
  ADD KEY `income_id` (`income_id`);

--
-- Indexes for table `user_photos`
--
ALTER TABLE `user_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `user_religion`
--
ALTER TABLE `user_religion`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `religion_id` (`religion_id`),
  ADD KEY `mother_tongue_id` (`mother_tongue_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `blood_groups`
--
ALTER TABLE `blood_groups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `body_types`
--
ALTER TABLE `body_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `complexions`
--
ALTER TABLE `complexions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `country_codes`
--
ALTER TABLE `country_codes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `disabilities`
--
ALTER TABLE `disabilities`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `drinking_habits`
--
ALTER TABLE `drinking_habits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `eating_habits`
--
ALTER TABLE `eating_habits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `education_levels`
--
ALTER TABLE `education_levels`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `heights`
--
ALTER TABLE `heights`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `income_ranges`
--
ALTER TABLE `income_ranges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `marital_statuses`
--
ALTER TABLE `marital_statuses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `mother_tongues`
--
ALTER TABLE `mother_tongues`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `profile_for_options`
--
ALTER TABLE `profile_for_options`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `religions`
--
ALTER TABLE `religions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `smoking_habits`
--
ALTER TABLE `smoking_habits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `states`
--
ALTER TABLE `states`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `upgrade_features`
--
ALTER TABLE `upgrade_features`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `upgrade_plans`
--
ALTER TABLE `upgrade_plans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=106;

--
-- AUTO_INCREMENT for table `user_education`
--
ALTER TABLE `user_education`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_habits`
--
ALTER TABLE `user_habits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_interactions`
--
ALTER TABLE `user_interactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `user_location`
--
ALTER TABLE `user_location`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_partner_preference`
--
ALTER TABLE `user_partner_preference`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_photos`
--
ALTER TABLE `user_photos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_profiles`
--
ALTER TABLE `user_profiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `user_religion`
--
ALTER TABLE `user_religion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `user_education`
--
ALTER TABLE `user_education`
  ADD CONSTRAINT `user_education_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_education_ibfk_2` FOREIGN KEY (`education_id`) REFERENCES `education_levels` (`id`),
  ADD CONSTRAINT `user_education_ibfk_3` FOREIGN KEY (`income_id`) REFERENCES `income_ranges` (`id`);

--
-- Constraints for table `user_habits`
--
ALTER TABLE `user_habits`
  ADD CONSTRAINT `user_habits_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_habits_ibfk_10` FOREIGN KEY (`blood_group_id`) REFERENCES `blood_groups` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_2` FOREIGN KEY (`height_id`) REFERENCES `heights` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_3` FOREIGN KEY (`eating_habit_id`) REFERENCES `eating_habits` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_4` FOREIGN KEY (`smoking_habit_id`) REFERENCES `smoking_habits` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_5` FOREIGN KEY (`drinking_habit_id`) REFERENCES `drinking_habits` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_6` FOREIGN KEY (`disability_id`) REFERENCES `disabilities` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_7` FOREIGN KEY (`marital_status_id`) REFERENCES `marital_statuses` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_8` FOREIGN KEY (`body_type_id`) REFERENCES `body_types` (`id`),
  ADD CONSTRAINT `user_habits_ibfk_9` FOREIGN KEY (`complexion_id`) REFERENCES `complexions` (`id`);

--
-- Constraints for table `user_interactions`
--
ALTER TABLE `user_interactions`
  ADD CONSTRAINT `user_interactions_ibfk_1` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_interactions_ibfk_2` FOREIGN KEY (`to_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_location`
--
ALTER TABLE `user_location`
  ADD CONSTRAINT `user_location_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_location_ibfk_2` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`);

--
-- Constraints for table `user_partner_preference`
--
ALTER TABLE `user_partner_preference`
  ADD CONSTRAINT `user_partner_preference_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_partner_preference_ibfk_2` FOREIGN KEY (`religion_id`) REFERENCES `religions` (`id`),
  ADD CONSTRAINT `user_partner_preference_ibfk_3` FOREIGN KEY (`min_height_id`) REFERENCES `heights` (`id`),
  ADD CONSTRAINT `user_partner_preference_ibfk_4` FOREIGN KEY (`max_height_id`) REFERENCES `heights` (`id`),
  ADD CONSTRAINT `user_partner_preference_ibfk_5` FOREIGN KEY (`income_id`) REFERENCES `income_ranges` (`id`);

--
-- Constraints for table `user_photos`
--
ALTER TABLE `user_photos`
  ADD CONSTRAINT `user_photos_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD CONSTRAINT `user_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_religion`
--
ALTER TABLE `user_religion`
  ADD CONSTRAINT `user_religion_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_religion_ibfk_2` FOREIGN KEY (`religion_id`) REFERENCES `religions` (`id`),
  ADD CONSTRAINT `user_religion_ibfk_3` FOREIGN KEY (`mother_tongue_id`) REFERENCES `mother_tongues` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
