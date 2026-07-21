USE [RetailDW]
GO
/****** Object:  StoredProcedure [dbo].[SA_SP_OB_Overall]    Script Date: 7/14/2026 5:47:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[SA_SP_OB_Overall]
AS
BEGIN
 
DELETE FROM SA_OB_Overall WHERE [MONTH]=MONTH(GETDATE()-1) AND [YEAR]=Year(GETDATE()-1)
 
INSERT INTO SA_OB_Overall(
	DistributionID,
	DistributionType,
	ClassName,
	DistributionName,
	OrderBookerID,
	OrderBooker,
	Level1Name,
	Level2Name,
	Level3Name,
	Level4Name,
	ChannelName,
	SubChannel,
	Element,
	SubElement,
	TotalPieces,
	Cases,
	TotalKg,
	TotalTons,
	TaxAmount,
	TotalNetAmount,
	InvoiceCount,
	[Numeric],
	TotalDiscount,
	NonClaimableDiscount,
	ClaimableDiscount,
	RentalDiscount,
	WholesaleDiscount,
	LoyaltyProgramDiscount,
	OffInvoiceDiscountA,
	[TradeOfferDiscount],
	OtherChannelDiscount,
	Others,
	[Month],
	[Year],
	SalesMonth,
	AddOn,
	SubElementID,
	[VisibilityDiscount],
	[OffInvoiceDiscountB],
	[OffInvoiceDiscountC]
	)
 
SELECT 
sd.DistributionID,d.DistributionType,dc.ClassName,d.LegalName   DistributionName
,ob.OrderbookerId,ob.Name as OrderBooker
,l1.Name as Level1Name,l2.Name as Level2Name,l3.Name Level3Name,l4.Name as Level4Name
,ch.Title ChannelName,sch.Title SubChannel,e.Title Element,se.Title SubElement

,Sum(sd.TotalPiecesDelivered%p.UnitPerCarton) AS 'TotalPieces' 
,Sum(sd.TotalPiecesDelivered/p.UnitPerCarton) AS 'Cases'
,Sum(sd.TotalPiecesDelivered*p.UnitWeight/1000) AS 'TotalKg'
,Sum((sd.TotalPiecesDelivered*p.UnitWeight/1000)/Case when p.TonnageFactor is null or p.TonnageFactor=0 then 1000 else p.TonnageFactor end ) AS 'TotalTons'
,SUM(isnull(sd.GStValue,0)+isnull(sd.MRPValue,0)) AS 'TaxAmount'
,Sum(sd.NetAmount) AS 'TotalNetAmount'
,Count(distinct sd.InvoiceCode) AS 'InvoiceCount'
,Count(distinct sd.CustomerID) AS 'Numeric'

,Sum(isnull(sd.TotalBillDiscount,0)+isnull(sd.OtherDiscount,0)) AS 'TotalDiscount',0 AS 'NonClaimableDiscount'
,0 AS 'ClaimableDiscount',Sum(sd.RentalDiscount) AS 'RentalDiscount',Sum(sd.WholesaleDiscount) AS 'WholesaleDiscount'
,Sum(isnull(sd.LoyaltyProgramDiscount,0)) AS 'LoyaltyProgramDiscount',Sum(isnull(sd.OffInvoiceDiscountA,0)) AS 'OffInvoiceDiscountA',Sum(isnull(sd.[TradeOfferDiscount],0)) AS 'TradeOfferDiscount',Sum(isnull(sd.OtherChannelDiscount,0)) AS 'OtherChannelDiscount',
0 AS 'Others'

,Month(sd.deliverydate) AS 'Month',Year(sd.DeliveryDate) AS 'Year'
,Format(sd.DeliveryDate,'MMM-yy')AS 'SalesMonth'
,getdate() AS 'AddOn'
,Se.SubElementID,SUM(sd.[VisibilityDiscount]) as 'VisibilityDiscount',SUM(sd.[OffInvoiceDiscountB]) as 'OffInvoiceDiscountB'
,SUM(sd.[OffInvoiceDiscountC]) as 'OffInvoiceDiscountC'

  
  FROM  SA_SalesDataDump  sd
join Customer c on c.CustomerID=sd.CustomerID
join OrderBooker ob on ob.OrderBookerID=sd.OrderBookerID
join Distribution d on d.DistributionID=sd.distributionid
join Level1 l1 on l1.Level1ID=d.Level1ID
join Level2 l2 on l2.Level2ID=d.Level2ID
join Level3 l3 on l3.Level3ID=d.Level3ID
join Level4 l4 on l4.Level4ID=d.Level4ID
join DistributionClass dc on dc.DistributionClassID=d.DistributionClassID
join Channel ch on ch.ChannelID=c.ChannelID
join SubChannel sch on sch.SubChannelID=c.SubChannelID
join Element e on e.ElementID=c.ElementID
join SubElement se on se.SubElementID=c.SubElementID
join Product p on p.ProductID=sd.ProductId


WHERE sd.DeliveryDate >=cast(DATEADD(MONTH,DATEDIFF(month,0,GETDATE()-1),0) AS DATE)
AND sd.DeliveryDate <=cast(GETDATE()-1 AS DATE)
AND (
        (sd.Type = 'Sales' AND sd.Netamount > 0.9 AND sd.Status = 'Settled')
     OR (sd.Type = 'Return')
)
GROUP BY  
sd.DistributionID,d.DistributionType,dc.ClassName,d.LegalName,ob.OrderbookerId,ob.Name
,l1.Name,l2.Name,l3.Name,l4.Name,ch.Title,sch.Title,e.Title,se.Title,Se.SubElementID
,Month( sd.deliverydate),Year(sd.DeliveryDate ),Format(sd.DeliveryDate,'MMM-yy')


end
