@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Consumption Entity'
@Metadata.allowExtensions: true
//@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #CONSUMPTION
define view entity ZVK_BOOKING_C
  as projection on ZVK_BOOKING_I
{
  key BookingUuid,
      TravelUuid,
      BookingId,
      BookingDate,
      CustomerId,
      CarrierId,
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LocalLastChangedAt,
      /* Associations */
      _Bookingsupplement: redirected to composition child ZVK_BKSPL_C,
      _Travel: redirected to parent ZVK_TRAVEL_C
}
