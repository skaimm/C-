-- OKulu Temsil eden Oyuncular�n �sim ve Soyismini G�steren Fonskiyon --
IF OBJECT_ID('dbo.Temsilcileri_Bul') IS NOT NULL
BEGIN
DROP FUNCTION Temsilcileri_Bul
END
GO

CREATE FUNCTION Temsilcileri_Bul (@okuladi VARCHAR(MAX))
RETURNS TABLE
AS
RETURN SELECT CONCAT(O.�sim , ' ', O.Soyisim) AS Temsilciler From Oyuncu O 
Inner join Okul Ok on O.[Okul ID] = Ok.[Okul ID] where Ok.[Okul Ad�] = @okuladi


SELECT * FROM dbo.Temsilcileri_Bul('Yalova �niversitesi')

