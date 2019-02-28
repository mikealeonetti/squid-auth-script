/*****************************************************************

 Squid Arms and Tentacles: Authentication (version 1.0)
        Mike A. Leonetti
          2009-07-29

 http://www.mikealeonetti.com/wiki/index.php/Squid_Arms_and_Tentacles:_Authentication


*****************************************************************/


--
-- Table structure for table `addresses`
--

DROP TABLE IF EXISTS `addresses`;

CREATE TABLE `addresses` (
  `ip` varchar(15) NOT NULL,
  `user` varchar(32) NOT NULL,
  `start_time` int(11) unsigned NOT NULL,
  `end_time` int(11) unsigned NOT NULL,
  PRIMARY KEY (`ip`),
  KEY `end_time` (`end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;

CREATE TABLE IF NOT EXISTS `groups` (
  `group` varchar(32) NOT NULL,
  `user` varchar(32) NOT NULL,
  PRIMARY KEY (`group`,`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

