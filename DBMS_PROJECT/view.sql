-- Bütün Turnuvalar Dahil Oyuncu Mac Sayýsýný Tutan View --
IF OBJECT_ID('dbo.OyuncuMacSayisi') IS NOT NULL
BEGIN
DROP VIEW OyuncuMacSayisi
END
GO

CREATE VIEW OyuncuMacSayisi
AS
SELECT CONCAT(O.Ýsim , ' ', O.Soyisim) AS Oyuncular, COUNT(O.Ýsim) AS MAC_SAYISI FROM Sonuç S 
Inner Join Maclar M on M.[Sonuç ID] = S.[Sonuç ID] 
Inner Join Oyuncu O on O.[Oyuncu ID] = S.Kazanan or O.[Oyuncu ID] =S.Kaybeden GROUP BY O.Ýsim,O.Soyisim


-- Okullarýn Toplam Kazandýklarý Maç View ile Gösterme --
Select Ok.[Okul Adý], COUNT(MAC_SAYISI) AS KAZANILAN_MAC_SAYISI FROM Okul Ok inner join Oyuncu O on O.[Okul ID] = Ok.[Okul ID] inner join OyuncuMacSayisi V on V.Oyuncular = CONCAT(O.Ýsim , ' ', O.Soyisim) 
inner Join Sonuç S on S.Kazanan = O.[Oyuncu ID] GROUP BY Ok.[Okul Adý] ORDER BY KAZANILAN_MAC_SAYISI DESC