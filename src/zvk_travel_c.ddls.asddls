@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Root Consumption Entity'
@Metadata.allowExtensions: true
//@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #CONSUMPTION

define root view entity ZVK_TRAVEL_C
  provider contract transactional_query
  as projection on ZVK_TRAVEL_I
{
  key TravelUuid,
      TravelId,
      AgencyId,
      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerId,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      _Customer.FirstName as CustomerName,
      /* Associations */
      _Booking : redirected to composition child ZVK_BOOKING_C
}
