CREATE DATABASE `Audio library`;
USE `Audio library`;
CREATE TABLE `Audio library`(cat varchar(15) PRIMARY KEY CHECK (cat IN('Жанр', 'Композиторы', 'Блогеры', 'Каверы', 'Саундтреки')), noorigartsbands smallint, nosongs smallint, songsdur varchar(15));
CREATE TABLE Genre(nam varchar(50) PRIMARY KEY, noartsbands smallint, nosongs smallint, songsdur varchar(15));
CREATE TABLE `Music artist/band`(ID smallint PRIMARY KEY, artband varchar(100), genr varchar(50) NULL, nosongs smallint, songsdur time, totnosongs smallint, totsongsdur time, cat varchar(15) CHECK (cat IN('Жанр', 'Композиторы', 'Блогеры', 'Каверы')), FOREIGN KEY (cat) REFERENCES `Audio library`(cat), FOREIGN KEY (genr) REFERENCES Genre(nam));
CREATE TABLE `Related music artist/band`(ID smallint PRIMARY KEY, relartband varchar(100), artband smallint, nosongs tinyint, songsdur time, FOREIGN KEY (artband) REFERENCES `Music artist/band`(ID));
CREATE TABLE `Music artist/band identifier`(ID smallint PRIMARY KEY, artband smallint NULL, relartband smallint NULL, FOREIGN KEY (artband) REFERENCES `Music artist/band`(ID), FOREIGN KEY (relartband) REFERENCES `Related music artist/band`(ID));
CREATE TABLE Song(ID int PRIMARY KEY auto_increment, nam varchar(150), dur time, cat varchar(15) NULL CHECK (cat='Каверы'), FOREIGN KEY (cat) REFERENCES `Audio library`(cat));
CREATE TABLE `Music artist/band's song`(song int, artband smallint, feat varchar(100) NULL, FOREIGN KEY (song) REFERENCES Song(ID), FOREIGN KEY (artband) REFERENCES `Music artist/band identifier`(ID));
CREATE TABLE `Cover's original music artist/band`(song int, artband smallint, feat varchar(100) NULL, FOREIGN KEY (song) REFERENCES Song(ID), FOREIGN KEY (artband) REFERENCES `Music artist/band identifier`(ID));
CREATE TABLE Favourites(num tinyint PRIMARY KEY, artband smallint, FOREIGN KEY (artband) REFERENCES `Music artist/band`(ID));
CREATE TABLE Soundtrack(ID smallint PRIMARY KEY auto_increment, movanimsergam varchar(150), artband varchar(500), song varchar(750), nosongs smallint, songsdur time, cat varchar(15) CHECK (cat='Саундтреки'), FOREIGN KEY (cat) REFERENCES `Audio library`(cat));
DELIMITER $
CREATE PROCEDURE NumberOfArtistsBands(category varchar(15), genre varchar(50))
BEGIN
SET @cat=category;
SET @genr=genre;
SET @noartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE genr=@genr);
SET @norelartsbands=(SELECT COUNT(`Related music artist/band`.artband) FROM `Music artist/band` JOIN `Related music artist/band` ON `Music artist/band`.ID=`Related music artist/band`.artband WHERE `Music artist/band`.genr=@genr);
SET @noorigartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE cat=@cat);
UPDATE Genre SET noartsbands=@noartsbands+@norelartsbands WHERE nam=@genr;
IF @cat='Жанр' THEN
UPDATE `Audio library` SET noorigartsbands=(SELECT SUM(noartsbands) FROM Genre) WHERE cat='Жанр';
ELSE
UPDATE `Audio library` SET noorigartsbands=@noorigartsbands WHERE cat=@cat;
END IF;
END$
CREATE PROCEDURE SongsCountandDuration(songid smallint, artistbandid smallint)
BEGIN
SET @song=songid;
SET @artbandid=artistbandid;
IF (SELECT cat FROM `Music artist/band` WHERE ID=@artbandid)!='Каверы' OR (SELECT cat FROM `Music artist/band` WHERE ID=(SELECT artband FROM `Related music artist/band` WHERE ID=@artbandid))!='Каверы' THEN
SET @noartbandsongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=@artbandid AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'));
SET @artbandsongsdur=(SELECT SEC_TO_TIME(SUM(TIME_TO_SEC(dur))) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=@artbandid AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')));
ELSE
SET @noartbandsongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=@artbandid AND song IN(SELECT ID FROM Song WHERE cat='Каверы'));
SET @artbandsongsdur=(SELECT SEC_TO_TIME(SUM(TIME_TO_SEC(dur))) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=@artbandid AND song IN(SELECT ID FROM Song WHERE cat='Каверы')));
END IF;
UPDATE `Related music artist/band` SET nosongs=@noartbandsongs, songsdur=@artbandsongsdur WHERE ID=@artbandid;
SET @relartbandnosongs=(SELECT SUM(nosongs) FROM `Related music artist/band` WHERE artband=(SELECT artband FROM `Related music artist/band` WHERE ID=@artbandid));
SET @relartbandsongsdur=(SELECT SUM(TIME_TO_SEC(songsdur)) FROM `Related music artist/band` WHERE artband=(SELECT artband FROM `Related music artist/band` WHERE ID=@artbandid));
IF @relartbandnosongs IS NULL AND @relartbandsongsdur IS NULL THEN
SET @relartbandnosongs=(SELECT SUM(nosongs) FROM `Related music artist/band` WHERE artband=@artbandid);
SET @relartbandsongsdur=(SELECT SUM(TIME_TO_SEC(songsdur)) FROM `Related music artist/band` WHERE artband=@artbandid);
IF @relartbandnosongs IS NULL AND @relartbandsongsdur IS NULL THEN
SET @relartbandnosongs=0;
SET @relartbandsongsdur=0;
END IF;
ELSE
SET @artbandid=(SELECT artband FROM `Related music artist/band` WHERE ID=@artbandid);
SET @noartbandsongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=@artbandid AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'));
SET @artbandsongsdur=(SELECT SEC_TO_TIME(SUM(TIME_TO_SEC(dur))) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=@artbandid AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')));
END IF;
UPDATE `Music artist/band` SET nosongs=@noartbandsongs, songsdur=@artbandsongsdur, totnosongs=nosongs+@relartbandnosongs, totsongsdur=(SELECT SEC_TO_TIME(TIME_TO_SEC(songsdur)+@relartbandsongsdur)) WHERE ID=@artbandid;
SET @artbandnosongs=(SELECT SUM(totnosongs) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=@artbandid));
SET @artbandsongsdurgenr=(SELECT SEC_TO_TIME(SUM(TIME_TO_SEC(totsongsdur))) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=@artbandid));
SET @artbandsongsdur=(SELECT REPLACE(CONCAT(FLOOR(TIME_FORMAT(@artbandsongsdurgenr, '%H')/24), 'd ', MOD(TIME_FORMAT(@artbandsongsdurgenr, '%H'), 24), ':', TIME_FORMAT(@artbandsongsdurgenr, '%i:%s')), '0d ', ''));
UPDATE Genre SET nosongs=@artbandnosongs, songsdur=@artbandsongsdur WHERE nam=(SELECT genr FROM `Music artist/band` WHERE ID=@artbandid);
IF (SELECT cat FROM Song WHERE ID=@song) IS NULL THEN
SET @artbandnosongs=(SELECT SUM(totnosongs) FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=@artbandid));
SET @artbandsongsduraudiolibrary=(SELECT SUM(TIME_TO_SEC(totsongsdur)) FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=@artbandid));
SET @artbandsongsdur=REPLACE((SELECT DATE_FORMAT(DATE('1000-01-01 00:00:00') + INTERVAL @artbandsongsduraudiolibrary SECOND - INTERVAL 1 DAY, '%jd %H:%i:%s')), '365d ', '');
UPDATE `Audio library` SET nosongs=@artbandnosongs, songsdur=@artbandsongsdur WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=@artbandid);
ELSE
SET @artbandnosongs=(SELECT COUNT(Song.ID) FROM `Music artist/band's song` JOIN Song ON `Music artist/band's song`.song=Song.ID WHERE Song.cat='Каверы');
SET @artbandsongsduraudiolibrary=(SELECT SUM(TIME_TO_SEC(Song.dur)) FROM `Music artist/band's song` JOIN Song ON `Music artist/band's song`.song=Song.ID WHERE Song.cat='Каверы');
SET @artbandsongsdur=REPLACE((SELECT DATE_FORMAT(DATE('1000-01-01 00:00:00') + INTERVAL @artbandsongsduraudiolibrary SECOND - INTERVAL 1 DAY, '%jd %H:%i:%s')), '365d ', '');
UPDATE `Audio library` SET nosongs=@artbandnosongs, songsdur=@artbandsongsdur WHERE cat='Каверы';
END IF;
UPDATE `Audio library` SET songsdur=REGEXP_REPLACE(songsdur, '0', '', 1, 1) WHERE cat='Жанр' AND songsdur LIKE('0%');
UPDATE `Audio library` SET songsdur=REGEXP_REPLACE(songsdur, '00', '', 1, 1) WHERE cat='Каверы' AND songsdur LIKE('0%');
END$
CREATE TRIGGER MusicArtistBandIDBEFOREINSERTONMUSICARTISTBAND BEFORE INSERT ON `Music artist/band` FOR EACH ROW
BEGIN
SET @artbandid=(SELECT MAX(ID) FROM `Music artist/band`);
SET @relartbandid=(SELECT MAX(ID) FROM `Related music artist/band`);
IF @artbandid<@relartbandid THEN
SET @artbandid=@relartbandid;
END IF;
IF @artbandid IS NULL THEN
SET @artbandid=0;
END IF;
SET NEW.ID=@artbandid+1;
END$
CREATE TRIGGER RelatedMusicArtistBandIDBEFOREINSERTONRELATEDMUSICARTISTBAND BEFORE INSERT ON `Related music artist/band` FOR EACH ROW
BEGIN
SET @relartbandid=(SELECT MAX(ID) FROM `Related music artist/band`);
SET @artbandid=(SELECT MAX(ID) FROM `Music artist/band`);
IF @relartbandid<@artbandid THEN
SET @relartbandid=@artbandid;
END IF;
IF @relartbandid IS NULL THEN
SET @relartbandid=@artbandid;
END IF;
SET NEW.ID=@relartbandid+1;
END$
DELIMITER ;
CREATE TRIGGER MusicArtistBandIDAFTERINSERTONMUSICARTISTBAND AFTER INSERT ON `Music artist/band` FOR EACH ROW
INSERT INTO `Music artist/band identifier`(ID, artband, relartband) VALUES(NEW.ID, NEW.ID, null);
CREATE TRIGGER RelatedMusicArtistBandIDAFTERINSERTONRELATEDMUSICARTISTBAND AFTER INSERT ON `Related music artist/band` FOR EACH ROW
INSERT INTO `Music artist/band identifier`(ID, artband, relartband) VALUES(NEW.ID, null, NEW.ID);
DELIMITER $
CREATE TRIGGER SongIDBEFOREINSERTONSONG BEFORE INSERT ON Song FOR EACH ROW
BEGIN
SET @songid=0;
UPDATE `Music artist/band's song` SET song=@songid:=@songid+1;
END$
DELIMITER ;
CREATE TRIGGER ArtistsBandsCountAFTERINSERTONMUSICARTISTBAND AFTER INSERT ON `Music artist/band` FOR EACH ROW
CALL NumberOfArtistsBands(NEW.cat, NEW.genr);
DELIMITER $
CREATE TRIGGER ArtistsBandsCountAFTERUPDATEONMUSICARTISTBAND AFTER UPDATE ON `Music artist/band` FOR EACH ROW
BEGIN
CALL NumberOfArtistsBands(OLD.cat, OLD.genr);
CALL NumberOfArtistsBands(NEW.cat, NEW.genr);
END$
DELIMITER ;
CREATE TRIGGER RelatedArtistsBandsCountAFTERINSERTONRELATEDMUSICARTISTBAND AFTER INSERT ON `Related music artist/band` FOR EACH ROW
CALL NumberOfArtistsBands('Жанр', (SELECT `Music artist/band`.genr FROM `Music artist/band` JOIN `Related music artist/band` ON `Music artist/band`.ID=`Related music artist/band`.artband WHERE `Related music artist/band`.artband=NEW.artband LIMIT 1));
DELIMITER $
CREATE TRIGGER SongsCountandDurationAFTERUPDATEONSONG AFTER UPDATE ON Song FOR EACH ROW
BEGIN
IF NEW.dur!=OLD.dur OR NEW.cat!=OLD.cat THEN
CALL SongsCountandDuration(NEW.ID, (SELECT artband FROM `Music artist/band's song` WHERE song=NEW.ID));
END IF;
END$
DELIMITER ;
CREATE TRIGGER SongsCountandDurationAFTERINSERTMUSICARTISTBAND AFTER INSERT ON `Music artist/band's song` FOR EACH ROW
CALL SongsCountandDuration(NEW.song, NEW.artband);
DELIMITER $
CREATE TRIGGER SongsCountandDurationAFTERDELETEONMUSICARTISTBAND AFTER DELETE ON `Music artist/band's song` FOR EACH ROW
BEGIN
CALL SongsCountandDuration(OLD.song, OLD.artband);
DELETE FROM Song WHERE ID=OLD.song;
SET @songid=0;
SET @@FOREIGN_KEY_CHECKS=0;
UPDATE Song SET ID=@songid:=@songid+1;
SET @@FOREIGN_KEY_CHECKS=1;
END$
DELIMITER ;
CREATE TRIGGER SoundtracksCountandDurationAFTERINSERTONSOUNDTRACK AFTER INSERT ON Soundtrack FOR EACH ROW
UPDATE `Audio library` SET noorigartsbands=0, nosongs=(SELECT SUM(nosongs) FROM Soundtrack), songsdur=REPLACE((SELECT DATE_FORMAT(DATE('1000-01-01 00:00:00') + INTERVAL SUM(TIME_TO_SEC(songsdur)) SECOND, '%jd %H:%i:%s') FROM Soundtrack), '001d ', '') WHERE cat='Саундтреки';
CREATE TRIGGER SoundtracksCountandDurationAFTERUPDATEONSOUNDTRACK AFTER UPDATE ON Soundtrack FOR EACH ROW
UPDATE `Audio library` SET noorigartsbands=0, nosongs=(SELECT SUM(nosongs) FROM Soundtrack), songsdur=REPLACE((SELECT DATE_FORMAT(DATE('1000-01-01 00:00:00') + INTERVAL SUM(TIME_TO_SEC(songsdur)) SECOND, '%jd %H:%i:%s') FROM Soundtrack), '001d ', '') WHERE cat='Саундтреки';
INSERT INTO `Audio library`(cat) VALUES('Жанр'),
                                                                          ('Композиторы'),
                                                                          ('Блогеры'),
                                                                          ('Каверы'),
                                                                          ('Саундтреки');
INSERT INTO Genre(nam) VALUES('Авторская песня, Шансон'),
                                                               ('Альтернатива, Инди'),
                                                               ('Блюз'),
                                                               ('ВИА'),
                                                               ('Вокальная музыка'),
                                                               ('Джаз'),
                                                               ('Кантри'),
                                                               ('Легкая, Инструментальная музыка'),
                                                               ('Метал, Ню-метал, Металкор'),
                                                               ('Панк, Эмо, Постхардкор'),
                                                               ('Поп'),
                                                               ('Поп-рок'),
                                                               ('Регги, Реггетон'),
                                                               ('Рок'),
                                                               ('Соул, Фанк, Диско'),
                                                               ('Хип-хоп'),
                                                               ('Электронная музыка');
