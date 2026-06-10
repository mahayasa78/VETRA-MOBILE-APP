-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3308
-- Generation Time: Jun 07, 2026 at 08:38 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.3.31

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `vetra_web_new`
--

-- --------------------------------------------------------

--
-- Table structure for table `api_keys`
--

CREATE TABLE `api_keys` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `key_hash` varchar(64) NOT NULL,
  `key_prefix` varchar(8) NOT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `articles`
--

CREATE TABLE `articles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `author_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `content` longtext NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL,
  `is_published` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `articles`
--

INSERT INTO `articles` (`id`, `author_id`, `title`, `slug`, `description`, `content`, `image_url`, `tags`, `is_published`, `created_at`, `updated_at`) VALUES
(1, 1, 'Tips Menjaga Kesehatan Kucing Peliharaan', 'tips-menjaga-kesehatan-kucing-peliharaan-eIQl0r', 'Panduan lengkap cara menjaga kesehatan kucing agar tetap aktif dan bahagia.', 'Kucing adalah hewan yang mandiri, namun tetap membutuhkan perawatan yang baik...', NULL, 'kucing,kesehatan,perawatan', 1, '2026-06-06 06:33:09', '2026-06-06 06:33:09'),
(2, 1, 'Mengenal Vaksin Wajib untuk Anjing', 'mengenal-vaksin-wajib-untuk-anjing-uaDH2y', 'Jadwal dan jenis vaksin penting yang harus diberikan pada anjing peliharaan Anda.', 'Vaksinasi adalah salah satu cara terpenting untuk menjaga kesehatan anjing...', NULL, 'anjing,vaksin,kesehatan', 1, '2026-06-06 06:33:09', '2026-06-06 06:33:09'),
(3, 1, 'test', 'test-CM1GaE', 'test', 'test', NULL, NULL, 0, '2026-06-07 10:05:42', '2026-06-07 10:06:21');

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `doctor_id` bigint(20) UNSIGNED DEFAULT NULL,
  `clinic_id` bigint(20) UNSIGNED NOT NULL,
  `pet_id` bigint(20) UNSIGNED DEFAULT NULL,
  `complaint` text DEFAULT NULL,
  `booking_date` date NOT NULL,
  `booking_time` time NOT NULL,
  `scheduled_at` datetime NOT NULL,
  `status` enum('pending','confirmed','rejected','done') NOT NULL DEFAULT 'pending',
  `doctor_notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `user_id`, `doctor_id`, `clinic_id`, `pet_id`, `complaint`, `booking_date`, `booking_time`, `scheduled_at`, `status`, `doctor_notes`, `created_at`, `updated_at`) VALUES
(1, 11, 5, 2, NULL, NULL, '2026-06-11', '16:09:00', '2026-06-11 16:09:00', 'confirmed', NULL, '2026-06-07 09:06:12', '2026-06-07 09:23:12'),
(2, 11, 5, 2, NULL, NULL, '2026-06-17', '17:15:00', '2026-06-17 17:15:00', 'rejected', 'liburr', '2026-06-07 09:16:02', '2026-06-07 09:23:44');

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cache`
--

INSERT INTO `cache` (`key`, `value`, `expiration`) VALUES
('vetra-cache-9YtJ6PkOeDe7bZIX', 's:7:\"forever\";', 2096222124),
('vetra-cache-Ck1SunZCDVpZj3sv', 's:7:\"forever\";', 2096208998),
('vetra-cache-dxpaN7m5ocWGrjAy', 's:7:\"forever\";', 2096215530),
('vetra-cache-JcoXwrzAczWcmIvx', 's:7:\"forever\";', 2096209940),
('vetra-cache-kd3QnrY0TpaxEV8o', 's:7:\"forever\";', 2096208431),
('vetra-cache-NHpjk3ouf6OpfoHU', 's:7:\"forever\";', 2096208831),
('vetra-cache-nW7swpcscGOGcmZg', 's:7:\"forever\";', 2096215432),
('vetra-cache-PmNp52FzK2smGnVD', 's:7:\"forever\";', 2096208282),
('vetra-cache-Q5rM82trsbl5CDOk', 's:7:\"forever\";', 2096219163),
('vetra-cache-QTqG3VBvayWD1V0Q', 's:7:\"forever\";', 2096219472),
('vetra-cache-RbylWsX80He3TsIV', 's:7:\"forever\";', 2096215350),
('vetra-cache-Ri24hGh2Hg24Ivzu', 's:7:\"forever\";', 2096215475),
('vetra-cache-upzSRvWxXQOo8atz', 's:7:\"forever\";', 2096118347),
('vetra-cache-UqYlbKCfVz6mPxtg', 's:7:\"forever\";', 2096207904),
('vetra-cache-XL7NqPYPFGjXz2GH', 's:7:\"forever\";', 2096116075),
('vetra-cache-ZoUJeQCm6KwPadx6', 's:7:\"forever\";', 2096216393);

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chats`
--

CREATE TABLE `chats` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `doctor_id` bigint(20) UNSIGNED NOT NULL,
  `last_message` text DEFAULT NULL,
  `last_sender_id` bigint(20) UNSIGNED DEFAULT NULL,
  `unread_doctor` int(11) NOT NULL DEFAULT 0,
  `unread_user` int(11) NOT NULL DEFAULT 0,
  `last_timestamp` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chats`
--

INSERT INTO `chats` (`id`, `user_id`, `doctor_id`, `last_message`, `last_sender_id`, `unread_doctor`, `unread_user`, `last_timestamp`, `created_at`, `updated_at`) VALUES
(1, 11, 5, 'halo', 5, 0, 1, '2026-06-07 09:04:15', '2026-06-07 08:57:40', '2026-06-07 09:04:15'),
(2, 11, 6, NULL, NULL, 0, 0, '2026-06-07 09:05:15', '2026-06-07 09:05:15', '2026-06-07 09:05:15');

-- --------------------------------------------------------

--
-- Table structure for table `clinic_profiles`
--

CREATE TABLE `clinic_profiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `address` text DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `is_open` tinyint(1) NOT NULL DEFAULT 1,
  `operational_hours` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`operational_hours`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `clinic_profiles`
--

INSERT INTO `clinic_profiles` (`id`, `user_id`, `address`, `phone`, `latitude`, `longitude`, `is_open`, `operational_hours`, `created_at`, `updated_at`) VALUES
(1, 2, 'Jl. Merdeka No. 1, Jakarta Pusat', '0812-0001-0001', NULL, NULL, 1, '{\"Senin\":{\"isOpen\":true,\"open\":\"08:00\",\"close\":\"17:00\"},\"Selasa\":{\"isOpen\":true,\"open\":\"08:00\",\"close\":\"17:00\"},\"Rabu\":{\"isOpen\":true,\"open\":\"08:00\",\"close\":\"17:00\"},\"Kamis\":{\"isOpen\":true,\"open\":\"08:00\",\"close\":\"17:00\"},\"Jumat\":{\"isOpen\":true,\"open\":\"08:00\",\"close\":\"15:00\"},\"Sabtu\":{\"isOpen\":true,\"open\":\"09:00\",\"close\":\"14:00\"},\"Minggu\":{\"isOpen\":false,\"open\":null,\"close\":null}}', '2026-06-06 06:33:07', '2026-06-06 06:33:07'),
(2, 3, 'Jl. Dago No. 88, Bandung', '0813-0002-0002', NULL, NULL, 1, '{\"Senin\":{\"isOpen\":true,\"open\":\"09:00\",\"close\":\"18:00\"},\"Selasa\":{\"isOpen\":true,\"open\":\"09:00\",\"close\":\"18:00\"},\"Rabu\":{\"isOpen\":true,\"open\":\"09:00\",\"close\":\"18:00\"},\"Kamis\":{\"isOpen\":true,\"open\":\"09:00\",\"close\":\"18:00\"},\"Jumat\":{\"isOpen\":true,\"open\":\"09:00\",\"close\":\"18:00\"},\"Sabtu\":{\"isOpen\":true,\"open\":\"10:00\",\"close\":\"16:00\"},\"Minggu\":{\"isOpen\":true,\"open\":\"10:00\",\"close\":\"14:00\"}}', '2026-06-06 06:33:07', '2026-06-06 06:33:07'),
(3, 4, 'Jl. HR Muhammad No. 45, Surabaya', '0814-0003-0003', NULL, NULL, 1, '{\"Senin\":{\"isOpen\":true,\"open\":\"07:00\",\"close\":\"19:00\"},\"Selasa\":{\"isOpen\":true,\"open\":\"07:00\",\"close\":\"19:00\"},\"Rabu\":{\"isOpen\":true,\"open\":\"07:00\",\"close\":\"19:00\"},\"Kamis\":{\"isOpen\":true,\"open\":\"07:00\",\"close\":\"19:00\"},\"Jumat\":{\"isOpen\":true,\"open\":\"07:00\",\"close\":\"16:00\"},\"Sabtu\":{\"isOpen\":true,\"open\":\"08:00\",\"close\":\"17:00\"},\"Minggu\":{\"isOpen\":false,\"open\":null,\"close\":null}}', '2026-06-06 06:33:07', '2026-06-06 06:33:07');

-- --------------------------------------------------------

--
-- Table structure for table `contact_messages`
--

CREATE TABLE `contact_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `subject` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `admin_reply` text DEFAULT NULL,
  `replied_at` timestamp NULL DEFAULT NULL,
  `replied_by` bigint(20) UNSIGNED DEFAULT NULL,
  `status` enum('unread','read','replied') NOT NULL DEFAULT 'unread',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `contact_messages`
--

INSERT INTO `contact_messages` (`id`, `name`, `email`, `phone`, `subject`, `message`, `admin_reply`, `replied_at`, `replied_by`, `status`, `created_at`, `updated_at`) VALUES
(1, 'turbo', 'dokter@vetra.id', '085122345678', 'menyapa operator', 'haloo', NULL, NULL, NULL, 'read', '2026-06-07 11:03:01', '2026-06-07 11:03:34'),
(2, 'turbo', 'dokter@vetra.id', '085122345678', 'menyapa operator', 'test', 'test juga', '2026-06-07 11:05:16', 1, 'replied', '2026-06-07 11:04:27', '2026-06-07 11:05:16'),
(3, 'turbo', 'madeagusmahayasa@gmail.com', '085122345678', 'menyapa operator', 'test', 'testtt', '2026-06-07 11:20:59', 1, 'replied', '2026-06-07 11:20:16', '2026-06-07 11:20:59'),
(4, 'turbo', 'madeagusmahayasa@gmail.com', '085122345678', 'menyapa operator', 'tset', 'test', '2026-06-07 12:07:05', 1, 'replied', '2026-06-07 12:06:18', '2026-06-07 12:07:05');

-- --------------------------------------------------------

--
-- Table structure for table `doctor_profiles`
--

CREATE TABLE `doctor_profiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `clinic_id` bigint(20) UNSIGNED DEFAULT NULL,
  `spesialis` varchar(255) NOT NULL DEFAULT 'Dokter Hewan Umum',
  `bio` text DEFAULT NULL,
  `experience_years` int(11) NOT NULL DEFAULT 0,
  `is_online` tinyint(1) NOT NULL DEFAULT 0,
  `license_number` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `doctor_profiles`
--

INSERT INTO `doctor_profiles` (`id`, `user_id`, `clinic_id`, `spesialis`, `bio`, `experience_years`, `is_online`, `license_number`, `created_at`, `updated_at`) VALUES
(1, 5, 2, 'Dokter Hewan Umum', 'Berpengalaman 5 tahun dalam menangani anjing dan kucing.', 5, 1, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(2, 6, 2, 'Spesialis Bedah Hewan', 'Ahli bedah hewan dengan pengalaman lebih dari 8 tahun.', 8, 0, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(3, 7, 3, 'Spesialis Kucing', 'Fokus pada perawatan dan pengobatan kucing.', 6, 1, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(4, 8, 4, 'Spesialis Eksotis', 'Spesialis dalam menangani hewan eksotis seperti reptil dan burung.', 4, 1, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(5, 9, 4, 'Dokter Hewan Umum', 'Dokter hewan muda dengan semangat tinggi untuk melayani.', 3, 0, NULL, '2026-06-06 06:33:09', '2026-06-06 06:33:09'),
(6, 10, NULL, 'Konsultan Gizi Hewan', 'Spesialis nutrisi dan gizi hewan peliharaan.', 7, 1, NULL, '2026-06-06 06:33:09', '2026-06-06 06:33:09');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` varchar(255) NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` smallint(5) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `chat_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED NOT NULL,
  `content` text NOT NULL,
  `message_type` enum('text','image') NOT NULL DEFAULT 'text',
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `chat_id`, `sender_id`, `content`, `message_type`, `is_read`, `created_at`, `updated_at`) VALUES
(1, 1, 11, 'p', 'text', 1, '2026-06-07 08:57:50', '2026-06-07 09:04:09'),
(2, 1, 5, 'halo', 'text', 0, '2026-06-07 09:04:15', '2026-06-07 09:04:15');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_05_31_095030_create_pets_table', 1),
(5, '2026_05_31_095031_create_reviews_table', 1),
(6, '2026_05_31_095041_create_notifications_table', 1),
(7, '2026_05_31_095042_create_api_keys_table', 1),
(8, '2026_05_31_095044_create_clinic_profiles_table', 1),
(9, '2026_05_31_095047_create_bookings_table', 1),
(10, '2026_05_31_095059_create_chats_table', 1),
(11, '2026_05_31_095059_create_messages_table', 1),
(12, '2026_05_31_095100_create_articles_table', 1),
(13, '2026_05_31_101523_create_doctor_profiles_table', 1),
(14, '2026_06_08_100000_create_contact_messages_table', 2);

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `type` varchar(255) NOT NULL,
  `reference_id` bigint(20) UNSIGNED DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `body`, `type`, `reference_id`, `is_read`, `created_at`, `updated_at`) VALUES
(1, 5, 'Pesan Baru', 'p', 'chat_message', 1, 0, '2026-06-07 08:57:50', '2026-06-07 08:57:50'),
(2, 11, 'Pesan Baru', 'halo', 'chat_message', 1, 0, '2026-06-07 09:04:15', '2026-06-07 09:04:15'),
(3, 11, 'Booking Berhasil Dibuat', 'Booking Anda sedang menunggu konfirmasi klinik.', 'booking_update', 1, 0, '2026-06-07 09:06:12', '2026-06-07 09:06:12'),
(4, 11, 'Booking Berhasil Dibuat', 'Booking Anda sedang menunggu konfirmasi.', 'booking_update', 2, 0, '2026-06-07 09:16:02', '2026-06-07 09:16:02'),
(5, 5, 'Booking Baru', 'Anda mendapat booking baru. Segera konfirmasi!', 'new_booking', 2, 0, '2026-06-07 09:16:02', '2026-06-07 09:16:02'),
(6, 11, 'Booking Dikonfirmasi! 🎉', 'Booking Anda telah disetujui oleh dokter.', 'booking_update', 1, 0, '2026-06-07 09:23:12', '2026-06-07 09:23:12'),
(7, 11, 'Booking Ditolak ⚠️', 'Booking Anda tidak dapat diproses.', 'booking_update', 2, 0, '2026-06-07 09:23:44', '2026-06-07 09:23:44');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pets`
--

CREATE TABLE `pets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `species` varchar(255) NOT NULL,
  `breed` varchar(255) DEFAULT NULL,
  `age` int(11) DEFAULT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `gender` enum('male','female','unknown') NOT NULL DEFAULT 'unknown',
  `photo` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pets`
--

INSERT INTO `pets` (`id`, `user_id`, `name`, `species`, `breed`, `age`, `weight`, `gender`, `photo`, `notes`, `created_at`, `updated_at`) VALUES
(1, 11, 'turbo', 'Kucing', 'persia', 1, 4.00, 'unknown', NULL, NULL, '2026-06-07 09:06:34', '2026-06-07 09:06:34');

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `target_id` bigint(20) UNSIGNED NOT NULL,
  `target_type` enum('doctor','clinic') NOT NULL,
  `rating` tinyint(4) NOT NULL,
  `comment` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('LDPJgQ7j1dLl1ui29JBPRqb2iVeU1fWw1CpfgA86', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0', 'eyJfdG9rZW4iOiJ1M1huWUxvVUl4dHdQa1VnNkt2akdXWEhJQWExNE5zZlYzd3FxYmdxIiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cLzEyNy4wLjAuMTo4MDAwXC9jaGF0Ym90Iiwicm91dGUiOiJ1c2VyLmNoYXRib3QifSwiX2ZsYXNoIjp7Im9sZCI6W10sIm5ldyI6W119fQ==', 1780862314);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) DEFAULT NULL,
  `role` enum('user','doctor','clinic','admin') NOT NULL DEFAULT 'user',
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `profile_pic` varchar(255) DEFAULT NULL,
  `google_id` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `phone`, `address`, `profile_pic`, `google_id`, `is_active`, `email_verified_at`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Admin VETRA', 'admin@vetra.id', '$2y$12$wy3SEPNQT0foP5nY6ZPP0eVdmXLvmxEoWgvf7h6w0q3Q0niXK9zMq', 'admin', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:07', '2026-06-06 06:33:07'),
(2, 'Klinik Hewan Sehat', 'klinik@vetra.id', '$2y$12$oH3P6OXa9qmDpG9WQnpkNeLtNSPoqkXLHmy.hTM1pYW4kZkAH9.XW', 'clinic', '0812-0001-0001', NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:07', '2026-06-06 06:33:07'),
(3, 'Pet Care Center Bandung', 'petcare@vetra.id', '$2y$12$D8AyKtxQWpeok31aKCxUduY9qveKxgFsB/10A00S5.BTBYkpd/2p.', 'clinic', '0813-0002-0002', NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:07', '2026-06-06 06:33:07'),
(4, 'Animal Hospital Surabaya', 'animalhosp@vetra.id', '$2y$12$4YUEZh.07F7RTrIjVqI01e3whDBxVnd9Telz7EWBZlYJBfTgQ3CK2', 'clinic', '0814-0003-0003', NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:07', '2026-06-06 06:33:07'),
(5, 'Budi Santoso', 'dokter@vetra.id', '$2y$12$n.fBohARTpOf52lZL2GoreQ22fil2FAt9TNKMjFV75rmSEu3Y9yx6', 'doctor', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(6, 'Siti Nurhaliza', 'siti@vetra.id', '$2y$12$V/GIy.CAUWtxKoIgiJzNGOph/Egieoo2jM4ZkXqtw0V6pwR6OaANK', 'doctor', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(7, 'Andi Wijaya', 'andi.dokter@vetra.id', '$2y$12$L4egBoBFCALHf/WkuyRFIefq73/Xa/rguSwrEFzIES/LSyAGjxXha', 'doctor', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(8, 'Dewi Lestari', 'dewi.dokter@vetra.id', '$2y$12$kkYfb8k1fx12/h.HbjyuJOPZv6KPJk1/ALYhl72GZMwtTdQxQHmSW', 'doctor', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:08', '2026-06-06 06:33:08'),
(9, 'Rudi Hermawan', 'rudi.dokter@vetra.id', '$2y$12$yW1SCk2XW17H.s1hMiqcs.i5CaALC.lFn5PBqI/JRnrQmK0I9p3KG', 'doctor', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:09', '2026-06-06 06:33:09'),
(10, 'Maya Kusuma', 'maya.dokter@vetra.id', '$2y$12$WJmYPpvrDF5RsUW6pZFgzuwIGRHhtnU/Hc742rAVLRv0pJiVGl1cm', 'doctor', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:09', '2026-06-06 06:33:09'),
(11, 'Andi Pratama', 'user@vetra.id', '$2y$12$6lhy2AyDlqBDMvaQX9zfy.Y3ddC.BaVmW5cGiXNywe69GjXB1.kZy', 'user', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-06 06:33:09', '2026-06-06 06:33:09'),
(12, 'mh', 'mh@vetra.id', '$2y$12$16BoGVhlhUpQIRJSyPOFBeiPLWKRJ9waKWeLn35PPkpVMrHS/ZlR2', 'user', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-06-07 11:01:57', '2026-06-07 11:01:57');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `api_keys`
--
ALTER TABLE `api_keys`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `api_keys_key_hash_unique` (`key_hash`),
  ADD KEY `api_keys_user_id_foreign` (`user_id`);

--
-- Indexes for table `articles`
--
ALTER TABLE `articles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `articles_slug_unique` (`slug`),
  ADD KEY `articles_author_id_foreign` (`author_id`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `bookings_user_id_foreign` (`user_id`),
  ADD KEY `bookings_doctor_id_foreign` (`doctor_id`),
  ADD KEY `bookings_clinic_id_foreign` (`clinic_id`),
  ADD KEY `bookings_pet_id_foreign` (`pet_id`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `chats`
--
ALTER TABLE `chats`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `chats_user_id_doctor_id_unique` (`user_id`,`doctor_id`),
  ADD KEY `chats_doctor_id_foreign` (`doctor_id`);

--
-- Indexes for table `clinic_profiles`
--
ALTER TABLE `clinic_profiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `clinic_profiles_user_id_foreign` (`user_id`);

--
-- Indexes for table `contact_messages`
--
ALTER TABLE `contact_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `contact_messages_replied_by_foreign` (`replied_by`),
  ADD KEY `contact_messages_status_created_at_index` (`status`,`created_at`),
  ADD KEY `contact_messages_email_index` (`email`);

--
-- Indexes for table `doctor_profiles`
--
ALTER TABLE `doctor_profiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `doctor_profiles_user_id_foreign` (`user_id`),
  ADD KEY `doctor_profiles_clinic_id_foreign` (`clinic_id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`),
  ADD KEY `failed_jobs_connection_queue_failed_at_index` (`connection`,`queue`,`failed_at`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `messages_chat_id_foreign` (`chat_id`),
  ADD KEY `messages_sender_id_foreign` (`sender_id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notifications_user_id_foreign` (`user_id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `pets`
--
ALTER TABLE `pets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pets_user_id_foreign` (`user_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `reviews_user_id_target_id_target_type_unique` (`user_id`,`target_id`,`target_type`),
  ADD KEY `reviews_target_id_target_type_index` (`target_id`,`target_type`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD UNIQUE KEY `users_google_id_unique` (`google_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `api_keys`
--
ALTER TABLE `api_keys`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `articles`
--
ALTER TABLE `articles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `chats`
--
ALTER TABLE `chats`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `clinic_profiles`
--
ALTER TABLE `clinic_profiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `contact_messages`
--
ALTER TABLE `contact_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `doctor_profiles`
--
ALTER TABLE `doctor_profiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `pets`
--
ALTER TABLE `pets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `api_keys`
--
ALTER TABLE `api_keys`
  ADD CONSTRAINT `api_keys_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `articles`
--
ALTER TABLE `articles`
  ADD CONSTRAINT `articles_author_id_foreign` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_clinic_id_foreign` FOREIGN KEY (`clinic_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `bookings_doctor_id_foreign` FOREIGN KEY (`doctor_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `bookings_pet_id_foreign` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `bookings_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `chats`
--
ALTER TABLE `chats`
  ADD CONSTRAINT `chats_doctor_id_foreign` FOREIGN KEY (`doctor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chats_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `clinic_profiles`
--
ALTER TABLE `clinic_profiles`
  ADD CONSTRAINT `clinic_profiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `contact_messages`
--
ALTER TABLE `contact_messages`
  ADD CONSTRAINT `contact_messages_replied_by_foreign` FOREIGN KEY (`replied_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `doctor_profiles`
--
ALTER TABLE `doctor_profiles`
  ADD CONSTRAINT `doctor_profiles_clinic_id_foreign` FOREIGN KEY (`clinic_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `doctor_profiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_chat_id_foreign` FOREIGN KEY (`chat_id`) REFERENCES `chats` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_sender_id_foreign` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `pets`
--
ALTER TABLE `pets`
  ADD CONSTRAINT `pets_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
