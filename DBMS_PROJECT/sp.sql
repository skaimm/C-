-- SP OBJECT KONTROL
IF OBJECT_ID('dbo.INSERT_SP') IS NOT NULL
BEGIN
DROP PROC INSERT_SP
END
GO

-- Okul Tablosuna Yeni Veri Ekleme
CREATE PROC INSERT_SP
(
@OkulID int,
@OkulAdi nvarchar(50),
@OKulun�ehri nvarchar(50),
@Takim�smi nvarchar(10)
)
AS
-- ID ye ait verinin var olup Olmad���n� kontrol et
IF EXISTS(SELECT * FROM Okul WHERE  [Okul ID]=@OkulID)
BEGIN
PRINT 'ID numaras�na ait Veri Zaten Mevcut!'
END
-- ID ye ait veri yoksa Yeni Ekle
ELSE
BEGIN
INSERT INTO Okul([Okul ID],[Okul Ad�],�ehir,[Tak�m �smi]) VALUES (@OkulID,@OkulAdi,
@OKulun�ehri,@Takim�smi)
PRINT 'Yeni Veri Olu�turuldu.!'
END

-- SP OBJECT KONTROL
IF OBJECT_ID('dbo.DELETE_SP') IS NOT NULL
BEGIN
DROP PROC DELETE_SP
END
GO

-- Okul Tablosundan Veri Silme
CREATE PROC DELETE_SP
(
@OkulID int
)
AS
-- ID ye ait verinin var olup Olmad���n� kontrol et
IF NOT EXISTS(SELECT * FROM Okul WHERE  [Okul ID]=@OkulID)
BEGIN
	PRINT 'ID numaras�na ait Veri Bulumad�!'
END
-- ID ye ait varsa Sil
ELSE
BEGIN
-- TRANCTION ile Okulu Temsil Eden ��renci Varsa Okul Silme ��lemini Geri Alma
	BEGIN TRAN
	DECLARE @i int
	SELECT @i = COUNT(O.[Okul ID]) FROM Oyuncu O WHERE O.[Okul ID]=@OkulID;
	DELETE FROM Okul WHERE [Okul ID] = @OkulID
	IF @i=0
	BEGIN 
		PRINT 'ID numaras�na ait Veri Silindi.!'
		COMMIT
	END
	ELSE
	BEGIN 
		PRINT 'Okulu Temsil Eden Oyuncu Oldu�u i�in Silinemez. �nce Oyuncu Verilerini Silmeniz Gerekli.'
		ROLLBACK
	END
END

-- SP OBJECT KONTROL
IF OBJECT_ID('dbo.UPDATE_SP') IS NOT NULL
BEGIN
DROP PROC UPDATE_SP
END
GO

-- Okul Tablosunda ki Veriyi G�ncelleme
CREATE PROC UPDATE_SP
(
@OkulID int,
@OkulAdi nvarchar(50),
@OKulun�ehri nvarchar(50),
@Takim�smi nvarchar(10)
)
AS
-- ID ye ait verinin var olup Olmad���n� kontrol et
IF NOT EXISTS(SELECT * FROM Okul WHERE  [Okul ID]=@OkulID)
BEGIN
PRINT 'ID numaras�na ait Veri Bulumad�!'
END
ELSE
BEGIN
-- ID ye ait veri varsa G�ncelle
UPDATE Okul SET  
[Okul Ad�] = @OkulAdi, �ehir = @OKulun�ehri, [Tak�m �smi] = @Takim�smi
WHERE [Okul ID] = @OkulID  
PRINT 'ID numaras�na ait Veri G�ncellendi.!'
END


-- SP CURSOR OBJECT KONTROL
IF OBJECT_ID('dbo.CURSOR_SP') IS NOT NULL
BEGIN
DROP PROC CURSOR_SP
END
GO

-- CURSOR kullanarak Tabloya INSERT i�lemi
CREATE PROC CURSOR_SP
(
@okID int
)
AS
BEGIN
    DECLARE @Sayac INT
    SET @Sayac = 1

    DECLARE @oyID INT
	DECLARE @AdSoyad VARCHAR(50)
	DECLARE @Yil INT
    DECLARE OyuncuCursor CURSOR FOR
        SELECT [Oyuncu ID], �sim +' ' + Soyisim, YEAR([Do�um Tarihi])
        FROM Oyuncu Where [Okul ID] = @okID

    OPEN OyuncuCursor

    FETCH NEXT FROM OyuncuCursor INTO @oyID ,@AdSoyad,@Yil

    WHILE @@FETCH_STATUS = 0
    BEGIN
		PRINT '----------------------------------------------------------------------'
        PRINT CONVERT(VARCHAR,@oyID)+ ' - ' + @AdSoyad + ' - ' + CONVERT(VARCHAR,@Yil)
		PRINT '----------------------------------------------------------------------'
        FETCH NEXT FROM OyuncuCursor INTO @oyID ,@AdSoyad,@Yil
    END

    CLOSE OyuncuCursor
    DEALLOCATE OyuncuCursor
END
GO

-- SP OBJECT KONTROL
IF OBJECT_ID('dbo.SELECT_SP') IS NOT NULL
BEGIN
DROP PROC SELECT_SP
END
GO

-- Girilen Oyuncu ID siyle, Oyuncunun ToplamMac S�resini Dakika Olarak Getirir
CREATE PROC SELECT_SP
(
@OyuncuID int
)
AS
BEGIN
-- ID ye ait veri varsa G�ncelle
SELECT CONCAT(O.�sim , ' ', O.Soyisim) AS AD_SOYAD ,SUM(DATEDIFF(MINUTE, '0:00:00',M.[Ma� S�resi])) AS OYNADI�I_DAK�KA FROM Maclar M 
INNER JOIN Sonu� S on M.[Sonu� ID] = s.[Sonu� ID] 
INNER JOIN Oyuncu O on O.[Oyuncu ID] = S.Kaybeden or O.[Oyuncu ID] = S.Kazanan
WHERE O.[Oyuncu ID] = @OyuncuID GROUP BY O.�sim,O.Soyisim
END

----------------------------------
--- STORED PROCEDURE TESTLERI ----
----------------------------------
 
set identity_insert OKUL on
-- TEST INSERT_SP // 9 eyl�l �niversitesini Ekle
EXEC dbo.INSERT_SP 15,'9 Eyl�l �ni','�zmr',''
-- TEST DELETE_SP // 9 eyl�l �niversitesini Sil
EXEC dbo.DELETE_SP 15
-- TEST UPDATE_SP // 9 Eyl�l Bilgilerini D�zelt
EXEC dbo.UPDATE_SP 15,'9 Eyl�l �niversitesi','�zmir','9EST'
-- TEST CURSOR_SP 
EXEC dbo.CURSOR_SP 11
-- TEST SELECT_SP
EXEC dbo.SELECT_SP 19



---------------------------------------------------------------------------------------------------------
------------------------------------------ TRIGGER ------------------------------------------------------
-- Yeni Bir Okul Eklendi�inde Tetiklenen ve OKulun Tak�m isminin Bo� olmas� durumunda dolduran Trigger --
---------------------------------------------------------------------------------------------------------

-- TRIGGER OBJECT KONTROL
IF OBJECT_ID('dbo.TRIGGER_SP') IS NOT NULL
BEGIN
DROP TRIGGER TRIGGER_SP
END
GO

CREATE TRIGGER TRIGGER_SP ON OKUL
AFTER INSERT
AS
	DECLARE @OKULID AS INT;
	DECLARE @AD AS VARCHAR(50);
	DECLARE @SEHIR AS VARCHAR(50);
	DECLARE @TAKIMISMI AS VARCHAR(50);
BEGIN
	SELECT @OKULID = I.[Okul ID] FROM inserted I;
	SELECT @AD = I.[Okul Ad�] FROM inserted I;
	SELECT @SEHIR = I.�ehir FROM inserted I;
	SELECT @TAKIMISMI = I.[Tak�m �smi] FROM inserted I;

	IF @TAKIMISMI = '' 
		BEGIN
			DELETE FROM Oyuncu WHERE Oyuncu.[Okul ID] = @OKULID;  
			EXEC dbo.UPDATE_SP @OKULID,@AD,@SEHIR,'YOK'
			PRINT 'Bo� Girilen Tak�m �smi YOK olarak G�ncellendi' 
		END; 
END



------------------------------------------
-------- NONCLUSTERED INDEX TEST ---------
------------------------------------------

DROP INDEX Maclar.idx_Mac

CREATE NONCLUSTERED INDEX idx_Mac ON Maclar([Ma� Tarihi])
WITH (PAD_INDEX = ON , FILLFACTOR = 90, DROP_EXISTING=OFF)

SET STATISTICS IO ON

SELECT * FROM Maclar WHERE [Ma� Tarihi] >'2018-04-10' ORDER BY [Ma� Tarihi] 



