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
@OKulunÞehri nvarchar(50),
@TakimÝsmi nvarchar(10)
)
AS
-- ID ye ait verinin var olup Olmadýðýný kontrol et
IF EXISTS(SELECT * FROM Okul WHERE  [Okul ID]=@OkulID)
BEGIN
PRINT 'ID numarasýna ait Veri Zaten Mevcut!'
END
-- ID ye ait veri yoksa Yeni Ekle
ELSE
BEGIN
INSERT INTO Okul([Okul ID],[Okul Adý],Þehir,[Takým Ýsmi]) VALUES (@OkulID,@OkulAdi,
@OKulunÞehri,@TakimÝsmi)
PRINT 'Yeni Veri Oluþturuldu.!'
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
-- ID ye ait verinin var olup Olmadýðýný kontrol et
IF NOT EXISTS(SELECT * FROM Okul WHERE  [Okul ID]=@OkulID)
BEGIN
	PRINT 'ID numarasýna ait Veri Bulumadý!'
END
-- ID ye ait varsa Sil
ELSE
BEGIN
-- TRANCTION ile Okulu Temsil Eden Öðrenci Varsa Okul Silme Ýþlemini Geri Alma
	BEGIN TRAN
	DECLARE @i int
	SELECT @i = COUNT(O.[Okul ID]) FROM Oyuncu O WHERE O.[Okul ID]=@OkulID;
	DELETE FROM Okul WHERE [Okul ID] = @OkulID
	IF @i=0
	BEGIN 
		PRINT 'ID numarasýna ait Veri Silindi.!'
		COMMIT
	END
	ELSE
	BEGIN 
		PRINT 'Okulu Temsil Eden Oyuncu Olduðu için Silinemez. Önce Oyuncu Verilerini Silmeniz Gerekli.'
		ROLLBACK
	END
END

-- SP OBJECT KONTROL
IF OBJECT_ID('dbo.UPDATE_SP') IS NOT NULL
BEGIN
DROP PROC UPDATE_SP
END
GO

-- Okul Tablosunda ki Veriyi Güncelleme
CREATE PROC UPDATE_SP
(
@OkulID int,
@OkulAdi nvarchar(50),
@OKulunÞehri nvarchar(50),
@TakimÝsmi nvarchar(10)
)
AS
-- ID ye ait verinin var olup Olmadýðýný kontrol et
IF NOT EXISTS(SELECT * FROM Okul WHERE  [Okul ID]=@OkulID)
BEGIN
PRINT 'ID numarasýna ait Veri Bulumadý!'
END
ELSE
BEGIN
-- ID ye ait veri varsa Güncelle
UPDATE Okul SET  
[Okul Adý] = @OkulAdi, Þehir = @OKulunÞehri, [Takým Ýsmi] = @TakimÝsmi
WHERE [Okul ID] = @OkulID  
PRINT 'ID numarasýna ait Veri Güncellendi.!'
END


-- SP CURSOR OBJECT KONTROL
IF OBJECT_ID('dbo.CURSOR_SP') IS NOT NULL
BEGIN
DROP PROC CURSOR_SP
END
GO

-- CURSOR kullanarak Tabloya INSERT iþlemi
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
        SELECT [Oyuncu ID], Ýsim +' ' + Soyisim, YEAR([Doðum Tarihi])
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

-- Girilen Oyuncu ID siyle, Oyuncunun ToplamMac Süresini Dakika Olarak Getirir
CREATE PROC SELECT_SP
(
@OyuncuID int
)
AS
BEGIN
-- ID ye ait veri varsa Güncelle
SELECT CONCAT(O.Ýsim , ' ', O.Soyisim) AS AD_SOYAD ,SUM(DATEDIFF(MINUTE, '0:00:00',M.[Maç Süresi])) AS OYNADIÐI_DAKÝKA FROM Maclar M 
INNER JOIN Sonuç S on M.[Sonuç ID] = s.[Sonuç ID] 
INNER JOIN Oyuncu O on O.[Oyuncu ID] = S.Kaybeden or O.[Oyuncu ID] = S.Kazanan
WHERE O.[Oyuncu ID] = @OyuncuID GROUP BY O.Ýsim,O.Soyisim
END

----------------------------------
--- STORED PROCEDURE TESTLERI ----
----------------------------------
 
set identity_insert OKUL on
-- TEST INSERT_SP // 9 eylül üniversitesini Ekle
EXEC dbo.INSERT_SP 15,'9 Eylül Üni','Ýzmr',''
-- TEST DELETE_SP // 9 eylül üniversitesini Sil
EXEC dbo.DELETE_SP 15
-- TEST UPDATE_SP // 9 Eylül Bilgilerini Düzelt
EXEC dbo.UPDATE_SP 15,'9 Eylül Üniversitesi','Ýzmir','9EST'
-- TEST CURSOR_SP 
EXEC dbo.CURSOR_SP 11
-- TEST SELECT_SP
EXEC dbo.SELECT_SP 19



---------------------------------------------------------------------------------------------------------
------------------------------------------ TRIGGER ------------------------------------------------------
-- Yeni Bir Okul Eklendiðinde Tetiklenen ve OKulun Takým isminin Boþ olmasý durumunda dolduran Trigger --
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
	SELECT @AD = I.[Okul Adý] FROM inserted I;
	SELECT @SEHIR = I.Þehir FROM inserted I;
	SELECT @TAKIMISMI = I.[Takým Ýsmi] FROM inserted I;

	IF @TAKIMISMI = '' 
		BEGIN
			DELETE FROM Oyuncu WHERE Oyuncu.[Okul ID] = @OKULID;  
			EXEC dbo.UPDATE_SP @OKULID,@AD,@SEHIR,'YOK'
			PRINT 'Boþ Girilen Takým Ýsmi YOK olarak Güncellendi' 
		END; 
END



------------------------------------------
-------- NONCLUSTERED INDEX TEST ---------
------------------------------------------

DROP INDEX Maclar.idx_Mac

CREATE NONCLUSTERED INDEX idx_Mac ON Maclar([Maç Tarihi])
WITH (PAD_INDEX = ON , FILLFACTOR = 90, DROP_EXISTING=OFF)

SET STATISTICS IO ON

SELECT * FROM Maclar WHERE [Maç Tarihi] >'2018-04-10' ORDER BY [Maç Tarihi] 



