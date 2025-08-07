@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement Interface View'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
define view entity ZVK_BKSPL_I
  as select from zvk_des_bksuppl
  association        to parent ZVK_BOOKING_I as _Booking on $projection.BookingUuid = _Booking.BookingUuid
  association [1..1] to ZVK_TRAVEL_I         as _Travel  on $projection.TravelUuid = _Travel.TravelUuid
{
  key booksuppl_uuid        as BooksupplUuid,
      root_uuid             as TravelUuid,
      parent_uuid           as BookingUuid,
      booking_supplement_id as BookingSupplementId,
      supplement_id         as SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _Booking, // Make association public
      _Travel // Make association public
}
