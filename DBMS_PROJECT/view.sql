-- B�t�n Turnuvalar Dahil Oyuncu Mac Say�s�n� Tutan View --
IF OBJECT_ID('dbo.OyuncuMacSayisi') IS NOT NULL
BEGIN
DROP VIEW OyuncuMacSayisi
END
GO

CREATE VIEW OyuncuMacSayisi
AS
SELECT CONCAT(O.�sim , ' ', O.Soyisim) AS Oyuncular, COUNT(O.�sim) AS MAC_SAYISI FROM Sonu� S 
Inner Join Maclar M on M.[Sonu� ID] = S.[Sonu� ID] 
Inner Join Oyuncu O on O.[Oyuncu ID] = S.Kazanan or O.[Oyuncu ID] =S.Kaybeden GROUP BY O.�sim,O.Soyisim


-- Okullar�n Toplam Kazand�klar� Ma� View ile G�sterme --
Select Ok.[Okul Ad�], COUNT(MAC_SAYISI) AS KAZANILAN_MAC_SAYISI FROM Okul Ok inner join Oyuncu O on O.[Okul ID] = Ok.[Okul ID] inner join OyuncuMacSayisi V on V.Oyuncular = CONCAT(O.�sim , ' ', O.Soyisim) 
inner Join Sonu� S on S.Kazanan = O.[Oyuncu ID] GROUP BY Ok.[Okul Ad�] ORDER BY KAZANILAN_MAC_SAYISI DESC