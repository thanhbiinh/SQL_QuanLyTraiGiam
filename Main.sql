CREATE DATABASE QUAN_LY_NHA_GIAM;
GO

USE QUAN_LY_NHA_GIAM;
GO
CREATE TABLE NHA_GIAM (
    MaNhaGiam  VARCHAR (10)   PRIMARY KEY,
    TenNhaGiam NVARCHAR (100) NOT NULL      
);

CREATE TABLE PHONG_GIAM (
    MaPhong   VARCHAR (10)  PRIMARY KEY,
    MaNhaGiam VARCHAR (10)  NOT NULL,
    TenPhong  NVARCHAR (50) NOT NULL,
    SucChua   INT          ,
    LoaiPhong NVARCHAR (20),
    FOREIGN KEY (MaNhaGiam) REFERENCES NHA_GIAM (MaNhaGiam)
);

CREATE TABLE TU_NHAN (
    MaTuNhan  VARCHAR (10)   PRIMARY KEY,
    HoTen     NVARCHAR (100) NOT NULL,
    NgaySinh  DATE          ,
    GioiTinh  NVARCHAR (10) ,
    DiaChi    NVARCHAR (200),
    NgayVaoTu DATE          ,
    MaPhong   VARCHAR (10)  ,
    FOREIGN KEY (MaPhong) REFERENCES PHONG_GIAM (MaPhong)
);

CREATE TABLE CAN_BO (
    MaCanBo  VARCHAR (10)   PRIMARY KEY,
    HoTen    NVARCHAR (100) NOT NULL,
    NgaySinh DATE          ,
    GioiTinh NVARCHAR (10) ,
    ChucVu   NVARCHAR (50) ,
    SDT      VARCHAR (15)   UNIQUE,
    MaPhong  VARCHAR (10)  ,
    FOREIGN KEY (MaPhong) REFERENCES PHONG_GIAM (MaPhong)
);

CREATE TABLE TOI_DANH (
    MaToiDanh   VARCHAR (10)   PRIMARY KEY,
    TenToiDanh  NVARCHAR (100) NOT NULL,
    LoaiToiDanh NVARCHAR (100),
    DieuLuat    NVARCHAR (50) ,
    Khoan       NVARCHAR (50)
);

CREATE TABLE BAN_AN (
    MaBanAn   VARCHAR (10)   PRIMARY KEY,
    MaTuNhan  VARCHAR (10)   NOT NULL,
    MucPhat   NVARCHAR (200),
    ThoiHanTu INT           ,
    NgayXetXu DATE          ,
    FOREIGN KEY (MaTuNhan) REFERENCES TU_NHAN (MaTuNhan)
);

CREATE TABLE CHI_TIET_BAN_AN (
    MaBanAn   VARCHAR (10),
    MaToiDanh VARCHAR (10),
    PRIMARY KEY (MaBanAn, MaToiDanh),
    FOREIGN KEY (MaBanAn)   REFERENCES BAN_AN (MaBanAn),
    FOREIGN KEY (MaToiDanh) REFERENCES TOI_DANH (MaToiDanh)
);

CREATE TABLE NGUOI_THAN (
    MaTuNhan    VARCHAR (10)  ,
    MaNguoiThan VARCHAR (10)  ,
    HoTen       NVARCHAR (100) NOT NULL,
    NgaySinh    DATE          ,
    SDT         VARCHAR (15)  ,
    DiaChi      NVARCHAR (200),
    QuanHe      NVARCHAR (200),
    PRIMARY KEY (MaTuNhan, MaNguoiThan),
    FOREIGN KEY (MaTuNhan) REFERENCES TU_NHAN (MaTuNhan)
);

CREATE TABLE LUOT_THAM (
    MaTham      VARCHAR (10)   PRIMARY KEY,
    MaTuNhan    VARCHAR (10)   NOT NULL,
    MaNguoiThan VARCHAR (10)   NOT NULL,
    NgayTham    DATE           NOT NULL,
    GioTham     TIME          ,
    NoiDung     NVARCHAR (200),
    FOREIGN KEY (MaTuNhan, MaNguoiThan) REFERENCES NGUOI_THAN (MaTuNhan, MaNguoiThan)
);

CREATE TABLE KHEN_THUONG (
    MaKhenThuong   VARCHAR (10)   PRIMARY KEY,
    MaTuNhan       VARCHAR (10)   NOT NULL,
    NgayKhenThuong DATE           NOT NULL,
    LyDo           NVARCHAR (200),
    HinhThuc       NVARCHAR (100),
    FOREIGN KEY (MaTuNhan) REFERENCES TU_NHAN (MaTuNhan)
);

CREATE TABLE KY_LUAT (
    MaKyLuat   VARCHAR (10)   PRIMARY KEY,
    MaTuNhan   VARCHAR (10)   NOT NULL,
    NgayKyLuat DATE           NOT NULL,
    LyDo       NVARCHAR (200),
    HinhThuc   NVARCHAR (100),
    FOREIGN KEY (MaTuNhan) REFERENCES TU_NHAN (MaTuNhan)
);


-- Tao Index
CREATE INDEX IX_BAN_AN_MaTuNhan ON BAN_AN (MaTuNhan);
CREATE INDEX IX_TU_NHAN_HoTen   ON TU_NHAN (HoTen);
CREATE INDEX IX_CAN_BO_HoTen ON CAN_BO (HoTen);


--Đếm số sức chứa của 1 nhà giam
GO
CREATE VIEW SUC_CHUA_NHA_GIAM AS
SELECT 
    N.MaNhaGiam,
    N.TenNhaGiam,
    SUM(P.SucChua) AS SucChua
FROM NHA_GIAM N
LEFT JOIN PHONG_GIAM P
    ON N.MaNhaGiam = P.MaNhaGiam    
GROUP BY N.MaNhaGiam, N.TenNhaGiam;


--Thống kê tội danh
GO
CREATE VIEW THONG_KE_TOI_DANH AS
SELECT
    TD.MaToiDanh,
    TD.TenToiDanh,
    TD.LoaiToiDanh,
    TD.DieuLuat,
    COUNT(DISTINCT CT.MaBanAn) AS SoBanAn,
    COUNT(DISTINCT BA.MaTuNhan) AS SoTuNhan
FROM TOI_DANH TD
LEFT JOIN CHI_TIET_BAN_AN CT
    ON TD.MaToiDanh = CT.MaToiDanh
LEFT JOIN BAN_AN BA
    ON CT.MaBanAn = BA.MaBanAn
GROUP BY
    TD.MaToiDanh,
    TD.TenToiDanh,
    TD.LoaiToiDanh,
    TD.DieuLuat;
GO


--Tính tổng thời hạn tù của một tù nhân
GO
CREATE PROCEDURE sp_TongThoiHanTu
    @MaTuNhan    VARCHAR(10),
    @TongThangTu INT OUTPUT
AS
BEGIN
    SELECT @TongThangTu = ISNULL(SUM(ThoiHanTu), 0)
    FROM BAN_AN
    WHERE MaTuNhan = @MaTuNhan;
END;
GO
--Test
DECLARE @ma VARCHAR(10) = 'TN001', @thang INT;
EXEC sp_TongThoiHanTu @MaTuNhan = @ma, @TongThangTu = @thang OUTPUT;
SELECT @ma AS MaTuNhan, @thang AS TongThangTu;

--Đếm số lượt thăm của một tù nhân theo mã tù nhân
GO
CREATE PROCEDURE sp_DemLuotThamTheoTuNhan
    @MaTuNhan   VARCHAR(10),     -- input
    @SoLuotTham INT OUTPUT       -- output
AS
BEGIN
    SELECT @SoLuotTham = COUNT(*)
    FROM LUOT_THAM
    WHERE MaTuNhan = @MaTuNhan;
END;
GO
--Test
DECLARE @so INT;
EXEC sp_DemLuotThamTheoTuNhan @MaTuNhan = 'TN001', @SoLuotTham = @so OUTPUT;
SELECT 'TN001' AS MaTuNhan, @so AS SoLuotTham;

--Trigger
GO
CREATE OR ALTER TRIGGER TRG_KIEM_TRA_SUC_CHUA
ON TU_NHAN
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM PHONG_GIAM P
        WHERE P.MaPhong IN (SELECT MaPhong FROM inserted WHERE MaPhong IS NOT NULL)
          AND (SELECT COUNT(*) FROM TU_NHAN TN WHERE TN.MaPhong = P.MaPhong) > P.SucChua
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, N'Phòng giam đã vượt quá sức chứa!', 1;
    END
END;
GO
-- Test
INSERT INTO TU_NHAN (MaTuNhan, HoTen, MaPhong)
VALUES ('TN999', N'Nguyễn Văn A', 'P01');


-- 1. Lấy danh sách tất cả tù nhân đang chấp hành án
SELECT MaTuNhan, HoTen, NgaySinh, GioiTinh, DiaChi, NgayVaoTu, MaPhong
FROM TU_NHAN;


-- 2. Thống kê số lượng tù nhân trong từng phòng giam
SELECT P.MaPhong, P.TenPhong, P.SucChua, COUNT(T.MaTuNhan) AS SoLuongHienTai
FROM PHONG_GIAM P
LEFT JOIN TU_NHAN T ON P.MaPhong = T.MaPhong
GROUP BY P.MaPhong, P.TenPhong, P.SucChua;


-- 3. Tìm các phòng giam đã đạt sức chứa tối đa
SELECT P.MaPhong, P.TenPhong, P.SucChua, COUNT(T.MaTuNhan) AS SoLuongHienTai
FROM PHONG_GIAM P
JOIN TU_NHAN T ON P.MaPhong = T.MaPhong
GROUP BY P.MaPhong, P.TenPhong, P.SucChua
HAVING COUNT(T.MaTuNhan) = P.SucChua;


-- 4. Liệt kê bản án và tội danh tương ứng của từng tù nhân
SELECT T.MaTuNhan, T.HoTen, B.MaBanAn, B.ThoiHanTu, TD.TenToiDanh, TD.LoaiToiDanh
FROM TU_NHAN T
JOIN BAN_AN B ON T.MaTuNhan = B.MaTuNhan
JOIN CHI_TIET_BAN_AN CT ON B.MaBanAn = CT.MaBanAn
JOIN TOI_DANH TD ON CT.MaToiDanh = TD.MaToiDanh;


-- 5. Lấy danh sách tù nhân phạm tội thuộc nhóm Ma túy
SELECT DISTINCT T.MaTuNhan, T.HoTen, TD.TenToiDanh, TD.LoaiToiDanh
FROM TU_NHAN T
JOIN BAN_AN B ON T.MaTuNhan = B.MaTuNhan
JOIN CHI_TIET_BAN_AN CT ON B.MaBanAn = CT.MaBanAn
JOIN TOI_DANH TD ON CT.MaToiDanh = TD.MaToiDanh
WHERE TD.LoaiToiDanh = N'Ma túy';


-- 6. Đếm số lần khen thưởng và kỷ luật của từng tù nhân
SELECT T.MaTuNhan, T.HoTen,
       COUNT(DISTINCT KT.MaKhenThuong) AS SoLanKhenThuong,
       COUNT(DISTINCT KL.MaKyLuat) AS SoLanKyLuat
FROM TU_NHAN T
LEFT JOIN KHEN_THUONG KT ON T.MaTuNhan = KT.MaTuNhan
LEFT JOIN KY_LUAT KL ON T.MaTuNhan = KL.MaTuNhan
GROUP BY T.MaTuNhan, T.HoTen;


-- 7. Tìm Top 5 tù nhân có nhiều lượt thăm nhất
SELECT TOP 5 T.MaTuNhan, T.HoTen, COUNT(L.MaTham) AS SoLuotTham
FROM TU_NHAN T
JOIN LUOT_THAM L ON T.MaTuNhan = L.MaTuNhan
GROUP BY T.MaTuNhan, T.HoTen
ORDER BY SoLuotTham DESC;


-- 8. Lấy danh sách cán bộ phụ trách phòng giam và số lượng tù nhân
SELECT CB.MaCanBo, CB.HoTen AS TenCanBo, CB.ChucVu, P.TenPhong,
       COUNT(T.MaTuNhan) AS SoTuNhanQuanLy
FROM CAN_BO CB
JOIN PHONG_GIAM P ON CB.MaPhong = P.MaPhong
LEFT JOIN TU_NHAN T ON P.MaPhong = T.MaPhong
GROUP BY CB.MaCanBo, CB.HoTen, CB.ChucVu, P.TenPhong;


-- 9. Thống kê số lượt vi phạm theo từng nhóm tội danh
SELECT TD.LoaiToiDanh, COUNT(CT.MaBanAn) AS SoLuotViPham
FROM TOI_DANH TD
JOIN CHI_TIET_BAN_AN CT ON TD.MaToiDanh = CT.MaToiDanh
GROUP BY TD.LoaiToiDanh
ORDER BY SoLuotViPham DESC;


-- 10. Tìm Top 10 tù nhân có thời hạn án phạt tù dài nhất
SELECT TOP 10 T.MaTuNhan, T.HoTen, B.ThoiHanTu AS SoThangTu,
       B.MucPhat, B.NgayXetXu
FROM TU_NHAN T
JOIN BAN_AN B ON T.MaTuNhan = B.MaTuNhan
ORDER BY B.ThoiHanTu DESC;




