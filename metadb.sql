-- MySQL dump 10.13  Distrib 5.7.17, for Win64 (x86_64)
--
-- Host: 10.17.139.66    Database: hivedb
-- ------------------------------------------------------
-- Server version	5.7.17

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `BUCKETING_COLS`
--

DROP TABLE IF EXISTS `BUCKETING_COLS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BUCKETING_COLS` (
  `SD_ID` bigint(20) NOT NULL,
  `BUCKET_COL_NAME` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`SD_ID`,`INTEGER_IDX`),
  KEY `BUCKETING_COLS_N49` (`SD_ID`),
  CONSTRAINT `BUCKETING_COLS_FK1` FOREIGN KEY (`SD_ID`) REFERENCES `SDS` (`SD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `CDS`
--

DROP TABLE IF EXISTS `CDS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CDS` (
  `CD_ID` bigint(20) NOT NULL,
  PRIMARY KEY (`CD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `COLUMNS_V2`
--

DROP TABLE IF EXISTS `COLUMNS_V2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `COLUMNS_V2` (
  `CD_ID` bigint(20) NOT NULL,
  `COMMENT` varchar(256) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `COLUMN_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `TYPE_NAME` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`CD_ID`,`COLUMN_NAME`),
  KEY `COLUMNS_V2_N49` (`CD_ID`),
  CONSTRAINT `COLUMNS_V2_FK1` FOREIGN KEY (`CD_ID`) REFERENCES `CDS` (`CD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `DATABASE_PARAMS`
--

DROP TABLE IF EXISTS `DATABASE_PARAMS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `DATABASE_PARAMS` (
  `DB_ID` bigint(20) NOT NULL,
  `PARAM_KEY` varchar(180) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `PARAM_VALUE` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`DB_ID`,`PARAM_KEY`),
  KEY `DATABASE_PARAMS_N49` (`DB_ID`),
  CONSTRAINT `DATABASE_PARAMS_FK1` FOREIGN KEY (`DB_ID`) REFERENCES `DBS` (`DB_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `DBS`
--

DROP TABLE IF EXISTS `DBS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `DBS` (
  `DB_ID` bigint(20) NOT NULL,
  `DESC` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `DB_LOCATION_URI` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `OWNER_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `OWNER_TYPE` varchar(10) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`DB_ID`),
  UNIQUE KEY `UNIQUE_DATABASE` (`NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `FUNCS`
--

DROP TABLE IF EXISTS `FUNCS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FUNCS` (
  `FUNC_ID` bigint(20) NOT NULL,
  `CLASS_NAME` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `CREATE_TIME` int(11) NOT NULL,
  `DB_ID` bigint(20) DEFAULT NULL,
  `FUNC_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `FUNC_TYPE` int(11) NOT NULL,
  `OWNER_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `OWNER_TYPE` varchar(10) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`FUNC_ID`),
  UNIQUE KEY `UNIQUEFUNCTION` (`FUNC_NAME`,`DB_ID`),
  KEY `FUNCS_N49` (`DB_ID`),
  CONSTRAINT `FUNCS_FK1` FOREIGN KEY (`DB_ID`) REFERENCES `DBS` (`DB_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `FUNC_RU`
--

DROP TABLE IF EXISTS `FUNC_RU`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FUNC_RU` (
  `FUNC_ID` bigint(20) NOT NULL,
  `RESOURCE_TYPE` int(11) NOT NULL,
  `RESOURCE_URI` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`FUNC_ID`,`INTEGER_IDX`),
  KEY `FUNC_RU_N49` (`FUNC_ID`),
  CONSTRAINT `FUNC_RU_FK1` FOREIGN KEY (`FUNC_ID`) REFERENCES `FUNCS` (`FUNC_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `GLOBAL_PRIVS`
--

DROP TABLE IF EXISTS `GLOBAL_PRIVS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GLOBAL_PRIVS` (
  `USER_GRANT_ID` bigint(20) NOT NULL,
  `CREATE_TIME` int(11) NOT NULL,
  `GRANT_OPTION` smallint(6) NOT NULL,
  `GRANTOR` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `GRANTOR_TYPE` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `PRINCIPAL_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `PRINCIPAL_TYPE` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `USER_PRIV` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`USER_GRANT_ID`),
  UNIQUE KEY `GLOBALPRIVILEGEINDEX` (`PRINCIPAL_NAME`,`PRINCIPAL_TYPE`,`USER_PRIV`,`GRANTOR`,`GRANTOR_TYPE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `PARTITIONS`
--

DROP TABLE IF EXISTS `PARTITIONS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `PARTITIONS` (
  `PART_ID` bigint(20) NOT NULL,
  `CREATE_TIME` int(11) NOT NULL,
  `LAST_ACCESS_TIME` int(11) NOT NULL,
  `PART_NAME` varchar(767) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `SD_ID` bigint(20) DEFAULT NULL,
  `TBL_ID` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`PART_ID`),
  UNIQUE KEY `UNIQUEPARTITION` (`PART_NAME`,`TBL_ID`),
  KEY `PARTITIONS_N49` (`SD_ID`),
  KEY `PARTITIONS_N50` (`TBL_ID`),
  CONSTRAINT `PARTITIONS_FK1` FOREIGN KEY (`TBL_ID`) REFERENCES `TBLS` (`TBL_ID`),
  CONSTRAINT `PARTITIONS_FK2` FOREIGN KEY (`SD_ID`) REFERENCES `SDS` (`SD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `PARTITION_KEYS`
--

DROP TABLE IF EXISTS `PARTITION_KEYS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `PARTITION_KEYS` (
  `TBL_ID` bigint(20) NOT NULL,
  `PKEY_COMMENT` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `PKEY_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `PKEY_TYPE` varchar(767) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`TBL_ID`,`PKEY_NAME`),
  KEY `PARTITION_KEYS_N49` (`TBL_ID`),
  CONSTRAINT `PARTITION_KEYS_FK1` FOREIGN KEY (`TBL_ID`) REFERENCES `TBLS` (`TBL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `PARTITION_KEY_VALS`
--

DROP TABLE IF EXISTS `PARTITION_KEY_VALS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `PARTITION_KEY_VALS` (
  `PART_ID` bigint(20) NOT NULL,
  `PART_KEY_VAL` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`PART_ID`,`INTEGER_IDX`),
  KEY `PARTITION_KEY_VALS_N49` (`PART_ID`),
  CONSTRAINT `PARTITION_KEY_VALS_FK1` FOREIGN KEY (`PART_ID`) REFERENCES `PARTITIONS` (`PART_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `PARTITION_PARAMS`
--

DROP TABLE IF EXISTS `PARTITION_PARAMS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `PARTITION_PARAMS` (
  `PART_ID` bigint(20) NOT NULL,
  `PARAM_KEY` varchar(256) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `PARAM_VALUE` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`PART_ID`,`PARAM_KEY`),
  KEY `PARTITION_PARAMS_N49` (`PART_ID`),
  CONSTRAINT `PARTITION_PARAMS_FK1` FOREIGN KEY (`PART_ID`) REFERENCES `PARTITIONS` (`PART_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `PART_COL_STATS`
--

DROP TABLE IF EXISTS `PART_COL_STATS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `PART_COL_STATS` (
  `CS_ID` bigint(20) NOT NULL,
  `AVG_COL_LEN` double DEFAULT NULL,
  `COLUMN_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `COLUMN_TYPE` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `DB_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `BIG_DECIMAL_HIGH_VALUE` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `BIG_DECIMAL_LOW_VALUE` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `DOUBLE_HIGH_VALUE` double DEFAULT NULL,
  `DOUBLE_LOW_VALUE` double DEFAULT NULL,
  `LAST_ANALYZED` bigint(20) NOT NULL,
  `LONG_HIGH_VALUE` bigint(20) DEFAULT NULL,
  `LONG_LOW_VALUE` bigint(20) DEFAULT NULL,
  `MAX_COL_LEN` bigint(20) DEFAULT NULL,
  `NUM_DISTINCTS` bigint(20) DEFAULT NULL,
  `NUM_FALSES` bigint(20) DEFAULT NULL,
  `NUM_NULLS` bigint(20) NOT NULL,
  `NUM_TRUES` bigint(20) DEFAULT NULL,
  `PART_ID` bigint(20) DEFAULT NULL,
  `PARTITION_NAME` varchar(767) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `TABLE_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`CS_ID`),
  KEY `PART_COL_STATS_N49` (`PART_ID`),
  CONSTRAINT `PART_COL_STATS_FK1` FOREIGN KEY (`PART_ID`) REFERENCES `PARTITIONS` (`PART_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ROLES`
--

DROP TABLE IF EXISTS `ROLES`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ROLES` (
  `ROLE_ID` bigint(20) NOT NULL,
  `CREATE_TIME` int(11) NOT NULL,
  `OWNER_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `ROLE_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`ROLE_ID`),
  UNIQUE KEY `ROLEENTITYINDEX` (`ROLE_NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SDS`
--

DROP TABLE IF EXISTS `SDS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SDS` (
  `SD_ID` bigint(20) NOT NULL,
  `CD_ID` bigint(20) DEFAULT NULL,
  `INPUT_FORMAT` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `IS_COMPRESSED` bit(1) NOT NULL,
  `IS_STOREDASSUBDIRECTORIES` bit(1) NOT NULL,
  `LOCATION` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `NUM_BUCKETS` int(11) NOT NULL,
  `OUTPUT_FORMAT` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `SERDE_ID` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`SD_ID`),
  KEY `SDS_N50` (`CD_ID`),
  KEY `SDS_N49` (`SERDE_ID`),
  CONSTRAINT `SDS_FK1` FOREIGN KEY (`SERDE_ID`) REFERENCES `SERDES` (`SERDE_ID`),
  CONSTRAINT `SDS_FK2` FOREIGN KEY (`CD_ID`) REFERENCES `CDS` (`CD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SD_PARAMS`
--

DROP TABLE IF EXISTS `SD_PARAMS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SD_PARAMS` (
  `SD_ID` bigint(20) NOT NULL,
  `PARAM_KEY` varchar(256) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `PARAM_VALUE` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`SD_ID`,`PARAM_KEY`),
  KEY `SD_PARAMS_N49` (`SD_ID`),
  CONSTRAINT `SD_PARAMS_FK1` FOREIGN KEY (`SD_ID`) REFERENCES `SDS` (`SD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SEQUENCE_TABLE`
--

DROP TABLE IF EXISTS `SEQUENCE_TABLE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SEQUENCE_TABLE` (
  `SEQUENCE_NAME` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `NEXT_VAL` bigint(20) NOT NULL,
  PRIMARY KEY (`SEQUENCE_NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SERDES`
--

DROP TABLE IF EXISTS `SERDES`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SERDES` (
  `SERDE_ID` bigint(20) NOT NULL,
  `NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `SLIB` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`SERDE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SERDE_PARAMS`
--

DROP TABLE IF EXISTS `SERDE_PARAMS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SERDE_PARAMS` (
  `SERDE_ID` bigint(20) NOT NULL,
  `PARAM_KEY` varchar(256) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `PARAM_VALUE` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`SERDE_ID`,`PARAM_KEY`),
  KEY `SERDE_PARAMS_N49` (`SERDE_ID`),
  CONSTRAINT `SERDE_PARAMS_FK1` FOREIGN KEY (`SERDE_ID`) REFERENCES `SERDES` (`SERDE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SKEWED_COL_NAMES`
--

DROP TABLE IF EXISTS `SKEWED_COL_NAMES`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SKEWED_COL_NAMES` (
  `SD_ID` bigint(20) NOT NULL,
  `SKEWED_COL_NAME` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`SD_ID`,`INTEGER_IDX`),
  KEY `SKEWED_COL_NAMES_N49` (`SD_ID`),
  CONSTRAINT `SKEWED_COL_NAMES_FK1` FOREIGN KEY (`SD_ID`) REFERENCES `SDS` (`SD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SKEWED_COL_VALUE_LOC_MAP`
--

DROP TABLE IF EXISTS `SKEWED_COL_VALUE_LOC_MAP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SKEWED_COL_VALUE_LOC_MAP` (
  `SD_ID` bigint(20) NOT NULL,
  `STRING_LIST_ID_KID` bigint(20) NOT NULL,
  `LOCATION` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`SD_ID`,`STRING_LIST_ID_KID`),
  KEY `SKEWED_COL_VALUE_LOC_MAP_N50` (`STRING_LIST_ID_KID`),
  KEY `SKEWED_COL_VALUE_LOC_MAP_N49` (`SD_ID`),
  CONSTRAINT `SKEWED_COL_VALUE_LOC_MAP_FK1` FOREIGN KEY (`SD_ID`) REFERENCES `SDS` (`SD_ID`),
  CONSTRAINT `SKEWED_COL_VALUE_LOC_MAP_FK2` FOREIGN KEY (`STRING_LIST_ID_KID`) REFERENCES `SKEWED_STRING_LIST` (`STRING_LIST_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SKEWED_STRING_LIST`
--

DROP TABLE IF EXISTS `SKEWED_STRING_LIST`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SKEWED_STRING_LIST` (
  `STRING_LIST_ID` bigint(20) NOT NULL,
  PRIMARY KEY (`STRING_LIST_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SKEWED_STRING_LIST_VALUES`
--

DROP TABLE IF EXISTS `SKEWED_STRING_LIST_VALUES`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SKEWED_STRING_LIST_VALUES` (
  `STRING_LIST_ID` bigint(20) NOT NULL,
  `STRING_LIST_VALUE` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`STRING_LIST_ID`,`INTEGER_IDX`),
  KEY `SKEWED_STRING_LIST_VALUES_N49` (`STRING_LIST_ID`),
  CONSTRAINT `SKEWED_STRING_LIST_VALUES_FK1` FOREIGN KEY (`STRING_LIST_ID`) REFERENCES `SKEWED_STRING_LIST` (`STRING_LIST_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SKEWED_VALUES`
--

DROP TABLE IF EXISTS `SKEWED_VALUES`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SKEWED_VALUES` (
  `SD_ID_OID` bigint(20) NOT NULL,
  `STRING_LIST_ID_EID` bigint(20) DEFAULT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`SD_ID_OID`,`INTEGER_IDX`),
  KEY `SKEWED_VALUES_N50` (`STRING_LIST_ID_EID`),
  KEY `SKEWED_VALUES_N49` (`SD_ID_OID`),
  CONSTRAINT `SKEWED_VALUES_FK1` FOREIGN KEY (`SD_ID_OID`) REFERENCES `SDS` (`SD_ID`),
  CONSTRAINT `SKEWED_VALUES_FK2` FOREIGN KEY (`STRING_LIST_ID_EID`) REFERENCES `SKEWED_STRING_LIST` (`STRING_LIST_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SORT_COLS`
--

DROP TABLE IF EXISTS `SORT_COLS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SORT_COLS` (
  `SD_ID` bigint(20) NOT NULL,
  `COLUMN_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `ORDER` int(11) NOT NULL,
  `INTEGER_IDX` int(11) NOT NULL,
  PRIMARY KEY (`SD_ID`,`INTEGER_IDX`),
  KEY `SORT_COLS_N49` (`SD_ID`),
  CONSTRAINT `SORT_COLS_FK1` FOREIGN KEY (`SD_ID`) REFERENCES `SDS` (`SD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TABLE_PARAMS`
--

DROP TABLE IF EXISTS `TABLE_PARAMS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `TABLE_PARAMS` (
  `TBL_ID` bigint(20) NOT NULL,
  `PARAM_KEY` varchar(256) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `PARAM_VALUE` varchar(4000) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`TBL_ID`,`PARAM_KEY`),
  KEY `TABLE_PARAMS_N49` (`TBL_ID`),
  CONSTRAINT `TABLE_PARAMS_FK1` FOREIGN KEY (`TBL_ID`) REFERENCES `TBLS` (`TBL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TAB_COL_STATS`
--

DROP TABLE IF EXISTS `TAB_COL_STATS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `TAB_COL_STATS` (
  `CS_ID` bigint(20) NOT NULL,
  `AVG_COL_LEN` double DEFAULT NULL,
  `COLUMN_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `COLUMN_TYPE` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `DB_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `BIG_DECIMAL_HIGH_VALUE` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `BIG_DECIMAL_LOW_VALUE` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `DOUBLE_HIGH_VALUE` double DEFAULT NULL,
  `DOUBLE_LOW_VALUE` double DEFAULT NULL,
  `LAST_ANALYZED` bigint(20) NOT NULL,
  `LONG_HIGH_VALUE` bigint(20) DEFAULT NULL,
  `LONG_LOW_VALUE` bigint(20) DEFAULT NULL,
  `MAX_COL_LEN` bigint(20) DEFAULT NULL,
  `NUM_DISTINCTS` bigint(20) DEFAULT NULL,
  `NUM_FALSES` bigint(20) DEFAULT NULL,
  `NUM_NULLS` bigint(20) NOT NULL,
  `NUM_TRUES` bigint(20) DEFAULT NULL,
  `TBL_ID` bigint(20) DEFAULT NULL,
  `TABLE_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`CS_ID`),
  KEY `TAB_COL_STATS_N49` (`TBL_ID`),
  CONSTRAINT `TAB_COL_STATS_FK1` FOREIGN KEY (`TBL_ID`) REFERENCES `TBLS` (`TBL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TBLS`
--

DROP TABLE IF EXISTS `TBLS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `TBLS` (
  `TBL_ID` bigint(20) NOT NULL,
  `CREATE_TIME` int(11) NOT NULL,
  `DB_ID` bigint(20) DEFAULT NULL,
  `LAST_ACCESS_TIME` int(11) NOT NULL,
  `OWNER` varchar(767) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `RETENTION` int(11) NOT NULL,
  `SD_ID` bigint(20) DEFAULT NULL,
  `TBL_NAME` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `TBL_TYPE` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `VIEW_EXPANDED_TEXT` mediumtext COLLATE utf8_unicode_ci,
  `VIEW_ORIGINAL_TEXT` mediumtext COLLATE utf8_unicode_ci,
  PRIMARY KEY (`TBL_ID`),
  UNIQUE KEY `UNIQUETABLE` (`TBL_NAME`,`DB_ID`),
  KEY `TBLS_N50` (`SD_ID`),
  KEY `TBLS_N49` (`DB_ID`),
  CONSTRAINT `TBLS_FK1` FOREIGN KEY (`DB_ID`) REFERENCES `DBS` (`DB_ID`),
  CONSTRAINT `TBLS_FK2` FOREIGN KEY (`SD_ID`) REFERENCES `SDS` (`SD_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `VERSION`
--

DROP TABLE IF EXISTS `VERSION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `VERSION` (
  `VER_ID` bigint(20) NOT NULL,
  `SCHEMA_VERSION` varchar(127) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `VERSION_COMMENT` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`VER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'hivedb'
--

--
-- Dumping routines for database 'hivedb'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-07-14 10:27:21
-- MySQL dump 10.13  Distrib 5.7.17, for Win64 (x86_64)
--
-- Host: 10.17.139.66    Database: ooziedb
-- ------------------------------------------------------
-- Server version	5.7.17

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `BUNDLE_ACTIONS`
--

DROP TABLE IF EXISTS `BUNDLE_ACTIONS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BUNDLE_ACTIONS` (
  `bundle_action_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `bundle_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `coord_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `coord_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `critical` int(11) DEFAULT NULL,
  `last_modified_time` datetime DEFAULT NULL,
  `pending` int(11) DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`bundle_action_id`),
  KEY `I_BNDLTNS_BUNDLE_ID` (`bundle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `BUNDLE_JOBS`
--

DROP TABLE IF EXISTS `BUNDLE_JOBS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BUNDLE_JOBS` (
  `id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `app_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `conf` mediumblob,
  `created_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `group_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `job_xml` mediumblob,
  `kickoff_time` datetime DEFAULT NULL,
  `last_modified_time` datetime DEFAULT NULL,
  `orig_job_xml` mediumblob,
  `pause_time` datetime DEFAULT NULL,
  `pending` int(11) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suspended_time` datetime DEFAULT NULL,
  `time_out` int(11) DEFAULT NULL,
  `time_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `I_BNDLJBS_CREATED_TIME` (`created_time`),
  KEY `I_BNDLJBS_LAST_MODIFIED_TIME` (`last_modified_time`),
  KEY `I_BNDLJBS_STATUS` (`status`),
  KEY `I_BNDLJBS_SUSPENDED_TIME` (`suspended_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `COORD_ACTIONS`
--

DROP TABLE IF EXISTS `COORD_ACTIONS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `COORD_ACTIONS` (
  `id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `action_number` int(11) DEFAULT NULL,
  `action_xml` mediumblob,
  `console_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_conf` mediumblob,
  `created_time` datetime DEFAULT NULL,
  `error_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `error_message` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `job_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_modified_time` datetime DEFAULT NULL,
  `missing_dependencies` mediumblob,
  `nominal_time` datetime DEFAULT NULL,
  `pending` int(11) DEFAULT NULL,
  `push_missing_dependencies` mediumblob,
  `rerun_time` datetime DEFAULT NULL,
  `run_conf` mediumblob,
  `sla_xml` mediumblob,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `time_out` int(11) DEFAULT NULL,
  `tracker_uri` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `job_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `I_CRD_TNS_CREATED_TIME` (`created_time`),
  KEY `I_CRD_TNS_EXTERNAL_ID` (`external_id`),
  KEY `I_CRD_TNS_JOB_ID` (`job_id`),
  KEY `I_CRD_TNS_LAST_MODIFIED_TIME` (`last_modified_time`),
  KEY `I_CRD_TNS_NOMINAL_TIME` (`nominal_time`),
  KEY `I_CRD_TNS_RERUN_TIME` (`rerun_time`),
  KEY `I_CRD_TNS_STATUS` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `COORD_JOBS`
--

DROP TABLE IF EXISTS `COORD_JOBS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `COORD_JOBS` (
  `id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `app_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_namespace` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bundle_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `concurrency` int(11) DEFAULT NULL,
  `conf` mediumblob,
  `created_time` datetime DEFAULT NULL,
  `done_materialization` int(11) DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `execution` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `frequency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `group_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `job_xml` mediumblob,
  `last_action_number` int(11) DEFAULT NULL,
  `last_action` datetime DEFAULT NULL,
  `last_modified_time` datetime DEFAULT NULL,
  `mat_throttling` int(11) DEFAULT NULL,
  `next_matd_time` datetime DEFAULT NULL,
  `orig_job_xml` mediumblob,
  `pause_time` datetime DEFAULT NULL,
  `pending` int(11) DEFAULT NULL,
  `sla_xml` mediumblob,
  `start_time` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `suspended_time` datetime DEFAULT NULL,
  `time_out` int(11) DEFAULT NULL,
  `time_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `time_zone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `I_CRD_JBS_BUNDLE_ID` (`bundle_id`),
  KEY `I_CRD_JBS_CREATED_TIME` (`created_time`),
  KEY `I_CRD_JBS_END_TIME` (`end_time`),
  KEY `I_CRD_JBS_LAST_MODIFIED_TIME` (`last_modified_time`),
  KEY `I_CRD_JBS_NEXT_MATD_TIME` (`next_matd_time`),
  KEY `I_CRD_JBS_STATUS` (`status`),
  KEY `I_CRD_JBS_SUSPENDED_TIME` (`suspended_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `OPENJPA_SEQUENCE_TABLE`
--

DROP TABLE IF EXISTS `OPENJPA_SEQUENCE_TABLE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `OPENJPA_SEQUENCE_TABLE` (
  `ID` tinyint(4) NOT NULL,
  `SEQUENCE_VALUE` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SLA_EVENTS`
--

DROP TABLE IF EXISTS `SLA_EVENTS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SLA_EVENTS` (
  `event_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `alert_contact` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alert_frequency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alert_percentage` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `dev_contact` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `group_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `job_data` text COLLATE utf8_unicode_ci,
  `notification_msg` text COLLATE utf8_unicode_ci,
  `parent_client_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_sla_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `qa_contact` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `se_contact` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sla_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `upstream_apps` text COLLATE utf8_unicode_ci,
  `user_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bean_type` varchar(31) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `event_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expected_end` datetime DEFAULT NULL,
  `expected_start` datetime DEFAULT NULL,
  `job_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status_timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`event_id`),
  KEY `I_SL_VNTS_DTYPE` (`bean_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SLA_REGISTRATION`
--

DROP TABLE IF EXISTS `SLA_REGISTRATION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SLA_REGISTRATION` (
  `job_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `app_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_time` datetime DEFAULT NULL,
  `expected_duration` bigint(20) DEFAULT NULL,
  `expected_end` datetime DEFAULT NULL,
  `expected_start` datetime DEFAULT NULL,
  `job_data` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nominal_time` datetime DEFAULT NULL,
  `notification_msg` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sla_config` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `upstream_apps` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`job_id`),
  KEY `I_SL_RRTN_NOMINAL_TIME` (`nominal_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SLA_SUMMARY`
--

DROP TABLE IF EXISTS `SLA_SUMMARY`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SLA_SUMMARY` (
  `job_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `actual_duration` bigint(20) DEFAULT NULL,
  `actual_end` datetime DEFAULT NULL,
  `actual_start` datetime DEFAULT NULL,
  `app_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_time` datetime DEFAULT NULL,
  `event_processed` tinyint(4) DEFAULT NULL,
  `event_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expected_duration` bigint(20) DEFAULT NULL,
  `expected_end` datetime DEFAULT NULL,
  `expected_start` datetime DEFAULT NULL,
  `job_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_modified` datetime DEFAULT NULL,
  `nominal_time` datetime DEFAULT NULL,
  `parent_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sla_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`job_id`),
  KEY `I_SL_SMRY_APP_NAME` (`app_name`),
  KEY `I_SL_SMRY_EVENT_PROCESSED` (`event_processed`),
  KEY `I_SL_SMRY_LAST_MODIFIED` (`last_modified`),
  KEY `I_SL_SMRY_NOMINAL_TIME` (`nominal_time`),
  KEY `I_SL_SMRY_PARENT_ID` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `VALIDATE_CONN`
--

DROP TABLE IF EXISTS `VALIDATE_CONN`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `VALIDATE_CONN` (
  `id` bigint(20) NOT NULL,
  `dummy` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WF_ACTIONS`
--

DROP TABLE IF EXISTS `WF_ACTIONS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `WF_ACTIONS` (
  `id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `conf` mediumblob,
  `console_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_time` datetime DEFAULT NULL,
  `cred` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `data` mediumblob,
  `end_time` datetime DEFAULT NULL,
  `error_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `error_message` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `execution_path` mediumtext COLLATE utf8_unicode_ci,
  `external_child_ids` mediumblob,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_check_time` datetime DEFAULT NULL,
  `log_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pending` int(11) DEFAULT NULL,
  `pending_age` datetime DEFAULT NULL,
  `retries` int(11) DEFAULT NULL,
  `signal_value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sla_xml` mediumblob,
  `start_time` datetime DEFAULT NULL,
  `stats` mediumblob,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tracker_uri` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `transition` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_retry_count` int(11) DEFAULT NULL,
  `user_retry_interval` int(11) DEFAULT NULL,
  `user_retry_max` int(11) DEFAULT NULL,
  `wf_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `I_WF_CTNS_PENDING_AGE` (`pending_age`),
  KEY `I_WF_CTNS_STATUS` (`status`),
  KEY `I_WF_CTNS_WF_ID` (`wf_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WF_JOBS`
--

DROP TABLE IF EXISTS `WF_JOBS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `WF_JOBS` (
  `id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `app_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app_path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `conf` mediumblob,
  `created_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `group_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_modified_time` datetime DEFAULT NULL,
  `log_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `proto_action_conf` mediumblob,
  `run` int(11) DEFAULT NULL,
  `sla_xml` mediumblob,
  `start_time` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wf_instance` mediumblob,
  PRIMARY KEY (`id`),
  KEY `I_WF_JOBS_END_TIME` (`end_time`),
  KEY `I_WF_JOBS_EXTERNAL_ID` (`external_id`),
  KEY `I_WF_JOBS_LAST_MODIFIED_TIME` (`last_modified_time`),
  KEY `I_WF_JOBS_PARENT_ID` (`parent_id`),
  KEY `I_WF_JOBS_STATUS` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'ooziedb'
--

--
-- Dumping routines for database 'ooziedb'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-07-14 10:27:21
