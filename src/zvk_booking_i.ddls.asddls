@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Interface View'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZVK_BOOKING_I
  as select from zvk_des_booking

  composition [0..*] of ZVK_BKSPL_I  as _Bookingsupplement

  association to parent ZVK_TRAVEL_I as _Travel on $projection.TravelUuid = _Travel.TravelUuid
{
  key booking_uuid          as BookingUuid,
      parent_uuid           as TravelUuid,
      booking_id            as BookingId,
      booking_date          as BookingDate,
      customer_id           as CustomerId,
      carrier_id            as CarrierId,
      connection_id         as ConnectionId,
      flight_date           as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,
      currency_code         as CurrencyCode,
      booking_status        as BookingStatus,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Travel,
      _Bookingsupplement
}
