CREATE DATABASE `Audio library`;
USE `Audio library`;
CREATE TABLE `Audio library`(cat varchar(15) PRIMARY KEY, noorigartsbands smallint, nosongs smallint, songsdur time);
CREATE TABLE Genre(nam varchar(50) PRIMARY KEY, noartsbands smallint, nosongs smallint, songsdur time);
CREATE TABLE `Music artist/band`(ID smallint PRIMARY KEY, artband varchar(100), genr varchar(50) NULL, nosongs smallint, totnosongs smallint, songsdur time, totsongsdur time, cat varchar(15), FOREIGN KEY (cat) REFERENCES `Audio library`(cat), FOREIGN KEY (genr) REFERENCES Genre(nam));
CREATE TABLE `Related music artist/band`(ID smallint PRIMARY KEY, relartband varchar(100), artband smallint, nosongs tinyint, songsdur time, FOREIGN KEY (artband) REFERENCES `Music artist/band`(ID));
CREATE TABLE Song(ID int PRIMARY KEY, nam varchar(150), dur time, cat varchar(15) NULL, FOREIGN KEY (cat) REFERENCES `Audio library`(cat));
CREATE TABLE `Music artist/band's song`(song int, artband smallint, feat varchar(100) NULL, FOREIGN KEY (song) REFERENCES Song(ID) ON DELETE CASCADE, FOREIGN KEY (artband) REFERENCES `Music artist/band`(ID), FOREIGN KEY (artband) REFERENCES `Related music artist/band`(ID));
CREATE TABLE `Cover's original music artist/band`(song int, artband smallint, feat varchar(100) NULL, FOREIGN KEY (song) REFERENCES Song(ID) ON DELETE CASCADE, FOREIGN KEY (artband) REFERENCES `Music artist/band`(ID), FOREIGN KEY (artband) REFERENCES `Related music artist/band`(ID));
CREATE TABLE Favourites(num tinyint PRIMARY KEY, artband smallint, FOREIGN KEY (artband) REFERENCES `Music artist/band`(ID));
CREATE TABLE Soundtrack(ID smallint PRIMARY KEY, movanimsergam varchar(100), artband varchar(150), song varchar(250), nosongs smallint, songsdur time, cat varchar(15), FOREIGN KEY (cat) REFERENCES `Audio library`(cat));
DELIMITER $
CREATE TRIGGER MusicArtistBandIDBEFOREINSERT BEFORE INSERT ON `Music artist/band` FOR EACH ROW
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
CREATE TRIGGER RelatedMusicArtistBandIDBEFOREINSERT BEFORE INSERT ON `Related music artist/band` FOR EACH ROW
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
CREATE TRIGGER SongIDBEFOREINSERT BEFORE INSERT ON Song FOR EACH ROW
BEGIN
SET @songid=(SELECT MAX(ID) FROM Song);
IF @songid IS NULL THEN
SET @songid=0;
END IF;
SET NEW.ID=@songid+1;
END$
CREATE TRIGGER SoundtrackIDBEFOREINSERT BEFORE INSERT ON Soundtrack FOR EACH ROW
BEGIN
SET @soundtrackID=(SELECT MAX(ID) FROM Soundtrack);
IF @soundtrackID IS NULL THEN
SET @soundtrackID=0;
END IF;
SET NEW.ID=@soundtrackID+1;
END$
CREATE TRIGGER SongsCountandDurationAFTERINSERT AFTER INSERT ON `Music artist/band's song` FOR EACH ROW
BEGIN
SET @relartbandnosongs=(SELECT SUM(nosongs) FROM `Related music artist/band` WHERE artband=NEW.artband);
SET @relartbandsongsdur=(SELECT SUM(songsdur) FROM `Related music artist/band` WHERE artband=NEW.artband);
SET @nocovers=(SELECT COUNT(ID) FROM Song WHERE cat='Каверы');
SET @coversdur=(SELECT SUM(dur) FROM Song WHERE cat='Каверы');
IF @relartbandnosongs IS NULL THEN
SET @relartbandnosongs=0;
END IF;
IF @relartbandsongsdur IS NULL THEN
SET @relartbandsongsdur='00:00:00';
END IF;
IF (SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband)!='Каверы' THEN
SET @nocovers=0;
SET @coversdur=0;
END IF;
UPDATE `Related music artist/band` SET nosongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')), songsdur=(SELECT SUM(dur) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'))) WHERE ID=NEW.artband;
UPDATE `Music artist/band` SET nosongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')), songsdur=(SELECT SUM(dur) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'))), totnosongs=nosongs+@relartbandnosongs, totsongsdur=songsdur+@relartbandsongsdur WHERE ID=NEW.artband;
UPDATE Genre SET nosongs=(SELECT SUM(totnosongs) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.artband)), songsdur=(SELECT SUM(totsongsdur) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.artband)) WHERE nam=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.artband);
UPDATE `Audio library` SET nosongs=(SELECT totnosongs FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband))+@nocovers, songsdur=(SELECT totsongsdur FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband))+@coversdur WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband);
END$
CREATE TRIGGER SongsCountandDurationAFTERUPDATE AFTER UPDATE ON `Music artist/band's song` FOR EACH ROW
BEGIN
SET @relartbandnosongs=(SELECT SUM(nosongs) FROM `Related music artist/band` WHERE artband=NEW.artband);
SET @relartbandsongsdur=(SELECT SUM(songsdur) FROM `Related music artist/band` WHERE artband=NEW.artband);
SET @nocovers=(SELECT COUNT(ID) FROM Song WHERE cat='Каверы');
SET @coversdur=(SELECT SUM(dur) FROM Song WHERE cat='Каверы');
IF @relartbandnosongs IS NULL THEN
SET @relartbandnosongs=0;
END IF;
IF @relartbandsongsdur IS NULL THEN
SET @relartbandsongsdur='00:00:00';
END IF;
IF (SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband)!='Каверы' THEN
SET @nocovers=0;
SET @coversdur=0;
END IF;
UPDATE `Related music artist/band` SET nosongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')), songsdur=(SELECT SUM(dur) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'))) WHERE ID=NEW.artband;
UPDATE `Music artist/band` SET nosongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')), songsdur=(SELECT SUM(dur) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=NEW.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'))), totnosongs=nosongs+@relartbandnosongs, totsongsdur=songsdur+@relartbandsongsdur WHERE ID=NEW.artband;
UPDATE Genre SET nosongs=(SELECT SUM(totnosongs) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.artband)), songsdur=(SELECT SUM(totsongsdur) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.artband)) WHERE nam=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.artband);
UPDATE `Audio library` SET nosongs=(SELECT totnosongs FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband))+@nocovers, songsdur=(SELECT totsongsdur FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband))+@coversdur WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.artband);
END$
CREATE TRIGGER SongsCountandDurationAFTERDELETE AFTER DELETE ON `Music artist/band's song` FOR EACH ROW
BEGIN
SET @relartbandnosongs=(SELECT SUM(nosongs) FROM `Related music artist/band` WHERE artband=OLD.artband);
SET @relartbandsongsdur=(SELECT SUM(songsdur) FROM `Related music artist/band` WHERE artband=OLD.artband);
SET @nocovers=(SELECT COUNT(ID) FROM Song WHERE cat='Каверы');
SET @coversdur=(SELECT SUM(dur) FROM Song WHERE cat='Каверы');
IF @relartbandnosongs IS NULL THEN
SET @relartbandnosongs=0;
END IF;
IF @relartbandsongsdur IS NULL THEN
SET @relartbandsongsdur='00:00:00';
END IF;
IF (SELECT cat FROM `Music artist/band` WHERE ID=OLD.artband)!='Каверы' THEN
SET @nocovers=0;
SET @coversdur=0;
END IF;
UPDATE `Related music artist/band` SET nosongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=OLD.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')), songsdur=(SELECT SUM(dur) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=OLD.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'))) WHERE ID=OLD.artband;
UPDATE `Music artist/band` SET nosongs=(SELECT COUNT(song) FROM `Music artist/band's song` WHERE artband=OLD.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы')), songsdur=(SELECT SUM(dur) FROM Song WHERE ID IN(SELECT song FROM `Music artist/band's song` WHERE artband=OLD.artband AND song NOT IN(SELECT ID FROM Song WHERE cat='Каверы'))), totnosongs=nosongs+@relartbandnosongs, totsongsdur=songsdur+@relartbandsongsdur WHERE ID=OLD.artband;
UPDATE Genre SET nosongs=(SELECT SUM(totnosongs) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=OLD.artband)), songsdur=(SELECT SUM(totsongsdur) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=OLD.artband)) WHERE nam=(SELECT genr FROM `Music artist/band` WHERE ID=OLD.artband);
UPDATE `Audio library` SET nosongs=(SELECT totnosongs FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=OLD.artband))+@nocovers, songsdur=(SELECT totsongsdur FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=OLD.artband))+@coversdur WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=OLD.artband);
END$
CREATE TRIGGER ArtistsBandsCountAFTERINSERT AFTER INSERT ON `Music artist/band` FOR EACH ROW
BEGIN
SET @norelartsbands=(SELECT COUNT(ID) FROM `Related music artist/band` WHERE artband=NEW.ID);
IF @norelartsbands IS NULL THEN
SET @norelartsbands=0;
END IF;
UPDATE Genre SET noartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.ID)) + @norelartsbands WHERE nam=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.ID);
UPDATE `Audio library` SET noorigartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.ID)) + @norelartsbands WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.ID);
END$
CREATE TRIGGER ArtistsBandsCountAFTERUPDATE AFTER UPDATE ON `Music artist/band` FOR EACH ROW
BEGIN
SET @norelartsbands=(SELECT COUNT(ID) FROM `Related music artist/band` WHERE artband=NEW.ID);
IF @norelartsbands IS NULL THEN
SET @norelartsbands=0;
END IF;
UPDATE Genre SET noartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.ID)) + @norelartsbands WHERE nam=(SELECT genr FROM `Music artist/band` WHERE ID=NEW.ID);
UPDATE `Audio library` SET noorigartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.ID)) + @norelartsbands WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=NEW.ID);
END$
CREATE TRIGGER ArtistsBandsCountAFTERDELETE AFTER DELETE ON `Music artist/band` FOR EACH ROW
BEGIN
SET @norelartsbands=(SELECT COUNT(ID) FROM `Related music artist/band` WHERE artband=OLD.ID);
IF @norelartsbands IS NULL THEN
SET @norelartsbands=0;
END IF;
UPDATE Genre SET noartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE genr=(SELECT genr FROM `Music artist/band` WHERE ID=OLD.ID)) + @norelartsbands WHERE nam=(SELECT genr FROM `Music artist/band` WHERE ID=OLD.ID);
UPDATE `Audio library` SET noorigartsbands=(SELECT COUNT(ID) FROM `Music artist/band` WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=OLD.ID)) + @norelartsbands WHERE cat=(SELECT cat FROM `Music artist/band` WHERE ID=OLD.ID);
END$
DELIMITER ;
CREATE TRIGGER SoundtracksCountandDurationAFTERINSERT AFTER INSERT ON Soundtrack FOR EACH ROW
UPDATE `Audio library` SET noorigartsbands=0, nosongs=(SELECT SUM(nosongs) FROM Soundtrack), songsdur=(SELECT SUM(songsdur) FROM Soundtrack) WHERE cat='Саундтреки';
CREATE TRIGGER SoundtracksCountandDurationAFTERUPDATE AFTER UPDATE ON Soundtrack FOR EACH ROW
UPDATE `Audio library` SET noorigartsbands=0, nosongs=(SELECT SUM(nosongs) FROM Soundtrack), songsdur=(SELECT SUM(songsdur) FROM Soundtrack) WHERE cat='Саундтреки';
CREATE TRIGGER SoundtracksCountandDurationAFTERDELETE AFTER DELETE ON Soundtrack FOR EACH ROW
UPDATE `Audio library` SET noorigartsbands=0, nosongs=(SELECT SUM(nosongs) FROM Soundtrack), songsdur=(SELECT SUM(songsdur) FROM Soundtrack) WHERE cat='Саундтреки';
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
