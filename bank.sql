-- phpMyAdmin SQL Dump
-- version 4.4.12
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Nov 19, 2018 at 06:05 AM
-- Server version: 5.6.25
-- PHP Version: 5.6.11

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bank`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `deposit`(IN `accno` VARCHAR(20), IN `amount` FLOAT)
    MODIFIES SQL DATA
    DETERMINISTIC
BEGIN
select @accid:=id from account where no=accno;
insert into transaction(type,amount,date,accid) 
values('D',amount,now(),@accid);
COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deposit2`(IN `accno` VARCHAR(20), IN `amount` FLOAT)
    MODIFIES SQL DATA
    DETERMINISTIC
BEGIN
SELECT @accid:=id FROM account WHERE no=accno;
IF @accid IS null THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Account not found';
    
ELSEIF amount < 0 THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid amount of money';
        ROLLBACK;
    
ELSE
	SELECT calBalance(@accid) INTO @bal;
    IF @bal < 0 THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid amount of money';
        ROLLBACK;
        COMMIT;
	END IF;

	INSERT INTO transaction(type, amount, date,accid) 
    VALUES ('D', amount,now(),@accid);
    UPDATE account SET bal = calBalance(@accid) WHERE id = @accid; 
    COMMIT;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `withdraw`(IN `accno` VARCHAR(20), IN `amount` FLOAT)
    MODIFIES SQL DATA
    DETERMINISTIC
BEGIN
 select @accid:=id from account where no=accno;
 INSERT INTO transaction(type,amount,date,accid)
 VALUES('W',amount,now(),@accid);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `withdraw2`(IN `accno` VARCHAR(20), IN `amount` FLOAT)
    MODIFIES SQL DATA
BEGIN
SET @accid = null;
SELECT id into @accid FROM account where no=accno;
IF @accid is null THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Account not found';
ELSEIF amount < 0 THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough money';
        ROLLBACK;

ELSE
	SELECT calBalance(@accid) INTO @bal;
    IF @bal - amount < 0 THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough money';
        ROLLBACK;
    END IF;
    INSERT INTO transaction(type, amount, date,accid) 
    VALUES ('W', amount,now(),@accid);
    UPDATE account SET bal = calBalance(@accid) WHERE id = @accid; 
    COMMIT;
    
END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calBalance`(`id2` INT) RETURNS float
    MODIFIES SQL DATA
    DETERMINISTIC
BEGIN
 
 SELECT SUM(CASE TYPE WHEN 'W' THEN -amount WHEN 'D' THEN amount END) INTO @ans FROM transaction where accid=id2;
 RETURN @ans;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `CustomerLevel`(`p_creditLimit` DOUBLE) RETURNS varchar(10) CHARSET latin1
    NO SQL
    DETERMINISTIC
BEGIN
DECLARE lvl varchar(10);
If p_creditLimit > 50000 Then 
 SET lvl = 'PLATINUM';
ELSEIF (p_creditLimit <=50000 and p_creditLimit >= 10000) THEN 
 SET lvl = 'Gold';
ELSEIF p_creditLimit < 10000 THEN
 SET lvl = 'SILVER';
END IF;


RETURN (lvl);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `account`
--

CREATE TABLE IF NOT EXISTS `account` (
  `id` int(11) NOT NULL,
  `no` varchar(20) DEFAULT NULL,
  `name` varchar(200) DEFAULT NULL,
  `creditLimit` double DEFAULT NULL,
  `bal` float DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `account`
--

INSERT INTO `account` (`id`, `no`, `name`, `creditLimit`, `bal`) VALUES
(1, '1111', 'Mr. A', 15000, 7051),
(2, '2222', 'Mr. B', 55000, 440);

-- --------------------------------------------------------

--
-- Table structure for table `messagelog`
--

CREATE TABLE IF NOT EXISTS `messagelog` (
  `msg_id` int(11) NOT NULL,
  `msg_text` varchar(500) NOT NULL,
  `msg_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `messagelog`
--

INSERT INTO `messagelog` (`msg_id`, `msg_text`, `msg_time`) VALUES
(1, 'Mr. Bwithdraw20', '2018-11-19 11:46:02'),
(2, 'Mr. B deposit 10', '2018-11-19 11:46:37'),
(3, 'Mr. B withdraw 50', '2018-11-19 11:46:58'),
(4, 'Mr. A withdraw 30', '2018-11-19 11:53:47'),
(5, 'Mr. A withdraw 20', '2018-11-19 11:59:10'),
(6, 'Mr. A withdraw -20', '2018-11-19 11:59:21'),
(7, 'Mr. A deposit -20', '2018-11-19 12:02:14');

-- --------------------------------------------------------

--
-- Table structure for table `transaction`
--

CREATE TABLE IF NOT EXISTS `transaction` (
  `id` int(11) NOT NULL,
  `type` char(1) DEFAULT NULL,
  `amount` float DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `accid` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `transaction`
--

INSERT INTO `transaction` (`id`, `type`, `amount`, `date`, `accid`) VALUES
(1, 'D', 5000, '2016-11-16 08:33:31', 1),
(2, 'W', 100, '2016-11-16 08:42:52', 1),
(3, 'D', 1000, '2016-11-16 08:53:01', 2),
(4, 'W', 500, '2016-11-16 08:53:11', 2),
(5, 'W', 100, '2016-11-23 08:30:17', 1),
(6, 'D', 1000, '2016-11-23 08:52:22', 1),
(7, 'W', 1000, '2016-11-23 08:53:19', 1),
(8, 'W', 100, '2017-11-06 08:22:37', 1),
(9, 'W', 100, '2017-11-06 08:23:27', 1),
(10, 'W', 100, '2017-11-06 08:26:45', 1),
(11, 'D', 100, '2017-11-06 08:43:44', 1),
(12, 'D', 100, '2017-11-06 08:44:47', 1),
(13, 'D', 100, '2017-11-06 08:45:00', 1),
(14, 'D', 1000, '2017-11-06 08:47:16', 1),
(15, 'D', 1000, '2017-11-06 08:49:12', 1),
(16, 'W', 1000, '2017-11-06 08:49:41', 1),
(17, 'D', 1000, '2017-11-06 08:49:52', 1),
(18, 'W', 1000, '2017-11-06 08:50:06', 1),
(19, 'D', 500, '2017-11-06 08:50:31', 1),
(20, 'D', 1000, '2017-11-06 08:51:29', 1),
(21, 'W', 1000, '2017-11-06 08:51:58', 1),
(22, 'D', 1000, '2017-11-06 08:52:06', 1),
(23, 'D', 1, '2017-11-06 08:52:41', 1),
(24, 'W', 1, '2017-11-06 08:52:54', 1),
(25, 'D', 1, '2017-11-06 08:54:12', 1),
(26, 'D', 100, '2017-11-06 08:57:05', 1),
(27, 'W', 100, '2017-11-06 08:57:18', 1),
(28, 'D', 100, '2017-11-06 08:58:37', 1),
(29, 'D', 100, '2017-11-06 08:59:03', 1),
(30, 'D', 100, '2017-11-06 09:00:09', 1),
(31, 'W', 500, '2017-11-06 09:00:20', 1),
(32, 'W', 10, '2018-11-19 10:52:50', 2),
(33, 'W', 10, '2018-11-19 10:54:39', 2),
(34, 'D', 20, '2018-11-19 10:56:51', 2),
(35, 'W', 20, '2018-11-19 11:46:02', 2),
(36, 'D', 10, '2018-11-19 11:46:37', 2),
(37, 'W', 50, '2018-11-19 11:46:58', 2),
(38, 'W', 30, '2018-11-19 11:53:47', 1),
(39, 'W', 20, '2018-11-19 11:59:10', 1),
(40, 'W', -20, '2018-11-19 11:59:21', 1),
(41, 'D', -20, '2018-11-19 12:02:14', 1);

--
-- Triggers `transaction`
--
DELIMITER $$
CREATE TRIGGER `insert_message` BEFORE INSERT ON `transaction`
 FOR EACH ROW BEGIN
    DECLARE msgtext VARCHAR(500);
    DECLARE msgtype VARCHAR(500);
    DECLARE msgid VARCHAR(500);
    
    SET msgid = (SELECT name FROM bank.account WHERE id = new.accid);
   	
    IF(new.type = 'D') THEN
    	SET msgtype = ' deposit ';
    ELSEIF(new.type = 'W') THEN
        SET msgtype = ' withdraw ';
    END IF;
    SET msgtext = CONCAT(msgid,msgtype,new.amount);
    INSERT INTO messagelog(msg_text) VALUES(msgtext);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `not_allow_delete` BEFORE DELETE ON `transaction`
 FOR EACH ROW BEGIN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot directly delete transaction !';
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `not_allow_update` BEFORE UPDATE ON `transaction`
 FOR EACH ROW BEGIN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot directly update transaction !';
    
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `account`
--
ALTER TABLE `account`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `messagelog`
--
ALTER TABLE `messagelog`
  ADD PRIMARY KEY (`msg_id`);

--
-- Indexes for table `transaction`
--
ALTER TABLE `transaction`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `account`
--
ALTER TABLE `account`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `messagelog`
--
ALTER TABLE `messagelog`
  MODIFY `msg_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `transaction`
--
ALTER TABLE `transaction`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=42;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
