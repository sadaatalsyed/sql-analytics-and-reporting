USE [RetailDW]
GO
/****** Object:  StoredProcedure [dbo].[SA_SP_SalesDataDump]    Script Date: 7/14/2026 5:13:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SA_SP_SalesDataDump]
AS



DECLARE @DeliveryDateFrom AS DATE
DECLARE @DeliveryDateTo AS DATE

SET @DeliveryDateFrom =cast(DATEADD(MONTH,DATEDIFF(month,0,GETDATE()-1),0) AS DATE);
SET @DeliveryDateTo =cast(GETDATE()-1 AS DATE);


DELETE FROM SA_SalesDataDump WHERE
DeliveryDate >=@DeliveryDateFrom
AND DeliveryDate <=@DeliveryDateTo
BEGIN

INSERT INTO SA_SalesDataDump
(
	DistributionID,
	CustomerID,
	InvoiceDate,
	DeliveryDate,
	[Status],
	OrderBookerID,
	SalemanID,
	VanID,
	RouteName,
	InvoiceCode,
	OrderStartTime,
	OrderCompleteTime,
	Synchronized,
	Lattitude,
	Longitude,
	ProductID,
	TotalPiecesOrdered,
	TotalPiecesDelivered,
	FMRRate,
	FMRAmount,
	GSTRate,
	GSTValue,
	AdvanceTaxRate,
	AdvanceTaxValue,
	FurtherTaxRate,
	FurtherTaxValue,
	MRPRate,
	MRPValue,
	ConfectionaryTaxRate,
	ConfectionaryTaxValue,
	InvoicePriceCase,
	RetailPriceCase,
	ConsumerPriceCase,
	ValueWithoutTax,
	TotalTax,
	TotalValueWithTax,
	NetAmount,
	ToAmount,
	TradeOfferPercentageValue,
	TotalBillDiscount,
	OtherDiscount,
	FreeSKUQuantity,
	RentalDiscount,
	WholesaleDiscount,
	LoyaltyProgramDiscount,
	OffInvoiceDiscountA,
	[TradeOfferDiscount],
	OtherChannelDiscount,
	[OffInvoiceDiscountB],
    [VisibilityDiscount],
	[OffInvoiceDiscountC],
	BatchCode,
	[Type],
	DiscountValue,
	DiscountReversal
)

SELECT 
si.DistributionID,si.CustomerID,si.InvoiceDate,si.DeliveryDate,si.[Status]
,si.OrderBookerID,si.SalemanID,si.VanID,si.RouteName,si.InvoiceCode,
	OrderStartTime,
	OrderCompleteTime,
	Synchronized,
	si.Lattitude,
	si.Longitude
,sidw.ProductID
,sidw.TotalPiecesOrdered,sidw.TotalPiecesDelivered,sidw.FMRRate,sidw.FMRAmount
,sidw.GSTRate,sidw.GSTValue,sidw.AdvanceTaxRate,sidw.AdvanceTaxValue,sidw.FurtherTaxRate
,sidw.FurtherTaxValue,sidw.MRPRate,sidw.MRPValue,sidw.ConfectionaryTaxRate,sidw.ConfectionaryTaxValue
,sidw.InvoicePriceCase,sidw.RetailPriceCase,sidw.ConsumerPriceCase,sidw.ValueWithoutTax,sidw.TotalTax
,sidw.TotalValueWithTax,sidw.NetAmount
,isnull(sidw.TradeOfferAmount,0) AS 'TradeOfferAmount',isnull(sid1.TradeOfferPercentageValue,0) AS 'TradeOfferPercentageValue'
,isnull(c.TotalDiscount,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'TotalBillDiscount',Isnull(d.Discount,0) AS 'OtherDiscount'
,Isnull(d.FreeSKUQuantity,0)+isnull(c.FreeSKUQuantityTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'FreeSKUQuantity'
,Isnull(d.RentalDiscount,0)+isnull(c.RentalDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'RentalDiscount'
,Isnull(d.WholesaleDiscount,0)+isnull(c.WholesaleDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) as 'WholesaleDiscount'
,Isnull(d.LoyaltyProgramDiscount,0)+isnull(c.LoyaltyProgramDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) as 'LoyaltyProgramDiscount'
,Isnull(d.OffInvoiceDiscountA,0)+isnull(c.OffInvoiceDiscountATotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) as 'OffInvoiceDiscountA'
,Isnull(d.[TradeOfferDiscount],0)+isnull(c.TradeOfferDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'TradeOfferDiscount'
,Isnull(d.OtherChannelDiscount,0)+isnull(c.OtherChannelDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'OtherChannelDiscount'
,Isnull(d.OffInvoiceDiscountB,0)+isnull(c.OffInvoiceDiscountB,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'OffInvoiceDiscountB'
,Isnull(d.VisibilityDiscount,0)+isnull(c.VisibilityDiscount,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'VisibilityDiscount'
,Isnull(d.[OffInvoiceDiscountC],0)+isnull(c.[OffInvoiceDiscountC],0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0) AS 'OffInvoiceDiscountC'
,sidw.BatchCode,'Sales' AS 'Type',isnull(sid1.DiscountValue,0) AS DiscountValue,0 AS DiscountReversal
  FROM SaleInvoice AS si
INNER JOIN SaleInvoiceDetail AS sid1
ON sid1.SaleInvoiceID = si.SaleInvoiceID
INNER JOIN SaleInvoiceDetailWBC AS sidw
ON sidw.SaleInvoiceDetailID = sid1.SaleInvoiceDetailID

LEFT JOIN (SELECT sip.SaleInvoiceDetailID,SUM(sip.TotalDiscount) AS 'TotalDiscount',
			SUM(CASE WHEN t.Name = 'RentalDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'RentalDiscountTotal',
			SUM(CASE WHEN t.Name = 'WholesaleDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'WholesaleDiscountTotal',
			SUM(CASE WHEN t.Name = 'LoyaltyProgramDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'LoyaltyProgramDiscountTotal',
			SUM(CASE WHEN t.Name = 'OffInvoiceDiscountA' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountATotal', 
			SUM(CASE WHEN t.Name = 'TradeOfferDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'TradeOfferDiscountTotal',
			SUM(CASE WHEN t.Name = 'OtherChannelDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OtherChannelDiscountTotal'
			,SUM(isnull(sip.FreeSKUQuantity,0))AS 'FreeSKUQuantityTotal' 
			,SUM(CASE WHEN t.Name = 'VisibilityDiscount'  THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'VisibilityDiscount'   
            ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountB'    THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountB'
			 ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountC'    THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountC' 
           from SaleInvoicePromotion AS sip
			  INNER JOIN Promotion AS p
			  ON p.PromotionID = sip.PromotionID
              INNER JOIN Tags AS t
              ON t.TagID = p.TagID
	 GROUP BY sip.SaleInvoiceDetailID    
	) c
	ON c.SaleInvoiceDetailID = sid1.SaleInvoiceDetailID
	   left join (
    SELECT 
        SaleInvoiceDetailID,
        SUM(TotalPiecesDelivered) AS TotalPieces
    FROM SaleInvoiceDetailWBC
    GROUP BY SaleInvoiceDetailID
    having SUM(TotalPiecesDelivered)<>0) tp on tp.SaleInvoiceDetailID=sid1.SaleInvoiceDetailID

Left JOIN (select  SaleInvoiceDetailWBCID,
Sum(sidw2.TotalDiscount) AS 'Discount',
	SUM(CASE WHEN t.Name = 'RentalDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'RentalDiscount',
    SUM(CASE WHEN t.Name = 'WholesaleDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'WholesaleDiscount',
    SUM(CASE WHEN t.Name = 'LoyaltyProgramDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'LoyaltyProgramDiscount',
    SUM(CASE WHEN t.Name = 'OffInvoiceDiscountA' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountA',
    SUM(CASE WHEN t.Name = 'TradeOfferDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'TradeOfferDiscount',
    SUM(CASE WHEN t.Name = 'OtherChannelDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OtherChannelDiscount'
    ,SUM(isnull(sidw2.FreeSKUQuantity,0))AS 'FreeSKUQuantity' 
	,SUM(CASE WHEN t.Name = 'VisibilityDiscount'  THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'VisibilityDiscount'   
    ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountB'    THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountB'
	 ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountC'    THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountC' 
       from SaleInvoiceDetailWBCPromotion AS sidw2
			  INNER JOIN Promotion AS p
			  ON p.PromotionID = sidw2.PromotionID
              INNER JOIN Tags AS t
              ON t.TagID = p.TagID
	 GROUP BY SaleInvoiceDetailWBCId
	) d
ON d.SaleInvoiceDetailWBCId = sidw.SaleInvoiceDetailWBCId
WHERE si.DeliveryDate>=@DeliveryDateFrom AND si.DeliveryDate<=@DeliveryDateTo
and sid1.NetAmount>0.9

UNION ALL

SELECT 
si.DistributionID,si.CustomerID,si.InvoiceDate
,si.InvoiceDate as DeliveryDate
,'Settled' as 'Status'
,si.OrderBookerID,si.SalemanID,si.VanID,si.RouteName,si.InvoiceCode,
    Null as OrderStartTime,
	Null as OrderCompleteTime,
	Null as Synchronized,
	Null as Lattitude,
	Null as Longitude
,sidw.ProductID
,sidw.TotalPiecesOrdered*-1 AS 'TotalPiecesOrdered',sidw.TotalPiecesDelivered*-1 AS 'TotalPiecesDelivered',sidw.FMRRate,sidw.FMRAmount
,sidw.GSTRate,sidw.GSTValue*-1 AS 'GSTValue',sidw.AdvanceTaxRate,sidw.AdvanceTaxValue*-1 AS 'AdvanceTaxValue',sidw.FurtherTaxRate
,sidw.FurtherTaxValue*-1 AS 'FurtherTaxValue',sidw.MRPRate,sidw.MRPValue*-1 AS 'MRPValue',sidw.ConfectionaryTaxRate,sidw.ConfectionaryTaxValue*-1 AS 'ConfectionaryTaxValue'
,sidw.InvoicePriceCase,sidw.RetailPriceCase,sidw.ConsumerPriceCase,sidw.ValueWithoutTax*-1 AS 'ValueWithoutTax',sidw.TotalTax*-1 AS 'TotalTax'
,sidw.TotalValueWithTax*-1 AS 'TotalValueWithTax',sidw.NetAmount*-1 AS 'NetAmount'
,isnull(sidw.TradeOfferAmount,0)*-1 AS 'TradeOfferAmount',isnull(sid1.TradeOfferPercentageValue,0)*-1 AS 'TradeOfferPercentageValue'
,isnull(c.TotalDiscount,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0)*-1 AS 'TotalBillDiscount',Isnull(d.Discount*-1,0) AS 'OtherDiscount'
,(Isnull(d.FreeSKUQuantity,0)+isnull(c.FreeSKUQuantityTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'FreeSKUQuantity'
,(Isnull(d.RentalDiscount,0)+isnull(c.RentalDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0)) *-1 AS 'RentalDiscount',
(Isnull(d.WholesaleDiscount,0)+isnull(c.WholesaleDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'WholesaleDiscount'
,(Isnull(d.LoyaltyProgramDiscount,0)+isnull(c.LoyaltyProgramDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'LoyaltyProgramDiscount',
(Isnull(d.OffInvoiceDiscountA,0)+isnull(c.OffInvoiceDiscountATotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'OffInvoiceDiscountA',
(Isnull(d.[TradeOfferDiscount],0)+isnull(c.TradeOfferDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'TradeOfferDiscount',
(Isnull(d.OtherChannelDiscount,0)+isnull(c.OtherChannelDiscountTotal,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'OtherChannelDiscount'
,(Isnull(d.OffInvoiceDiscountB,0)+isnull(c.OffInvoiceDiscountB,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'OffInvoiceDiscountB'
,(Isnull(d.VisibilityDiscount,0)+isnull(c.VisibilityDiscount,0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'VisibilityDiscount'
,(Isnull(d.[OffInvoiceDiscountC],0)+isnull(c.[OffInvoiceDiscountC],0)*isnull(sidw.TotalPiecesDelivered*1.0/tp.TotalPieces,0))*-1 AS 'OffInvoiceDiscountC'
,sidw.BatchCode,'Return' AS 'Type',isnull(sid1.DiscountValue,0)*-1 AS DiscountValue,0 AS DiscountReversal
  FROM SaleInvoiceReturn AS si
INNER JOIN SaleInvoiceReturnDetail AS sid1
ON sid1.SaleInvoiceReturnID = si.SaleInvoiceReturnID
INNER JOIN SaleInvoiceReturnDetailWBC AS sidw
ON sidw.SaleInvoiceReturnDetailID = sid1.SaleInvoiceReturnDetailID

LEFT JOIN (SELECT sip.SaleInvoiceReturnDetailID,SUM(sip.TotalDiscount) AS 'TotalDiscount',
			SUM(CASE WHEN t.Name = 'RentalDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'RentalDiscountTotal',
			SUM(CASE WHEN t.Name = 'WholesaleDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'WholesaleDiscountTotal',
			SUM(CASE WHEN t.Name = 'LoyaltyProgramDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'LoyaltyProgramDiscountTotal',
			SUM(CASE WHEN t.Name = 'OffInvoiceDiscountA' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountATotal',
			SUM(CASE WHEN t.Name = 'TradeOfferDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'TradeOfferDiscountTotal',
			SUM(CASE WHEN t.Name = 'OtherChannelDiscount' THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OtherChannelDiscountTotal'
			,SUM(isnull(sip.FreeSKUQuantity,0))AS 'FreeSKUQuantityTotal' 
			,SUM(CASE WHEN t.Name = 'VisibilityDiscount'  THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'VisibilityDiscount'   
          ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountB'    THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountB' 
		   ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountC'    THEN ISNULL(sip.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountC' 
           from SaleInvoiceReturnDetailPromotion AS sip
			  INNER JOIN Promotion AS p
			  ON p.PromotionID = sip.PromotionID
              INNER JOIN Tags AS t
              ON t.TagID = p.TagID
	 GROUP BY sip.SaleInvoiceReturnDetailID
	) c
	ON c.SaleInvoiceReturnDetailID = sid1.SaleInvoiceReturnDetailID
	left join (   
   SELECT 
        SaleInvoiceReturnDetailID,
        SUM(TotalPiecesDelivered) AS TotalPieces
    FROM SaleInvoiceReturnDetailWBC
    GROUP BY SaleInvoiceReturnDetailID
    having SUM(TotalPiecesDelivered)<>0) tp on tp.SaleInvoiceReturnDetailID=sid1.SaleInvoiceReturnDetailID


Left JOIN (select SaleInvoiceReturnDetailWBCId, Sum(sidw2.TotalDiscount) AS 'Discount',
	SUM(CASE WHEN t.Name = 'RentalDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'RentalDiscount',
    SUM(CASE WHEN t.Name = 'WholesaleDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'WholesaleDiscount',
    SUM(CASE WHEN t.Name = 'LoyaltyProgramDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'LoyaltyProgramDiscount',
    SUM(CASE WHEN t.Name = 'OffInvoiceDiscountA' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountA',
    SUM(CASE WHEN t.Name = 'TradeOfferDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'TradeOfferDiscount',
    SUM(CASE WHEN t.Name = 'OtherChannelDiscount' THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OtherChannelDiscount'
    ,SUM(isnull(sidw2.FreeSKUQuantity,0))AS 'FreeSKUQuantity' 
	,SUM(CASE WHEN t.Name = 'VisibilityDiscount'  THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'VisibilityDiscount'   
      ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountB'    THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountB' 
	 ,SUM(CASE WHEN t.Name = 'OffInvoiceDiscountC'    THEN ISNULL(sidw2.TotalDiscount,0) ELSE 0 END) AS 'OffInvoiceDiscountC' 
           from SaleInvoiceReturnDetailWBCPromotion AS sidw2
			  INNER JOIN Promotion AS p
			  ON p.PromotionID = sidw2.PromotionID
              INNER JOIN Tags AS t
              ON t.TagID = p.TagID
	 GROUP BY SaleInvoiceReturnDetailWBCId
	) d
ON d.SaleInvoiceReturnDetailWBCId = sidw.SaleInvoiceReturnDetailWBCId
WHERE 
si.SaleInvoiceID is NOT null
AND si.InvoiceDate>=@DeliveryDateFrom AND si.InvoiceDate<=@DeliveryDateTo

UNION ALL


SELECT 
si.DistributionID,si.CustomerID,si.InvoiceDate
,si.InvoiceDate as DeliveryDate
,'Settled' as 'Status'
,si.OrderBookerID,si.SalemanID,si.VanID,si.RouteName,si.InvoiceCode,
 Null as OrderStartTime,
	Null as OrderCompleteTime,
	Null as Synchronized,
	Null as Lattitude,
	Null as Longitude
,sid.ProductID
,sid.TotalPiecesOrdered*-1 AS 'TotalPiecesOrdered',sid.TotalPiecesDelivered*-1 AS 'TotalPiecesDelivered',sid.FMRRate,sid.FMRAmount
,sid.GSTRate,sid.GSTValue*-1 AS 'GSTValue',sid.AdvanceTaxRate,sid.AdvanceTaxValue*-1 AS 'AdvanceTaxValue',sid.FurtherTaxRate
,sid.FurtherTaxValue*-1 AS 'FurtherTaxValue',sid.MRPRate,sid.MRPValue*-1 AS 'MRPValue',
sid.ConfectionaryTaxRate,sid.ConfectionaryTaxValue*-1 AS 'ConfectionaryTaxValue'
,sid.InvoicePriceCase,sid.RetailPriceCase,sid.ConsumerPriceCase,sid.ValueWithoutTax*-1 AS 'ValueWithoutTax',sid.TotalTax*-1 AS 'TotalTax'
,sid.TotalValueWithTax*-1 AS 'TotalValueWithTax',sid.NetAmount*-1 AS 'NetAmount'
,0 AS 'TradeOfferAmount',isnull(sid.TradeOfferPercentageValue,0)*-1 AS 'TradeOfferPercentageValue',
0 AS TotalBillDiscount
,0 AS 'OtherDiscount'
,0 AS 'FreeSKUQuantity'
,0 AS 'RentalDiscount'
,0 AS 'WholesaleDiscount'
,0 AS 'LoyaltyProgramDiscount'
,0 AS 'OffInvoiceDiscountA'
,0 AS 'TradeOfferDiscount'
,0 AS 'OtherChannelDiscount'
,0 AS 'OffInvoiceDiscountB'
,0 AS 'VisibilityDiscount'
,0 AS 'OffInvoiceDiscountC'
,sid.BatchCode,'Return' AS 'Type',isnull(sid.DiscountValue,0)*-1 AS DiscountValue,isnull(sid.TradeOfferAmount,0) AS DiscountReversal
  FROM SaleInvoiceReturn AS si
INNER JOIN SaleInvoiceReturnDetail AS sid
ON sid.SaleInvoiceReturnID = si.SaleInvoiceReturnID
WHERE si.SaleInvoiceID is null
AND si.InvoiceDate>=@DeliveryDateFrom AND si.InvoiceDate<=@DeliveryDateTo

END
