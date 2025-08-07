@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement Consumption Entity'
@Metadata.allowExtensions: true
//@Metadata.ignorePropagatedAnnotations: true
define view entity ZVK_BKSPL_C
  as projection on ZVK_BKSPL_I
{
  key BooksupplUuid,
      TravelUuid,
      BookingUuid,
      BookingSupplementId,
      SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      LocalLastChangedAt,
      /* Associations */
      _Booking : redirected to parent ZVK_BOOKING_C,
      _Travel  : redirected to ZVK_TRAVEL_C
}
