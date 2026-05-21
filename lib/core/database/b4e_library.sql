-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th5 20, 2026 lúc 02:18 PM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `b4e_library`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `books`
--

CREATE TABLE `books` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `publisher` varchar(255) DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  `category_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `status` enum('available','borrowed') NOT NULL DEFAULT 'available',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_deleted` tinyint(1) DEFAULT 0,
  `borrow_count` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `books`
--

INSERT INTO `books` (`id`, `title`, `author`, `publisher`, `year`, `category_id`, `description`, `image_url`, `status`, `created_at`, `updated_at`, `is_deleted`, `borrow_count`) VALUES
(1, 'Nhà Giả Kim', 'Paulo Coelho', 'NXB Văn Học', 2013, 1, 'Tiểu thuyết kể về hành trình của chàng chăn cừu Santiago đi tìm kho báu.', 'img/Book/Nha_gia_kim.png', 'borrowed', '2025-11-26 07:40:19', '2026-05-18 12:34:26', 0, 2),
(2, 'Hai Số Phận', 'Jeffrey Archer', 'NXB Văn Học', 2018, 1, 'Câu chuyện song hành đầy kịch tính về cuộc đời của hai người đàn ông sinh cùng ngày.', 'img/Book/hai_số_phận.webp', 'available', '2025-11-26 07:40:19', '2026-05-11 16:49:12', 0, 2),
(3, 'Người Đua Diều', 'Khaled Hosseini', 'NXB Nhã Nam', 2015, 1, 'Một câu chuyện cảm động về tình bạn, sự phản bội và chuộc lỗi tại Afghanistan.', 'img/Book/nguoi-dua-dieu.png', 'available', '2025-11-26 07:40:19', '2026-05-18 12:59:52', 0, 1),
(4, 'Trăm Năm Cô Đơn', 'Gabriel García Márquez', 'NXB Văn Học', 2010, 7, 'Kiệt tác văn học hiện thực huyền ảo kể về dòng họ Buendía.', 'img/Book/Trăm_năm_cô_đơn.jpeg', 'available', '2025-11-26 07:40:19', '2025-11-26 07:40:19', 0, 0),
(5, 'Số Đỏ', 'Vũ Trọng Phụng', 'NXB Văn Học', 2000, 7, 'Tác phẩm châm biếm kinh điển của văn học Việt Nam.', 'img/Book/số_đỏ.webp', 'available', '2025-11-26 07:40:19', '2025-11-26 07:40:19', 0, 0),
(6, 'Đắc Nhân Tâm', 'Dale Carnegie', 'NXB Tổng Hợp TP.HCM', 2016, 2, 'Nghệ thuật giao tiếp và đối nhân xử thế kinh điển.', 'img/Book/1765506439_-1726817123.jpg', 'available', '2025-11-26 07:40:19', '2025-12-12 02:27:19', 0, 0),
(7, 'Thế Giới Phẳng', 'Thomas L. Friedman', 'NXB Trẻ', 2014, 3, 'Cái nhìn sâu sắc về toàn cầu hóa trong thế kỷ 21.', 'img/Book/Thế_giới_phẳng.jpg', 'borrowed', '2025-11-26 07:40:19', '2025-11-26 07:40:19', 0, 0),
(8, 'Điểm Đến Của Cuộc Đời', 'Đặng Hoàng Giang', 'NXB Hội Nhà Văn', 2020, 4, 'Hành trình đồng hành cùng những người ở cận kề cái chết.', 'img/Book/điểm_đến_của_cuộc_đời.jpg', 'borrowed', '2025-11-26 07:40:19', '2025-11-26 07:40:19', 0, 0),
(9, 'Súng, Vi Trùng và Thép', 'Jared Diamond', 'NXB Tri Thức', 2019, 5, 'Lược sử nhân loại qua các yếu tố địa lý và sinh học.', 'img/Book/súng_vi_trùng_và_thép.webp', 'available', '2025-11-26 07:40:19', '2025-11-26 07:40:19', 0, 0),
(10, 'Vũ Trụ Trong Vỏ Hạt Dẻ', 'Stephen Hawking', 'NXB Trẻ', 2012, 5, 'Khám phá kỳ thú của vật lý lý thuyết.', 'img/Book/vũ_trụ_trong_vỏ_hạt_dẻ.jpg', 'borrowed', '2025-11-26 07:40:19', '2025-11-26 07:40:19', 0, 0),
(11, 'Lược Sử Thời Gian', 'Stephen Hawking', 'NXB Trẻ', 2011, 5, 'Cuốn sách khoa học phổ thông bán chạy nhất mọi thời đại.', 'img/Book/Lược_sử_thời_gian.jpg', 'available', '2025-11-26 07:40:19', '2026-04-23 06:59:18', 0, 1),
(12, 'Gen Vị Kỷ', 'Richard Dawkins', 'NXB Tri Thức', 2015, 5, 'Quan điểm gen là đơn vị trung tâm của sự tiến hóa.', 'img/Book/gen_vị_kỷ.jpg', 'available', '2025-11-26 07:40:19', '2026-05-07 14:25:39', 0, 1),
(13, 'Toán 12 (Giải tích & Hình học)', 'Bộ Giáo dục', 'NXB Giáo Dục', 2023, 6, 'Sách giáo khoa Toán lớp 12 chương trình chuẩn.', 'img/Book/Toán_12.jpg', 'available', '2025-11-26 07:40:19', '2026-04-23 06:59:18', 0, 2),
(14, 'Harry Potter và Hòn đá Phù thủy', 'J.K. Rowling', 'NXB Trẻ', 2020, 1, 'Khởi đầu cuộc hành trình của cậu bé phù thủy Harry Potter.', 'img/Book/1765506377_nxbtre_full_21042022_030444.jpg', 'borrowed', '2025-11-26 07:40:19', '2026-05-11 16:53:08', 0, 1),
(15, 'Dế Mèn Phiêu Lưu Ký', 'Tô Hoài', 'NXB Kim Đồng', 2019, 8, 'Câu chuyện phiêu lưu kinh điển dành cho thiếu nhi Việt Nam.', 'img/Book/1765506344_de_men_phieu_luu_ky_ban_du__to_hoai.jpg', 'available', '2025-11-26 07:40:19', '2025-12-12 02:25:44', 0, 0),
(16, 'Đọc Vị Bất Kỳ Ai', 'David J. Lieberman', 'NXB Lao Động', 2018, 4, 'Phương pháp tâm lý để hiểu rõ suy nghĩ của người khác.', 'img/Book/1765506315_docvibatkiai.jpg', 'available', '2025-11-26 07:40:19', '2025-12-12 02:25:15', 0, 0),
(17, 'Cha Giàu Cha Nghèo', 'Robert Kiyosaki', 'NXB Trẻ', 2021, 3, 'Tư duy tài chính khác biệt giữa người giàu và người nghèo.', 'img/Book/1765506271_cha-giau-cha-ngheo.jpg', 'available', '2025-11-26 07:40:19', '2025-12-12 02:24:31', 0, 0),
(18, 'Tắt Đèn', 'Ngô Tất Tố', 'NXB Văn Học', 2015, 7, 'Bức tranh hiện thực về cuộc sống khốn cùng của nông dân Việt Nam xưa.', 'img/Book/1765506235_Tắt_đèn-Nhã_Nam.jpeg', 'available', '2025-11-26 07:40:19', '2025-12-12 02:23:55', 0, 0),
(19, 'Lão Hạc', 'Nam Cao', 'NXB Văn Học', 2015, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: Hơi cũ', NULL, 'available', '2026-05-20 12:04:32', '2026-05-20 12:04:32', 0, 0),
(20, 'Sapiens: Lược Sử Loài Người', 'Yuval Noah Harari', 'NXB Tri Thức', 2018, 5, 'Tác giả Yuval Noah Harari, một nhà sử học và triết học người Israel, đã kết hợp kiến thức từ nhiều lĩnh vực như sinh học, nhân chủng học, cổ sinh vật học và kinh tế học để khám phá cách thức mà loài người, từ một loài linh trưởng không mấy quan trọng, đã vươn lên thống trị hành tinh. Cuốn sách được chia thành bốn phần chính, tương ứng với bốn cuộc cách mạng lớn định hình lịch sử: \r\nCách mạng Nhận thức: Xảy ra khoảng 70.000 năm trước, đây là bước ngoặt giúp Homo sapiens phát triển khả năng tư duy trừu tượng, ngôn ngữ và khả năng hợp tác linh hoạt trên quy mô lớn, từ đó vượt qua các loài người khác.\r\nCách mạng Nông nghiệp: Bắt đầu khoảng 12.000 năm trước, đánh dấu sự chuyển đổi từ lối sống săn bắt hái lượm sang trồng trọt và chăn nuôi. Harari lập luận rằng đây có thể là \"sai lầm lớn nhất trong lịch sử loài người\", dẫn đến những hệ quả phức tạp như sự phân tầng xã hội, bệnh tật và lao động nặng nhọc hơn.\r\nSự thống nhất của loài người: Phần này xem xét các lực lượng đã dần dần thống nhất các xã hội loài người rải rác thành các đế chế và cộng đồng toàn cầu, bao gồm tiền tệ, tôn giáo và đế chế.\r\nCách mạng Khoa học: Bắt đầu khoảng 500 năm trước và vẫn đang tiếp diễn, cuộc cách mạng này mang lại cho con người sức mạnh chưa từng có, nhưng cũng đặt ra những câu hỏi đạo đức và tương lai về thiết kế thông minh và sự thay thế Homo sapiens bằng \"siêu nhân\". ', 'img/Book/1764926106_sapiens-luoc-su-ve-loai-nguoi-outline-5-7-2017-02.webp', 'available', '2025-11-26 07:40:19', '2026-04-23 06:59:18', 0, 2),
(21, 'Kẻ lười biếng', 'Yao Kirrimasu', 'Tokyo halmbus', 2018, 2, 'Sách được quyên góp từ cộng đồng. Tình trạng: good', 'img/Book/1764830698_Ảnh chụp màn hình 2025-11-26 141048.png', 'available', '2025-11-27 07:45:12', '2026-04-23 06:59:18', 1, 3),
(22, 'Đất rừng phương Nam', 'Đoàn Giỏi', 'NXB Kim Đồng', 2020, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: Khá mới', NULL, 'available', '2026-05-20 12:04:35', '2026-05-20 12:04:35', 0, 0),
(23, 'Kẻ lười biếng', 'Yao Kirrimasu', 'Tokyo halmbus', 2018, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: Tốt', 'good1778076256_scaled_1000015051.jpg', 'available', '2026-05-20 12:04:36', '2026-05-20 12:04:36', 0, 0),
(24, 'Mắt Biếc', 'Nguyễn Nhật Ánh', 'Nhà Xuất Bản Trẻ', 0, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: good', '1779278998_scaled_1000015161.jpg', 'available', '2026-05-20 12:10:18', '2026-05-20 12:10:18', 0, 0),
(537, 'Dế Mèn Phiêu Lưu Ký', 'Tô Hoài', 'NXB Kim Đồng', 2020, 8, 'Tác phẩm văn học thiếu nhi kinh điển của nhà văn Tô Hoài, kể về cuộc phiêu lưu của chú Dế Mèn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(538, 'Số Đỏ', 'Vũ Trọng Phụng', 'NXB Văn Học', 2019, 7, 'Tiểu thuyết trào phúng sắc sảo, đả kích xã hội thượng lưu giả tạo thời Pháp thuộc.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(539, 'Vang Bóng Một Thời', 'Nguyễn Tuân', 'NXB Văn Học', 2021, 7, 'Tập truyện ngắn tinh tế về những vẻ đẹp văn hóa truyền thống đang dần mai một.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(540, 'Hà Nội Băm Sáu Phố Phường', 'Thạch Lam', 'NXB Trẻ', 2020, 7, 'Tập bút ký nhẹ nhàng, đầy tình cảm về vẻ đẹp và nét văn hóa đặc sắc của Hà Nội xưa.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(541, 'Sống Mòn', 'Nam Cao', 'NXB Văn Học', 2018, 7, 'Tiểu thuyết hiện thực tâm lý sâu sắc về cuộc sống bế tắc của những trí thức nghèo.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(542, 'Tắt Đèn', 'Ngô Tất Tố', 'NXB Văn Học', 2019, 7, 'Tác phẩm hiện thực phê phán mạnh mẽ chế độ sưu thuế bất công ở nông thôn Việt Nam.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(543, 'Bỉ Vỏ', 'Nguyên Hồng', 'NXB Văn Học', 2020, 7, 'Câu chuyện đầy nước mắt về cuộc đời của Tám Bính trong xã hội đen tối.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(544, 'Bước Đường Cùng', 'Nguyễn Công Hoan', 'NXB Văn Học', 2021, 7, 'Phác họa bi kịch của người nông dân bị đẩy vào đường cùng bởi sự áp bức.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(545, 'Hồn Bướm Mơ Tiên', 'Khái Hưng', 'NXB Văn Học', 2018, 7, 'Tiểu thuyết lãng mạn tiêu biểu của nhóm Tự Lực Văn Đoàn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(546, 'Nửa Chừng Xuân', 'Khái Hưng', 'NXB Văn Học', 2019, 7, 'Câu chuyện về tình yêu và lý tưởng của những người trẻ tuổi trong xã hội giao thời.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(547, 'Đoạn Tuyệt', 'Nhất Linh', 'NXB Văn Học', 2020, 7, 'Tác phẩm đấu tranh cho quyền tự do cá nhân và hạnh phúc của phụ nữ.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(548, 'Lạnh Lùng', 'Nhất Linh', 'NXB Văn Học', 2021, 7, 'Khám phá những góc khuất trong tâm lý và khát vọng của con người.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(549, 'Gánh Hàng Hoa', 'Khái Hưng & Nhất Linh', 'NXB Văn Học', 2018, 7, 'Sự kết hợp tài hoa của hai cây bút chủ lực nhóm Tự Lực Văn Đoàn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(550, 'Trống Mái', 'Khái Hưng', 'NXB Văn Học', 2019, 7, 'Câu chuyện về sự khác biệt tầng lớp và định kiến xã hội.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(551, 'Gia Đình', 'Khái Hưng', 'NXB Văn Học', 2020, 7, 'Bức tranh về những mâu thuẫn và giá trị truyền thống trong gia đình Việt.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(552, 'Chân Trời Cũ', 'Thanh Tịnh', 'NXB Văn Học', 2021, 7, 'Tập truyện ngắn mang âm hưởng nhẹ nhàng, hoài niệm về quê hương.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(553, 'Gió Đầu Mùa', 'Thạch Lam', 'NXB Văn Học', 2018, 7, 'Tập truyện ngắn tinh tế, giàu chất thơ và lòng trắc ẩn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(554, 'Nắng Trong Vườn', 'Thạch Lam', 'NXB Văn Học', 2019, 7, 'Những câu chuyện nhỏ về những con người bình dị với tâm hồn cao đẹp.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(555, 'Hai đứa trẻ', 'Thạch Lam', 'NXB Văn Học', 2020, 7, 'Truyện ngắn kinh điển về niềm hy vọng mong manh của những kiếp người nghèo khổ.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(556, 'Cô hàng xén', 'Thạch Lam', 'NXB Văn Học', 2021, 7, 'Ca ngợi vẻ đẹp chịu thương chịu khó của người phụ nữ Việt Nam.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(557, 'Chí Phèo', 'Nam Cao', 'NXB Văn Học', 2018, 7, 'Bi kịch tha hóa của một người nông dân lương thiện bị xã hội cự tuyệt.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(558, 'Lão Hạc', 'Nam Cao', 'NXB Văn Học', 2019, 7, 'Câu chuyện cảm động về lòng tự trọng và tình phụ tử thiêng liêng.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(559, 'Đời thừa', 'Nam Cao', 'NXB Văn Học', 2020, 7, 'Nỗi đau của người trí thức có khát vọng lớn nhưng bị cơm áo gạo tiền ghì sát đất.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(560, 'Một bữa no', 'Nam Cao', 'NXB Văn Học', 2021, 7, 'Phản ánh chân thực cái đói và sự khốn cùng của con người trước Cách mạng.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(561, 'Đôi mắt', 'Nam Cao', 'NXB Văn Học', 2018, 7, 'Truyện ngắn đặt ra vấn đề về cách nhìn nhận hiện thực của người nghệ sĩ.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(562, 'Vợ nhặt', 'Kim Lân', 'NXB Văn Học', 2019, 7, 'Vẻ đẹp của tình người và niềm khát khao sự sống trong nạn đói năm 1945.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(563, 'Chiếc lược ngà', 'Nguyễn Quang Sáng', 'NXB Văn Học', 2020, 7, 'Tình cha con sâu nặng, cảm động trong hoàn cảnh chiến tranh khốc liệt.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(564, 'Đất rừng phương Nam', 'Đoàn Giỏi', 'NXB Kim Đồng', 2021, 8, 'Cuộc phiêu lưu đầy thú vị và hào hùng của cậu bé An giữa thiên nhiên Nam Bộ.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(565, 'Hương rừng Cà Mau', 'Sơn Nam', 'NXB Trẻ', 2018, 7, 'Những câu chuyện mang đậm hơi thở đất và người vùng cực Nam Tổ quốc.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(566, 'Cho tôi xin một vé đi tuổi thơ', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2019, 8, 'Mảnh ghép ký ức trong sáng, đưa độc giả trở về với những ngày thơ ấu hồn nhiên.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(567, 'Mắt biếc', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2020, 1, 'Câu chuyện tình đơn phương buồn man mác qua nhiều thập kỷ.', 'img/Book/1778735731_scaled_1000015161.jpg', 'borrowed', '2026-05-13 15:11:49', '2026-05-18 13:15:08', 0, 2),
(568, 'Còn chút gì để nhớ', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2021, 1, 'Hành trình trưởng thành và những kỷ niệm khó quên của tuổi sinh viên.', 'img/Book/1778735738_scaled_1000015162.jpg', 'borrowed', '2026-05-13 15:11:49', '2026-05-18 15:16:29', 0, 3),
(569, 'Kính vạn hoa', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2018, 8, 'Bộ truyện học đường nổi tiếng với những tình huống hài hước và ý nghĩa.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(570, 'Bàn có năm chỗ ngồi', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2019, 8, 'Câu chuyện về tình bạn và tinh thần đoàn kết của nhóm học sinh.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(571, 'Cô gái đến từ hôm qua', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2020, 1, 'Sự giao thoa giữa quá khứ và hiện tại trong một mối tình học trò.', 'img/Book/1778735720_scaled_1000015163.jpg', 'available', '2026-05-13 15:11:49', '2026-05-18 12:59:05', 0, 1),
(572, 'Đi qua hoa cúc', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2021, 1, 'Những rung động đầu đời trong sáng và đầy nuối tiếc.', 'img/Book/default.png', 'borrowed', '2026-05-13 15:11:49', '2026-05-18 13:15:38', 0, 3),
(573, 'Trại hoa vàng', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2018, 1, 'Câu chuyện về những ước mơ và tình yêu tuổi mới lớn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-18 13:03:17', 0, 1),
(574, 'Bong bóng lên trời', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2019, 1, 'Nỗ lực vươn lên trong cuộc sống đầy khó khăn của những người trẻ.', 'img/Book/default.png', 'borrowed', '2026-05-13 15:11:49', '2026-05-18 15:16:24', 0, 1),
(575, 'Hạ đỏ', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2020, 1, 'Ký ức về một mùa hè rực rỡ và những tình cảm khó phai.', 'img/Book/default.png', 'borrowed', '2026-05-13 15:11:49', '2026-05-18 16:01:08', 0, 1),
(576, 'Những cô em gái', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2021, 1, 'Xoay quanh những mối quan hệ gia đình và tình bạn đầy thú vị.', 'img/Book/default.png', 'borrowed', '2026-05-13 15:11:49', '2026-05-18 16:16:14', 0, 1),
(577, 'Thằng quỷ nhỏ', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2018, 1, 'Câu chuyện về sự khác biệt và lòng nhân ái giữa con người.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(578, 'Bồ câu không đưa thư', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2019, 1, 'Những lá thư tình giấu kín và những trò đùa tinh nghịch của tuổi học trò.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(579, 'Nữ sinh', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2020, 1, 'Ghi lại những khoảnh khắc đẹp đẽ và rắc rối của thời áo trắng.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(580, 'Phượng hồng', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2021, 1, 'Biểu tượng của mùa hè và những lời chia tay đầy lưu luyến.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(581, 'Buổi chiều tắt nắng', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2018, 1, 'Một lát cắt nhẹ nhàng về cuộc sống và tình cảm con người.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(582, 'Những ngày thơ ấu', 'Nguyên Hồng', 'NXB Văn Học', 2019, 7, 'Hồi ký đầy xúc động về tuổi thơ gian khó nhưng giàu tình yêu thương.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(583, 'Cánh đồng bất tận', 'Nguyễn Ngọc Tư', 'NXB Trẻ', 2020, 1, 'Những mảnh đời lênh đênh trên sông nước miền Tây với bao nỗi niềm.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(584, 'Nỗi buồn chiến tranh', 'Bảo Ninh', 'NXB Trẻ', 2021, 1, 'Cái nhìn trực diện và đầy nhân văn về những mất mát sau cuộc chiến.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(585, 'Mảnh đất lắm người nhiều ma', 'Nguyễn Khắc Trường', 'NXB Văn Học', 2018, 1, 'Phản ánh những xung đột sâu sắc ở nông thôn Việt Nam thời đổi mới.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(586, 'Thời xa vắng', 'Lê Lựu', 'NXB Văn Học', 2019, 1, 'Câu chuyện về một thế hệ loay hoay tìm kiếm bản ngã giữa những định kiến.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(587, 'Mùa lá rụng trong vườn', 'Ma Văn Kháng', 'NXB Văn Học', 2020, 1, 'Những biến động trong một gia đình Hà Nội truyền thống trước thời đại mới.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(588, 'Đám cưới không có giấy giá thú', 'Ma Văn Kháng', 'NXB Văn Học', 2021, 1, 'Khám phá những khía cạnh đạo đức và xã hội phức tạp.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(589, 'Ngược dòng', 'Ma Văn Kháng', 'NXB Văn Học', 2018, 1, 'Sự kiên trì và bản lĩnh của con người trước nghịch cảnh.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(590, 'Gặp gỡ ở La Pan Tẩn', 'Ma Văn Kháng', 'NXB Văn Học', 2019, 1, 'Vẻ đẹp của vùng cao và những câu chuyện về tình người.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(591, 'Chó bi - đời', 'Ma Văn Kháng', 'NXB Văn Học', 2020, 1, 'Cái nhìn trào lộng về cuộc đời qua đôi mắt của một con vật.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(592, 'Miền hoang', 'Sương Nguyệt Minh', 'NXB Quân Đội', 2021, 1, 'Khắc họa sự khốc liệt của chiến tranh và bản năng sinh tồn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(593, 'Dị hương', 'Sương Nguyệt Minh', 'NXB Quân Đội', 2018, 1, 'Tập truyện ngắn giàu trí tưởng tượng và đầy ám ảnh.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(594, 'Đàn trời', 'Cao Duy Sơn', 'NXB Văn Học', 2019, 1, 'Sắc màu văn hóa dân tộc miền núi phía Bắc trong văn chương hiện đại.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(595, 'Ngôi nhà xưa bên suối', 'Cao Duy Sơn', 'NXB Văn Học', 2020, 1, 'Những câu chuyện nhẹ nhàng về quê hương và nguồn cội.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(596, 'Phượng hoàng', 'Cao Duy Sơn', 'NXB Văn Học', 2021, 1, 'Biểu tượng của sự tái sinh và những giá trị vĩnh cửu.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(597, 'Thổ địa', 'Nguyễn Xuân Khánh', 'NXB Phụ Nữ', 2018, 1, 'Hành trình tìm về văn hóa đất đai và tâm linh người Việt.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(598, 'Mẫu thượng ngàn', 'Nguyễn Xuân Khánh', 'NXB Phụ Nữ', 2019, 1, 'Tác phẩm đồ sộ về tín ngưỡng thờ Mẫu và đời sống nông thôn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(599, 'Đội gạo lên chùa', 'Nguyễn Xuân Khánh', 'NXB Phụ Nữ', 2020, 1, 'Khám phá sự giao thoa giữa Phật giáo và văn hóa Việt Nam.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(600, 'Hồ Quý Ly', 'Nguyễn Xuân Khánh', 'NXB Phụ Nữ', 2021, 1, 'Tiểu thuyết lịch sử sâu sắc về một nhân vật gây nhiều tranh cãi.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(601, 'Giàn thiêu', 'Võ Thị Hảo', 'NXB Phụ Nữ', 2018, 1, 'Tiểu thuyết mang màu sắc kỳ ảo về lịch sử và thân phận con người.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(602, 'Dạ tiệc quỷ', 'Võ Thị Hảo', 'NXB Phụ Nữ', 2019, 1, 'Những góc khuất và sự đối đầu giữa thiện và ác.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(603, 'Khải huyền muộn', 'Nguyễn Việt Hà', 'NXB Trẻ', 2020, 1, 'Lối viết hậu hiện đại độc đáo về cuộc sống đô thị đương đại.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(604, 'Cơ hội của Chúa', 'Nguyễn Việt Hà', 'NXB Trẻ', 2021, 1, 'Những suy tư về đức tin, tình yêu và sự lựa chọn trong đời.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(605, 'Ba ngôi báu', 'Nguyễn Việt Hà', 'NXB Trẻ', 2018, 1, 'Câu chuyện về những giá trị bị bỏ quên trong dòng chảy hối hả.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(606, 'Thoạt kỳ thủy', 'Nguyễn Bình Phương', 'NXB Văn Học', 2019, 1, 'Ngôn ngữ văn chương mới mẻ, đầy sức gợi và ám ảnh.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(607, 'Ngồi', 'Nguyễn Bình Phương', 'NXB Văn Học', 2020, 1, 'Sự chiêm nghiệm về thời gian và sự tĩnh lặng giữa cuộc đời.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(608, 'Trí nhớ suy tàn', 'Nguyễn Bình Phương', 'NXB Văn Học', 2021, 1, 'Khám phá thế giới nội tâm phức tạp và những mảng ký ức nhạt nhòa.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(609, 'Những đứa trẻ chết già', 'Nguyễn Bình Phương', 'NXB Văn Học', 2018, 1, 'Một tác phẩm mang tính triết lý về sự tồn tại và cái chết.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(610, 'Chinatown', 'Thuận', 'NXB Đà Nẵng', 2019, 1, 'Tiểu thuyết về căn tính và ký ức của người Việt ở nước ngoài.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(611, 'Paris 11 tháng 8', 'Thuận', 'NXB Đà Nẵng', 2020, 1, 'Những cuộc gặp gỡ và những mảnh đời tại kinh đô ánh sáng.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(612, 'T mất tích', 'Thuận', 'NXB Đà Nẵng', 2021, 1, 'Hành trình tìm kiếm sự thật giữa những lớp màn bí ẩn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(613, 'Marie Sến', 'Phạm Thị Hoài', 'NXB Văn Học', 2018, 1, 'Lối viết sắc sảo, cá tính về những vấn đề đương đại.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(614, 'Thiên sứ', 'Phạm Thị Hoài', 'NXB Văn Học', 2019, 1, 'Tác phẩm từng gây tiếng vang lớn với cách đặt vấn đề táo bạo.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(615, 'Mê lộ', 'Phạm Thị Hoài', 'NXB Văn Học', 2020, 1, 'Hành trình khám phá những giới hạn của tự do và sáng tạo.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(616, 'Khi người ta trẻ', 'Phan Thị Vàng Anh', 'NXB Trẻ', 2021, 1, 'Những cảm xúc tinh khôi và những trăn trở của tuổi thanh xuân.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(617, 'Bến quê', 'Nguyễn Minh Châu', 'NXB Văn Học', 2018, 7, 'Sự thức tỉnh muộn màng về những vẻ đẹp bình dị quanh ta.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(618, 'Chiếc thuyền ngoài xa', 'Nguyễn Minh Châu', 'NXB Văn Học', 2019, 7, 'Bài học về cách nhìn nhận cuộc đời đa diện và sâu sắc hơn.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(619, 'Tuổi thơ dữ dội', 'Phùng Quán', 'NXB Văn Học', 2020, 1, 'Hùng ca về những thiếu niên anh hùng trong kháng chiến chống Pháp.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(620, 'Tuổi thơ im lặng', 'Duy Khán', 'NXB Văn Học', 2021, 1, 'Những kỷ niệm êm đềm và đầy hoài niệm về một thời đã xa.', 'img/Book/default.png', 'available', '2026-05-13 15:11:49', '2026-05-13 15:11:49', 0, 0),
(621, 'Ăn mày dĩ vãng', 'Chu Lai', 'NXB Quân Đội', 2018, 1, 'Cuộc đi tìm lại quá khứ và đồng đội của một người lính.', 'img/Book/1778735588_scaled_1000015160.jpg', 'available', '2026-05-13 15:11:49', '2026-05-14 05:13:08', 0, 0),
(622, 'Một thoáng ta rực rỡ ở nhân gian', 'Ocean Vuong', 'NXB Hội Nhà Văn', 2019, 1, 'Thư gửi mẹ về gia đình, tình yêu và những nỗi đau không lời.', 'img/Book/1778735581_scaled_1000015159.jpg', 'available', '2026-05-13 15:11:49', '2026-05-14 05:13:01', 0, 0),
(623, 'Việt Nam sử lược', 'Trần Trọng Kim', 'NXB Tân Việt', 2020, 14, 'Cuốn thông sử đầu tiên bằng chữ Quốc ngữ, hệ thống lại lịch sử Việt Nam.', 'img/Book/1778735574_scaled_1000015158.jpg', 'available', '2026-05-13 15:11:49', '2026-05-14 05:12:54', 0, 0),
(624, 'Việt Nam phong tục', 'Phan Kế Bính', 'NXB Văn Học', 2021, 15, 'Khám phá và giải thích các phong tục tập quán lâu đời của dân tộc.', 'img/Book/1778735563_scaled_1000015156.jpg', 'available', '2026-05-13 15:11:49', '2026-05-14 05:12:43', 0, 0),
(625, 'Đắc Nhân Tâm', 'Dale Carnegie (Dịch giả VN)', 'NXB Tổng Hợp', 2018, 2, 'Nghệ thuật thu phục lòng người và xây dựng mối quan hệ tốt đẹp.', 'img/Book/1778735558_scaled_1000015155.webp', 'available', '2026-05-13 15:11:49', '2026-05-14 05:12:38', 0, 0),
(626, 'Tuổi Trẻ Đáng Giá Bao Nhiêu', 'Rosie Nguyễn', 'NXB Nhã Nam', 2019, 2, 'Lời nhắn nhủ chân thành giúp người trẻ tìm thấy hướng đi cho mình.', 'img/Book/1778735551_scaled_1000015154.jpg', 'available', '2026-05-13 15:11:49', '2026-05-14 05:12:31', 0, 0),
(627, 'Tư Duy Nhanh Và Chậm', 'Daniel Kahneman (Dịch giả VN)', 'NXB Thế Giới', 2020, 4, 'Khám phá hai hệ thống tư duy điều khiển hành động của con người.', 'img/Book/1778690365_scaled_1000015153.webp', 'available', '2026-05-13 15:11:49', '2026-05-13 16:39:25', 0, 0),
(628, 'Dám Bị Ghét', 'Kishimi Ichiro & Koga Fumitake (Dịch giả VN)', 'NXB Nhã Nam', 2021, 4, 'Triết lý Alfred Adler giúp bạn tìm thấy tự do và hạnh phúc đích thực.', 'img/Book/1778690359_scaled_1000015152.webp', 'available', '2026-05-13 15:11:49', '2026-05-13 16:39:19', 0, 0),
(629, 'Người Giàu Có Nhất Thành Babylon', 'George S. Clason (Dịch giả VN)', 'NXB Trẻ', 2018, 3, 'Những nguyên lý tài chính cơ bản và hiệu quả qua các thời đại.', 'img/Book/1778690353_scaled_1000015151.jpg', 'available', '2026-05-13 15:11:49', '2026-05-13 16:39:13', 0, 0),
(630, 'Trên Đường Băng', 'Tony Buổi Sáng', 'NXB Trẻ', 2019, 2, 'Truyền cảm hứng và kỹ năng sống cho thế hệ trẻ Việt Nam.', 'img/Book/1778690344_scaled_1000015150.jpg', 'available', '2026-05-13 15:11:49', '2026-05-13 16:39:04', 0, 0),
(631, 'Cha Giàu Cha Nghèo', 'Robert Kiyosaki (Dịch giả VN)', 'NXB Trẻ', 2020, 3, 'Thay đổi tư duy về tiền bạc và đầu tư để đạt tới tự do tài chính.', 'img/Book/1778690247_scaled_1000015149.jpg', 'available', '2026-05-13 15:11:49', '2026-05-13 16:37:27', 0, 0),
(632, 'Cấu trúc dữ liệu và giải thuật', 'Trần Hạnh (Generic)', 'NXB Giáo Dục', 2021, 13, 'Kiến thức nền tảng quan trọng cho mọi lập trình viên.', 'img/Book/1778690214_scaled_1000015148.jpg', 'available', '2026-05-13 15:11:49', '2026-05-13 16:36:54', 0, 0),
(633, 'Tấm Cám', 'Dân gian Việt Nam', 'NXB Kim Đồng', 2018, 12, 'Truyện cổ tích nổi tiếng về sự đấu tranh giữa cái thiện và cái ác.', 'img/Book/1778690160_scaled_1000015147.jpg', 'available', '2026-05-13 15:11:49', '2026-05-13 16:36:00', 0, 0),
(634, 'Thạch Sanh', 'Dân gian Việt Nam', 'NXB Kim Đồng', 2019, 12, 'Hình tượng người anh hùng dũng cảm, nhân hậu trong văn hóa dân gian.', 'img/Book/1778690154_scaled_1000015146.jpg', 'available', '2026-05-13 15:11:49', '2026-05-13 16:35:54', 0, 0),
(635, 'Sơn Tinh Thủy Tinh', 'Dân gian Việt Nam', 'NXB Kim Đồng', 2020, 12, 'Giải thích hiện tượng thiên nhiên qua cuộc chiến thần thoại.', 'img/Book/1778689945_scaled_1000015145.jpg', 'available', '2026-05-13 15:11:49', '2026-05-13 16:32:25', 0, 0),
(636, 'Trại Hoa Đỏ', 'Di Li', 'NXB Phụ Nữ', 2021, 11, 'Tiểu thuyết trinh thám kinh dị đầy kịch tính và bất ngờ.', 'img/Book/1778689911_scaled_1000015144.webp', 'available', '2026-05-13 15:11:49', '2026-05-13 16:31:51', 0, 0),
(637, 'Nhà Giả Kim', 'Paulo Coelho', 'Lê Chu Cầu', 0, NULL, 'Sách được quyên góp từ cộng đồng. Tình trạng: good', NULL, 'available', '2026-05-18 12:34:54', '2026-05-18 12:34:54', 0, 0),
(638, 'Nhà Giả Kim', 'Paulo Coelho', 'Lê Chu Cầu', 0, NULL, 'Sách được quyên góp từ cộng đồng. Tình trạng: like_new', NULL, 'available', '2026-05-18 12:39:47', '2026-05-18 12:39:47', 0, 0),
(639, 'Nhà Giả Kim', 'Paulo Coelho', 'Lê Chu Cầu', 0, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: like_new', '1779107976_scaled_33.jpg', 'available', '2026-05-18 16:15:04', '2026-05-18 16:15:04', 0, 0),
(640, 'Nhà Giả Kim', 'Paulo Coelho', 'Lê Chu Cầu', 0, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: good', '1779106956_scaled_33.jpg', 'available', '2026-05-18 16:15:32', '2026-05-18 16:15:32', 0, 0),
(641, 'Nhà Giả Kim', 'Paulo Coelho', '', 0, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: new', '1778460182_scaled_c22668e3-0b80-4c6d-944f-92be4acdabd62553153985115238504.jpg', 'available', '2026-05-18 16:15:34', '2026-05-18 16:15:34', 0, 0),
(642, 'Nhà Giả Kim', 'Paulo Coelho', 'Nhà xuất bản VH', 2018, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: good', '1778076256_scaled_1000015051.jpg', 'available', '2026-05-18 16:15:36', '2026-05-18 16:15:36', 0, 0),
(643, 'kinh tế chính trị', 'Lenin', 'NXB Giáo Dục Việt Nam', 2007, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: new', NULL, 'available', '2026-05-18 16:15:38', '2026-05-18 16:15:38', 0, 0),
(644, 'software engineering', 'google', 'amazon', 2020, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: like_new', NULL, 'available', '2026-05-18 16:15:39', '2026-05-18 16:15:39', 0, 0),
(645, 'Ca dao tục ngữ Việt Nam', 'Dân Gian', 'Kim Đồng', 2008, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: good', NULL, 'available', '2026-05-18 16:15:41', '2026-05-18 16:15:41', 0, 0),
(646, 'Toán học cao ', 'GS. Nguyễn Đình Trí', 'NXB Giáo Dục', 2006, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: fair', NULL, 'available', '2026-05-18 16:15:42', '2026-05-18 16:15:42', 0, 0),
(647, 'Hai đứa trẻ', 'Thạch Lam', 'Kim Đồng', 1987, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: new', NULL, 'available', '2026-05-18 16:15:43', '2026-05-18 16:15:43', 0, 0),
(648, 'Toán 9', 'Bộ giáo dục và đào tạo', 'NXB Giáo Dục Việt Nam', 1978, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: likeNew', NULL, 'available', '2026-05-18 16:15:44', '2026-05-18 16:15:44', 0, 0),
(649, 'Kẻ lười biếng', 'Yao Kirrimasu', 'Tokyo halmbus', 2018, NULL, 'Sách quyên góp từ bạn đọc. Tình trạng: good', NULL, 'available', '2026-05-18 16:15:45', '2026-05-18 16:15:45', 0, 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `borrowings`
--

CREATE TABLE `borrowings` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `delivery_type` enum('pickup','delivery') NOT NULL DEFAULT 'pickup',
  `delivery_address` text DEFAULT NULL,
  `delivery_distance_km` decimal(8,2) DEFAULT NULL,
  `shipping_fee` int(11) NOT NULL DEFAULT 0,
  `payment_method` enum('cod','vietqr') DEFAULT NULL,
  `payment_status` enum('pending','paid','not_required') NOT NULL DEFAULT 'not_required',
  `payment_ref` varchar(100) DEFAULT NULL,
  `payment_confirmed_at` datetime DEFAULT NULL,
  `borrow_date` date NOT NULL,
  `due_date` date NOT NULL,
  `return_date` date DEFAULT NULL,
  `status` enum('pending_approval','approved','preparing','shipped','borrowed','return_requested','return_shipping','returned','overdue','cancelled') NOT NULL DEFAULT 'pending_approval',
  `approved_at` datetime DEFAULT NULL,
  `shipped_at` datetime DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `renew_status` enum('none','pending','approved','rejected') NOT NULL DEFAULT 'none',
  `renew_days` int(11) NOT NULL DEFAULT 0,
  `renew_count` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `borrowings`
--

INSERT INTO `borrowings` (`id`, `user_id`, `book_id`, `delivery_type`, `delivery_address`, `delivery_distance_km`, `shipping_fee`, `payment_method`, `payment_status`, `payment_ref`, `payment_confirmed_at`, `borrow_date`, `due_date`, `return_date`, `status`, `approved_at`, `shipped_at`, `cancelled_at`, `renew_status`, `renew_days`, `renew_count`) VALUES
(1, 3, 20, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2025-11-26', '2025-12-03', '2025-12-06', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(3, 3, 21, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2025-12-06', '2025-12-20', '2025-12-06', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(4, 3, 11, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2025-12-08', '2025-12-22', '2025-12-12', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(5, 3, 21, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2025-12-09', '2025-12-23', '2025-12-09', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(6, 3, 21, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2025-12-10', '2025-12-11', '2025-12-12', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(8, 3, 20, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2025-12-14', '2025-12-28', '2025-12-15', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(9, 5, 13, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2025-12-14', '2025-12-28', '2025-12-14', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(17, 9, 13, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-03-31', '2026-04-14', '2026-04-21', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(23, 9, 12, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-04-21', '2026-05-05', '2026-05-07', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(26, 9, 1, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-06', '2026-05-20', '2026-05-06', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(28, 10, 2, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-07', '2026-05-21', '2026-05-07', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(29, 9, 2, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-07', '2026-05-21', '2026-05-11', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(31, 9, 3, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-11', '2026-05-26', '2026-05-18', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(32, 9, 14, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-11', '2026-05-26', NULL, 'borrowed', NULL, NULL, NULL, 'rejected', 1, 0),
(36, 9, 567, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-14', '2026-05-21', '2026-05-18', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(37, 9, 568, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-14', '2026-05-28', '2026-05-18', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(38, 10, 1, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-18', '2026-06-08', NULL, 'returned', NULL, NULL, NULL, 'none', 0, 0),
(39, 9, 571, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-18', '2026-06-08', '2026-05-18', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(40, 10, 572, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-18', '2026-06-08', '2026-05-18', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(41, 9, 572, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-18', '2026-06-01', '2026-05-18', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(42, 9, 573, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-18', '2026-06-02', '2026-05-18', 'returned', NULL, NULL, NULL, 'none', 0, 0),
(43, 10, 567, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-18', '2026-06-01', NULL, 'borrowed', NULL, NULL, NULL, 'none', 0, 0),
(44, 10, 572, 'pickup', NULL, NULL, 0, NULL, 'not_required', NULL, NULL, '2026-05-18', '2026-06-01', NULL, 'borrowed', NULL, NULL, NULL, 'none', 0, 0),
(45, 10, 568, 'pickup', NULL, NULL, 0, NULL, '', NULL, NULL, '2026-05-18', '2026-06-01', NULL, 'borrowed', NULL, NULL, NULL, 'none', 0, 0),
(46, 9, 574, 'pickup', NULL, NULL, 0, NULL, 'pending', NULL, NULL, '2026-05-18', '2026-06-01', NULL, 'borrowed', NULL, NULL, NULL, 'none', 0, 0),
(47, 10, 568, 'delivery', NULL, NULL, 0, '', '', NULL, NULL, '2026-05-18', '2026-06-01', NULL, 'borrowed', NULL, NULL, NULL, 'none', 0, 0),
(48, 9, 575, 'delivery', NULL, 0, 0, '', '', NULL, NULL, '2026-05-18', '2026-06-01', NULL, 'borrowed', NULL, NULL, NULL, 'none', 0, 0),
(49, 9, 576, 'delivery', NULL, 0, 0, '', '', NULL, NULL, '2026-05-18', '2026-06-01', NULL, 'borrowed', NULL, NULL, NULL, 'none', 0, 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `categories`
--

INSERT INTO `categories` (`id`, `name`) VALUES
(1, 'Tiểu thuyết'),
(2, 'Kỹ năng sống'),
(3, 'Kinh tế'),
(4, 'Tâm lý học'),
(5, 'Khoa học'),
(6, 'Sách giáo khoa'),
(7, 'Văn học kinh điển'),
(8, 'Truyện thiếu nhi'),
(9, 'Kinh dị'),
(11, 'Trinh thám'),
(12, 'Cổ tích'),
(13, 'Khoa học máy tính'),
(14, 'Lịch sử'),
(15, 'Văn hóa'),
(16, 'Hồi ký');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `donations`
--

CREATE TABLE `donations` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `donation_type` varchar(50) NOT NULL,
  `pickup_type` enum('self_deliver','user_ship') NOT NULL DEFAULT 'self_deliver',
  `status` enum('pending','approved','in_transit','received','processed','rejected') NOT NULL DEFAULT 'pending',
  `book_title` varchar(255) NOT NULL,
  `book_author` varchar(255) NOT NULL,
  `book_publisher` varchar(255) DEFAULT NULL,
  `book_year` int(11) DEFAULT NULL,
  `book_condition` varchar(100) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `pickup_address` text DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `donations`
--

INSERT INTO `donations` (`id`, `user_id`, `donation_type`, `pickup_type`, `status`, `book_title`, `book_author`, `book_publisher`, `book_year`, `book_condition`, `image_url`, `created_at`, `pickup_address`, `approved_at`, `received_at`, `processed_at`) VALUES
(1, 3, 'directDelivery', 'self_deliver', 'processed', 'Kẻ lười biếng', 'Yao Kirrimasu', 'Tokyo halmbus', 2018, 'Tốt', 'good1778076256_scaled_1000015051.jpg', '2026-03-07 03:15:19', NULL, '2026-05-20 19:02:39', '2026-05-20 19:03:00', '2026-05-20 19:04:36'),
(2, 3, 'shipToLibrary', 'user_ship', 'processed', 'Đất rừng phương Nam', 'Đoàn Giỏi', 'NXB Kim Đồng', 2020, 'Khá mới', NULL, '2026-04-10 07:20:00', '123 Đường Láng, Đống Đa, Hà Nội', NULL, '2026-05-20 19:02:58', '2026-05-20 19:04:35'),
(3, 9, 'directDelivery', 'self_deliver', 'processed', 'Lão Hạc', 'Nam Cao', 'NXB Văn Học', 2015, 'Hơi cũ', NULL, '2026-05-01 02:30:00', NULL, NULL, NULL, '2026-05-20 19:04:32'),
(4, 10, 'shipToLibrary', 'user_ship', 'processed', 'Số Đỏ', 'Vũ Trọng Phụng', 'NXB Trẻ', 2019, 'Tốt', NULL, '2026-05-05 09:45:00', '456 Cầu Giấy, Hà Nội', NULL, NULL, NULL),
(5, 11, 'directDelivery', 'self_deliver', 'rejected', 'Chiến tranh và Hòa bình', 'Leo Tolstoy', 'NXB Văn Học', 2010, 'Rách bìa', NULL, '2026-05-10 04:15:00', NULL, NULL, NULL, NULL),
(6, 9, 'delivery', 'self_deliver', 'processed', 'Mắt Biếc', 'Nguyễn Nhật Ánh', 'Nhà Xuất Bản Trẻ', 0, 'good', '1779278998_scaled_1000015161.jpg', '2026-05-20 12:09:58', NULL, '2026-05-20 19:10:08', '2026-05-20 19:10:16', '2026-05-20 19:10:18');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `library_config`
--

CREATE TABLE `library_config` (
  `config_key` varchar(100) NOT NULL,
  `config_value` text NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `library_config`
--

INSERT INTO `library_config` (`config_key`, `config_value`, `updated_at`) VALUES
('bank_account', '41608977', '2026-05-18 14:14:52'),
('bank_name', 'ACB', '2026-05-18 14:14:52'),
('bank_owner', 'NGUYEN THANH CHIEN', '2026-05-18 14:14:52'),
('borrow_timeout_cod_hours', '48', '2026-05-18 13:55:26'),
('borrow_timeout_vietqr_hours', '24', '2026-05-18 13:55:26'),
('cod_timeout_hours', '48', '2026-05-18 14:14:52'),
('library_address', '470 Tr?n ??i Nghia, Phu?ng H?a Qu?, Qu?n Ngu H?nh Son, TP ?? N?ng', '2026-05-18 15:11:51'),
('library_lat', '15.9752931', '2026-05-18 15:40:31'),
('library_lng', '108.252355', '2026-05-18 15:40:31'),
('library_name', 'Thư Viện B4E', '2026-05-18 14:14:52'),
('max_delivery_km', '30', '2026-05-18 14:14:52'),
('vietqr_timeout_hours', '24', '2026-05-18 14:14:52');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(50) NOT NULL DEFAULT 'system',
  `ref_id` int(11) DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `ref_id`, `is_read`, `created_at`) VALUES
(1, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Mắt Biếc\" thành công. Hạn trả: 05/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 21, 1, '2026-04-21 15:23:27'),
(2, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Mắt Biếc\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 21, 1, '2026-04-21 15:23:44'),
(3, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Nắng trong vườn\" thành công. Hạn trả: 05/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 22, 1, '2026-04-21 15:24:02'),
(4, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Gen Vị Kỷ\" thành công. Hạn trả: 05/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 23, 1, '2026-04-21 15:33:04'),
(5, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Nắng trong vườn\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 22, 1, '2026-04-22 06:55:23'),
(6, 11, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Toán học cao \" thành công. Hạn trả: 06/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 24, 0, '2026-04-22 07:19:56'),
(7, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Hai đứa trẻ\" thành công. Hạn trả: 07/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 25, 1, '2026-04-23 06:41:49'),
(8, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Hai đứa trẻ\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 25, 1, '2026-05-06 13:17:32'),
(9, 11, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Toán học cao \". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 24, 0, '2026-05-06 13:17:34'),
(10, 9, 'Quyên góp không được chấp nhận', 'Rất tiếc, yêu cầu quyên góp cuốn \"Nhà Giả Kim\" chưa phù hợp với tiêu chí của thư viện lúc này. Cảm ơn bạn đã quan tâm!', 'donation_rejected', 11, 1, '2026-05-06 13:53:52'),
(11, 9, 'Quyên góp được chấp nhận ❤️', 'Cảm ơn bạn! Thư viện B4E đã tiếp nhận thành công cuốn \"Nhà Giả Kim\". Sách của bạn đã được thêm vào kho và phục vụ cộng đồng!', 'donation_approved', 12, 1, '2026-05-06 14:04:27'),
(12, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Nhà Giả Kim\" thành công. Hạn trả: 20/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 26, 1, '2026-05-06 14:34:40'),
(13, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Nhà Giả Kim\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 26, 1, '2026-05-06 14:35:55'),
(14, 10, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Hai đứa trẻ\" thành công. Hạn trả: 21/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 27, 1, '2026-05-07 06:32:09'),
(15, 10, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Hai đứa trẻ\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 27, 1, '2026-05-07 07:27:51'),
(16, 10, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Hai Số Phận\" thành công. Hạn trả: 21/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 28, 1, '2026-05-07 07:28:16'),
(17, 10, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Hai Số Phận\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 28, 1, '2026-05-07 07:29:01'),
(18, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Hai Số Phận\" thành công. Hạn trả: 21/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 29, 1, '2026-05-07 14:20:47'),
(19, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Gen Vị Kỷ\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 23, 1, '2026-05-07 14:25:39'),
(20, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"con cò\" thành công. Hạn trả: 25/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 30, 1, '2026-05-11 00:40:11'),
(21, 9, 'Quyên góp được chấp nhận ❤️', 'Cảm ơn bạn! Thư viện B4E đã tiếp nhận thành công cuốn \"Nhà Giả Kim\". Sách của bạn đã được thêm vào kho và phục vụ cộng đồng!', 'donation_approved', 13, 1, '2026-05-11 12:25:43'),
(22, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Người Đua Diều\" thành công. Hạn trả: 25/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 31, 1, '2026-05-11 16:44:38'),
(23, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Hai Số Phận\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 29, 1, '2026-05-11 16:49:12'),
(24, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Harry Potter và Hòn đá Phù thủy\" thành công. Hạn trả: 25/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 32, 1, '2026-05-11 16:53:08'),
(25, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Nhà Giả Kim\" thành công. Hạn trả: 25/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 33, 1, '2026-05-11 17:27:59'),
(26, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Hai đứa trẻ\" thành công. Hạn trả: 12/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 34, 1, '2026-05-11 17:30:21'),
(27, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"10 Viễn Cảnh Cho Tương Lai AI 2041\" thành công. Hạn trả: 21/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 35, 1, '2026-05-13 13:20:51'),
(28, 9, 'Quyên góp không được chấp nhận', 'Rất tiếc, yêu cầu quyên góp cuốn \"Nhà Giả Kim\" chưa phù hợp với tiêu chí của thư viện lúc này. Cảm ơn bạn đã quan tâm!', 'donation_rejected', 14, 1, '2026-05-13 13:23:36'),
(29, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Mắt biếc\" thành công. Hạn trả: 21/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 36, 1, '2026-05-14 06:41:12'),
(30, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Còn chút gì để nhớ\" thành công. Hạn trả: 28/05/2026. Chúc bạn đọc vui!', 'borrow_approved', 37, 1, '2026-05-14 06:43:03'),
(31, 10, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Nhà Giả Kim\" thành công. Hạn trả: 01/06/2026. Chúc bạn đọc vui!', 'borrow_approved', 38, 1, '2026-05-18 12:34:26'),
(32, 10, 'Quyên góp được chấp nhận ❤️', 'Cảm ơn bạn! Thư viện B4E đã tiếp nhận thành công cuốn \"Nhà Giả Kim\". Sách của bạn đã được thêm vào kho và phục vụ cộng đồng!', 'donation_approved', 15, 1, '2026-05-18 12:34:54'),
(33, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Cô gái đến từ hôm qua\" thành công. Hạn trả: 01/06/2026. Chúc bạn đọc vui!', 'borrow_approved', 39, 1, '2026-05-18 12:36:23'),
(34, 10, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Đi qua hoa cúc\" thành công. Hạn trả: 01/06/2026. Chúc bạn đọc vui!', 'borrow_approved', 40, 1, '2026-05-18 12:37:03'),
(35, 10, 'Quyên góp được chấp nhận ❤️', 'Cảm ơn bạn! Thư viện B4E đã tiếp nhận thành công cuốn \"Nhà Giả Kim\". Sách của bạn đã được thêm vào kho và phục vụ cộng đồng!', 'donation_approved', 16, 1, '2026-05-18 12:39:47'),
(36, 10, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Đi qua hoa cúc\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 40, 1, '2026-05-18 12:40:22'),
(37, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Đi qua hoa cúc\" thành công. Hạn trả: 01/06/2026. Chúc bạn đọc vui!', 'borrow_approved', 41, 1, '2026-05-18 12:55:59'),
(38, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Đi qua hoa cúc\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 41, 1, '2026-05-18 12:57:30'),
(39, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Cô gái đến từ hôm qua\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 39, 0, '2026-05-18 12:59:05'),
(40, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Người Đua Diều\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 31, 0, '2026-05-18 12:59:52'),
(41, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Còn chút gì để nhớ\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 37, 0, '2026-05-18 13:00:44'),
(42, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Mắt biếc\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 36, 0, '2026-05-18 13:01:10'),
(43, 9, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Trại hoa vàng\" thành công. Hạn trả: 01/06/2026. Chúc bạn đọc vui!', 'borrow_approved', 42, 0, '2026-05-18 13:01:38'),
(44, 9, 'Trả sách thành công 📚', 'Thư viện đã xác nhận nhận lại cuốn \"Trại hoa vàng\". Cảm ơn bạn đã trả sách đúng hạn!', 'system', 42, 0, '2026-05-18 13:03:17'),
(45, 10, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Mắt biếc\" thành công. Hạn trả: 01/06/2026. Chúc bạn đọc vui!', 'borrow_approved', 43, 1, '2026-05-18 13:15:08'),
(46, 10, 'Mượn sách thành công ✅', 'Bạn đã mượn cuốn \"Đi qua hoa cúc\" thành công. Hạn trả: 01/06/2026. Chúc bạn đọc vui!', 'borrow_approved', 44, 1, '2026-05-18 13:15:38'),
(47, 10, 'Yêu cầu mượn sách đã gửi ⏳', 'Yêu cầu mượn cuốn \"Còn chút gì để nhớ\" (Nhận trực tiếp tại thư viện) đang chờ Admin duyệt.', 'borrow_approved', 45, 0, '2026-05-18 14:52:53'),
(48, 9, 'Yêu cầu mượn sách đã gửi ⏳', 'Yêu cầu mượn cuốn \"Bong bóng lên trời\" (Nhận trực tiếp tại thư viện) đang chờ Admin duyệt.', 'borrow_approved', 46, 0, '2026-05-18 14:59:44'),
(49, 10, 'Yêu cầu mượn sách đã gửi ⏳', 'Yêu cầu mượn cuốn \"Còn chút gì để nhớ\" (Ship tận nơi - phí: 40.000đ) đang chờ Admin duyệt.', 'borrow_approved', 47, 0, '2026-05-18 15:14:42'),
(50, 10, 'Thanh toán xác nhận thành công 💳', 'Thư viện đã nhận được phí ship cho cuốn \"Còn chút gì để nhớ\". Sách của bạn đang được chuẩn bị!', 'borrow_approved', 47, 0, '2026-05-18 15:16:18'),
(51, 9, 'Yêu cầu mượn sách được duyệt ✅', 'Yêu cầu mượn \"Bong bóng lên trời\" đã được duyệt. Hạn trả: 2026-06-01. Vui lòng đến thư viện nhận sách.', 'borrow_approved', 46, 0, '2026-05-18 15:16:24'),
(52, 10, 'Yêu cầu mượn sách được duyệt ✅', 'Yêu cầu mượn \"Còn chút gì để nhớ\" đã được duyệt. Hạn trả: 2026-06-01. Vui lòng đến thư viện nhận sách.', 'borrow_approved', 45, 0, '2026-05-18 15:16:29'),
(53, 10, 'Sách đang trên đường đến bạn 🚚', 'Cuốn \"Còn chút gì để nhớ\" đã được giao cho đơn vị vận chuyển. Hạn trả sau khi nhận sách: 2026-06-01.', 'borrow_approved', 47, 0, '2026-05-18 15:16:35'),
(54, 10, 'Xác nhận đã nhận sách 📚', 'Bạn đã nhận cuốn \"Còn chút gì để nhớ\". Hạn trả: 2026-06-01. Chúc bạn đọc vui!', 'borrow_approved', 47, 0, '2026-05-18 15:17:17'),
(55, 9, 'Xác nhận đã nhận sách 📚', 'Bạn đã nhận cuốn \"Bong bóng lên trời\". Hạn trả: 2026-06-01. Chúc bạn đọc vui!', 'borrow_approved', 46, 0, '2026-05-18 15:22:21'),
(56, 9, 'Yêu cầu mượn sách đã gửi ⏳', 'Yêu cầu mượn cuốn \"Hạ đỏ\" (Ship tận nơi - phí: 15.000đ) đang chờ Admin duyệt.', 'borrow_approved', 48, 0, '2026-05-18 15:48:11'),
(57, 10, 'Xác nhận đã nhận sách 📚', 'Bạn đã nhận cuốn \"Còn chút gì để nhớ\". Hạn trả: 2026-06-01. Chúc bạn đọc vui!', 'borrow_approved', 45, 0, '2026-05-18 15:48:46'),
(58, 10, 'Xác nhận đã nhận sách 📚', 'Bạn đã nhận cuốn \"Còn chút gì để nhớ\". Hạn trả: 2026-06-01. Chúc bạn đọc vui!', 'borrow_approved', 45, 0, '2026-05-18 15:48:50'),
(59, 9, 'Yêu cầu mượn sách được duyệt ✅', 'Yêu cầu mượn \"Hạ đỏ\" đã được duyệt. Sách sẽ được giao đến bạn. Phí ship (15.000đ) thanh toán khi nhận.', 'borrow_approved', 48, 0, '2026-05-18 15:49:08'),
(60, 9, 'Sách đang được chuẩn bị 📦', 'Thư viện đang chuẩn bị cuốn \"Hạ đỏ\" để giao đến bạn. Chúng tôi sẽ thông báo khi sách được gửi đi.', 'borrow_approved', 48, 0, '2026-05-18 16:01:08'),
(61, 9, 'Sách đang trên đường đến bạn 🚚', 'Cuốn \"Hạ đỏ\" đã được giao cho đơn vị vận chuyển. Hạn trả sau khi nhận sách: 2026-06-01.', 'borrow_approved', 48, 0, '2026-05-18 16:01:40'),
(62, 9, 'Xác nhận đã nhận sách 📚', 'Bạn đã nhận cuốn \"Hạ đỏ\". Hạn trả: 2026-06-01. Chúc bạn đọc vui!', 'borrow_approved', 48, 0, '2026-05-18 16:01:46'),
(63, 9, 'Yêu cầu mượn sách đã gửi ⏳', 'Yêu cầu mượn cuốn \"Những cô em gái\" (Ship tận nơi - phí: 15.000đ) đang chờ Admin duyệt.', 'borrow_approved', 49, 0, '2026-05-18 16:14:05'),
(64, 10, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Nhà Giả Kim\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 16, 0, '2026-05-18 16:14:56'),
(65, 10, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Nhà Giả Kim\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 16, 0, '2026-05-18 16:15:04'),
(66, 10, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Nhà Giả Kim\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 15, 0, '2026-05-18 16:15:14'),
(67, 9, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Nhà Giả Kim\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 13, 0, '2026-05-18 16:15:16'),
(68, 9, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Nhà Giả Kim\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 12, 0, '2026-05-18 16:15:20'),
(69, 9, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"kinh tế chính trị\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 10, 0, '2026-05-18 16:15:22'),
(70, 9, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"software engineering\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 9, 0, '2026-05-18 16:15:24'),
(71, 3, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Ca dao tục ngữ Việt Nam\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 8, 0, '2026-05-18 16:15:25'),
(72, 3, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Toán học cao \" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 7, 0, '2026-05-18 16:15:27'),
(73, 3, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Hai đứa trẻ\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 6, 0, '2026-05-18 16:15:28'),
(74, 3, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Toán 9\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 3, 0, '2026-05-18 16:15:29'),
(75, 3, 'Thư viện đã nhận được sách 📦', 'Thư viện đã nhận cuốn \"Kẻ lười biếng\" thành công. Sách đang được kiểm tra và xử lý.', 'donation_approved', 1, 0, '2026-05-18 16:15:29'),
(76, 10, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Nhà Giả Kim\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 15, 0, '2026-05-18 16:15:32'),
(77, 9, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Nhà Giả Kim\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 13, 0, '2026-05-18 16:15:34'),
(78, 9, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Nhà Giả Kim\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 12, 0, '2026-05-18 16:15:36'),
(79, 9, 'Quyên góp hoàn tất 🎉', 'Cuốn \"kinh tế chính trị\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 10, 0, '2026-05-18 16:15:38'),
(80, 9, 'Quyên góp hoàn tất 🎉', 'Cuốn \"software engineering\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 9, 0, '2026-05-18 16:15:39'),
(81, 3, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Ca dao tục ngữ Việt Nam\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 8, 0, '2026-05-18 16:15:41'),
(82, 3, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Toán học cao \" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 7, 0, '2026-05-18 16:15:42'),
(83, 3, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Hai đứa trẻ\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 6, 0, '2026-05-18 16:15:43'),
(84, 3, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Toán 9\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 3, 0, '2026-05-18 16:15:44'),
(85, 3, 'Quyên góp hoàn tất 🎉', 'Cuốn \"Kẻ lười biếng\" đã được nhập vào kho thư viện và sẵn sàng phục vụ bạn đọc. Cảm ơn đóng góp quý giá của bạn!', 'donation_approved', 1, 0, '2026-05-18 16:15:45'),
(86, 9, 'Yêu cầu mượn sách được duyệt ✅', 'Yêu cầu mượn \"Những cô em gái\" đã được duyệt. Sách sẽ được giao đến bạn. Phí ship (15.000đ) thanh toán khi nhận.', 'borrow_approved', 49, 0, '2026-05-18 16:16:08'),
(87, 9, 'Sách đang được chuẩn bị 📦', 'Thư viện đang chuẩn bị cuốn \"Những cô em gái\" để giao đến bạn. Chúng tôi sẽ thông báo khi sách được gửi đi.', 'borrow_approved', 49, 0, '2026-05-18 16:16:14'),
(88, 9, 'Sách đang trên đường đến bạn 🚚', 'Cuốn \"Những cô em gái\" đã được giao cho đơn vị vận chuyển. Hạn trả sau khi nhận sách: 2026-06-01.', 'borrow_approved', 49, 0, '2026-05-18 16:16:18'),
(89, 9, 'Xác nhận đã nhận sách 📚', 'Bạn đã nhận cuốn \"Những cô em gái\". Hạn trả: 2026-06-01. Chúc bạn đọc vui!', 'borrow_approved', 49, 0, '2026-05-18 16:16:23');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `shipping_fee_config`
--

CREATE TABLE `shipping_fee_config` (
  `id` int(11) NOT NULL,
  `min_km` decimal(8,2) NOT NULL,
  `max_km` decimal(8,2) NOT NULL,
  `fee` int(11) NOT NULL COMMENT 'Ph?? v???n chuy???n (VN??)',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `shipping_fee_config`
--

INSERT INTO `shipping_fee_config` (`id`, `min_km`, `max_km`, `fee`, `is_active`, `updated_at`) VALUES
(1, 0.00, 5.00, 15000, 1, '2026-05-18 13:55:26'),
(2, 5.00, 10.00, 25000, 1, '2026-05-18 13:55:26'),
(3, 10.00, 20.00, 40000, 1, '2026-05-18 13:55:26'),
(4, 20.00, 35.00, 60000, 1, '2026-05-18 13:55:26');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `system_announcements`
--

CREATE TABLE `system_announcements` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `ref_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `role` enum('user','admin','super-admin') NOT NULL DEFAULT 'user',
  `avatar` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fcm_token` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `password_hash`, `phone`, `address`, `role`, `avatar`, `created_at`, `updated_at`, `fcm_token`) VALUES
(1, 'Chiến D', 'chiennguyen@gmail.con', '$2y$10$Aj5MoVJbBeYo4TT3RRekcuUjmW/aLmLoSHkabK05Kb67RwyrkFMCa', NULL, NULL, 'user', NULL, '2026-05-20 11:50:52', '2026-05-20 11:50:52', NULL),
(2, 'Chiếnc', 'chient@gmail.com', '$2y$10$n46o/88ts1ZeNUHlERCjPO4NHsfm8TeISBzDeIzhJC917UO4mS47q', NULL, NULL, 'user', NULL, '2026-05-20 11:53:51', '2026-05-20 11:54:01', 'ef1eH3JvQBKsbQWwnIxBER:APA91bExLCsv-NB6gj_MQmhVIaKpRhMNvtjkw8kK7I4T_d_sk23q0wqpPjDeNsizBuIiW_bqXGzRis9FpL6N1B5YkDLcJYZYkO7Tl2Zn9yJeSUioweviM6g'),
(3, 'chien', 'admin@gmail.com', '$2y$10$oY6OLnmtnikbPKjJUeqSme5YDIT2A5gY.TC4o.CD1NlUeq9c4AAKC', '03321798111', 'thon qt, xa iasao, gia lai vn', 'super-admin', NULL, '2025-11-26 07:41:21', '2026-03-31 13:32:11', NULL),
(7, 'admin1', 'admin1@gmail.com', '$2y$10$3urdgJ0WMNkJwv5GwftQZOW2hXupejPxyl4uxjQwus4y45xQE2fYO', '', '', 'super-admin', NULL, '2025-12-15 02:00:46', '2025-12-30 03:27:57', NULL),
(9, 'chiến nguyễn thanh', 'chiennt@gmail.com', '$2y$10$DJ.NpH3q/VBzr5OsXnbauOXeDVLscB5DTbl6ZRnSooPW3aq3/lQ2i', '0332179813', '470 Trần Đại Nghĩa, Ngũ Hành Sơn, Đà Nẵng', 'super-admin', 'avatars/avatar_9_1779278552.jpg', '2026-03-18 13:10:53', '2026-05-20 12:17:00', 'ccTAFeAFTzeFIOrLZH4lVs:APA91bGbV9OGdVR6G40K56k7Xnx-S41lVlIx-kTrQO_KxkdWut7SJ6Suz2_BcpDS5xREJMjxwJi0CgOBsbBmrrCQUR735HSuX_I50U0_DkmGr0RfbXZJIZg'),
(10, 'chiến nguyễn', 'chiennguyenthanh31@gmail.com', '$2y$10$jwFJ28lVSLGV4mep7tgcO.idN7.EQXWmwGGl6ICFQvoVeKjgNyg9m', '', '', 'super-admin', NULL, '2026-03-31 14:03:51', '2026-05-20 11:58:49', 'ccTAFeAFTzeFIOrLZH4lVs:APA91bGbV9OGdVR6G40K56k7Xnx-S41lVlIx-kTrQO_KxkdWut7SJ6Suz2_BcpDS5xREJMjxwJi0CgOBsbBmrrCQUR735HSuX_I50U0_DkmGr0RfbXZJIZg'),
(11, 'Nguyễn Thanh Chiến', 'chienn@gmail.com', '$2y$10$nqO9ROsd0PuLr6nkEMDHfOhEPadagrt8IgLzMLxLgBo5fydnFqJXm', '', '', 'user', NULL, '2026-04-22 07:08:01', '2026-05-13 13:23:54', NULL);

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `borrowings`
--
ALTER TABLE `borrowings`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `donations`
--
ALTER TABLE `donations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `library_config`
--
ALTER TABLE `library_config`
  ADD PRIMARY KEY (`config_key`);

--
-- Chỉ mục cho bảng `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `shipping_fee_config`
--
ALTER TABLE `shipping_fee_config`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `system_announcements`
--
ALTER TABLE `system_announcements`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `books`
--
ALTER TABLE `books`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT cho bảng `borrowings`
--
ALTER TABLE `borrowings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `donations`
--
ALTER TABLE `donations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT cho bảng `shipping_fee_config`
--
ALTER TABLE `shipping_fee_config`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `system_announcements`
--
ALTER TABLE `system_announcements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `donations`
--
ALTER TABLE `donations`
  ADD CONSTRAINT `donations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
