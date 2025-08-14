*cl_abap_behavior_saver -->HANDLES SAVE SEQUNECE PHASE
CLASS lsc_zvk_travel_i DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zvk_travel_i IMPLEMENTATION.

  METHOD save_modified.

    DATA : travel_log        TYPE STANDARD TABLE OF zvk_travel_log,
           travel_log_create TYPE STANDARD TABLE OF zvk_travel_log,
           travel_log_update TYPE STANDARD TABLE OF zvk_travel_log.

*************create-travel**************************************************************************************************************************
    IF create-travel IS NOT INITIAL.

      travel_log = CORRESPONDING #( create-travel ).
      LOOP AT travel_log ASSIGNING FIELD-SYMBOL(<lfs_travel_log>).

        <lfs_travel_log>-changing_operation = 'CREATE'.

        GET TIME STAMP FIELD <lfs_travel_log>-created_at.

        TRY.
            <lfs_travel_log>-change_id = cl_system_uuid=>create_uuid_x16_static(  ).

          CATCH cx_uuid_error.

        ENDTRY.

        IF create-travel[ 1 ]-%control-BookingFee = cl_abap_behv=>flag_changed.
          <lfs_travel_log>-changed_field_name = 'Booking Fee'.
          <lfs_travel_log>-changed_value = create-travel[ 1 ]-BookingFee.

          <lfs_travel_log>-travelid =  create-travel[ 1 ]-TravelId.

        ENDIF.

        IF create-travel[ 1 ]-%control-AgencyId = cl_abap_behv=>flag_changed.
          <lfs_travel_log>-changed_field_name = 'Agency ID'.
          <lfs_travel_log>-changed_value = create-travel[ 1 ]-AgencyId.
        ENDIF.

        APPEND <lfs_travel_log> TO travel_log_create.

      ENDLOOP.

      MODIFY zvk_travel_log FROM TABLE @travel_log_create.

    ENDIF.
********************************************************************************************************************************************************
*************update-travel**************************************************************************************************************************
    IF update-travel IS NOT INITIAL.

      travel_log = CORRESPONDING #( update-travel ).

      LOOP AT travel_log ASSIGNING FIELD-SYMBOL(<lfs_travel_update>).

        <lfs_travel_update>-changing_operation = 'UPDATE'.

        GET TIME STAMP FIELD <lfs_travel_update>-created_at.

        TRY.
            <lfs_travel_update>-change_id = cl_system_uuid=>create_uuid_x16_static(  ).

          CATCH cx_uuid_error.

        ENDTRY.

        IF update-travel[ 1 ]-%control-BookingFee = cl_abap_behv=>flag_changed.
          <lfs_travel_update>-changed_field_name = 'Booking Fee'.
          <lfs_travel_update>-changed_value = update-travel[ 1 ]-BookingFee.

          <lfs_travel_update>-travelid = update-travel[ 1 ]-TravelId.

        ENDIF.

        IF update-travel[ 1 ]-%control-AgencyId = cl_abap_behv=>flag_changed.
          <lfs_travel_update>-changed_field_name = 'Agency ID'.
          <lfs_travel_update>-changed_value = update-travel[ 1 ]-AgencyId.
        ENDIF.

        APPEND <lfs_travel_update> TO  travel_log_update.
      ENDLOOP.
      MODIFY zvk_travel_log FROM TABLE @travel_log_update.
    ENDIF.
********************************************************************************************************************************************************
*************delete-travel**************************************************************************************************************************

    IF delete-travel IS NOT INITIAL.

      TYPES : BEGIN OF ty_travel_uuid,
                TravelUuid TYPE sysuuid_x16,
              END OF ty_travel_uuid.

      DATA : lt_travel     TYPE TABLE FOR READ RESULT zvk_travel_I,
             ls_travel_log TYPE zvk_travel_log.

      lt_travel = CORRESPONDING #( delete-travel ).

      SELECT FROM zvk_des_travel FIELDS *
      FOR ALL ENTRIES IN @lt_travel
      WHERE travel_uuid = @lt_travel-TravelUuid
      INTO TABLE @DATA(lt_travels).


      LOOP AT lt_travels INTO DATA(lfs_Delete_travel_log).

        ls_travel_log = CORRESPONDING #( lfs_Delete_travel_log MAPPING travelid =  travel_id EXCEPT * ).

        ls_travel_log-changing_operation = 'DELETE'.

        GET TIME STAMP FIELD ls_travel_log-created_at.

        TRY.
            ls_travel_log-change_id = cl_system_uuid=>create_uuid_x16_static(  ).

          CATCH cx_uuid_error.

        ENDTRY.

        APPEND ls_travel_log TO  travel_log_update.
      ENDLOOP.

      MODIFY zvk_travel_log FROM TABLE @travel_log_update.
    ENDIF.

  ENDMETHOD.
ENDCLASS.

*cl_abap_behavior_handler -->HANDLES INTERACTION PHASE

CLASS lhc_bookingsuppl DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS SetBookingSupplId FOR DETERMINE ON SAVE
      IMPORTING keys FOR Bookingsuppl~SetBookingSupplId.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Bookingsuppl~calculateTotalPrice.

ENDCLASS.

CLASS lhc_bookingsuppl IMPLEMENTATION.

  METHOD SetBookingSupplId.

    DATA : Max_Booking_Suppl_ID TYPE /dmo/booking_supplement_id,
           BookingSupplement    TYPE STRUCTURE FOR READ RESULT zvk_bkspl_i,
           BookingSuppl_update  TYPE TABLE FOR UPDATE zvk_travel_i\\Bookingsuppl.

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Bookingsuppl BY \_Booking
    FIELDS ( BookingUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Bookings).

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Booking BY \_Bookingsupplement
    FIELDS ( BookingSupplementId )
    WITH CORRESPONDING #( Bookings )
    LINK DATA(BookingSuppl_links)
    RESULT DATA(Bookingsupplements).

    LOOP AT Bookings INTO DATA(Booking).

      Max_Booking_Suppl_ID = '00'.

      LOOP AT BookingSuppl_links INTO DATA(BookingSuppl_link) USING KEY id WHERE source-%tky = booking-%tky.

        BookingSupplement = Bookingsupplements[ KEY id
                                               %tky = BookingSuppl_link-target-%tky  ].

        IF BookingSupplement-BookingSupplementId > Max_Booking_Suppl_ID.
          Max_Booking_Suppl_ID = BookingSupplement-BookingSupplementId.
        ENDIF.

      ENDLOOP.

      LOOP AT BookingSuppl_links INTO BookingSuppl_link USING KEY id WHERE source-%tky = booking-%tky.
        BookingSupplement = Bookingsupplements[ KEY id
                                               %tky = BookingSuppl_link-target-%tky  ].

        IF BookingSupplement-BookingSupplementId IS INITIAL.
          Max_Booking_Suppl_ID += 1.

          APPEND VALUE #( %tky = bookingsupplement-%tky
                           BookingSupplementId =  Max_Booking_Suppl_ID
                           ) TO  BookingSuppl_update.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Bookingsuppl
    UPDATE FIELDS ( BookingSupplementId )
    WITH bookingsuppl_update.

  ENDMETHOD.

  METHOD calculateTotalPrice.

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Bookingsuppl BY \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    EXECUTE ReCalcTotalPrice
    FROM CORRESPONDING #( travels ).

  ENDMETHOD.
ENDCLASS.

****************Booking***************************************************************************************************************************
CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS SetBookingID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~SetBookingID.
    METHODS SetBookingDate FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~SetBookingDate.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalPrice.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD SetBookingID.

    DATA : Max_bookingId   TYPE /dmo/booking_id,
           Booking         TYPE STRUCTURE FOR READ RESULT zvk_booking_i,
           Bookings_update TYPE TABLE FOR UPDATE zvk_travel_i\\Booking.

*we are reading booking entity to get the Traveluuid field for the current booking instance and store that it into Travels table
    READ ENTITIES OF ZVk_travel_i IN LOCAL MODE
    ENTITY Booking BY \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

*Now read all the bookings related to the Travel Entity which we got from the travels table
    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FIELDS ( BookingId )
    WITH CORRESPONDING #( travels )
    LINK DATA(Booking_links)
    RESULT DATA(Bookings).

    LOOP AT travels INTO DATA(travel).
*Initialize the Booking Id Number
      Max_bookingId = '0000'.

      LOOP AT Booking_links INTO DATA(Booking_link) USING KEY id WHERE source-%tky = travel-%tky.
*BELOW "Booking" IS A STRUCTURE
        Booking = Bookings[ KEY id
                            %tky = Booking_link-target-%tky ].

        IF Booking-BookingId > Max_bookingId.
          Max_bookingId = Booking-BookingId.
        ENDIF.

      ENDLOOP.

      LOOP AT Booking_links INTO Booking_link USING KEY id WHERE source-%tky = travel-%tky.

        Booking = Bookings[ KEY id
                            %tky = Booking_link-target-%tky ].
        IF Booking-BookingId IS INITIAL.

          Max_bookingId += 1.
          APPEND VALUE #( %tky = booking-%tky
                           Bookingid =  Max_bookingId
                             ) TO Bookings_update.

        ENDIF.

      ENDLOOP.
    ENDLOOP.

*modify eml to update both Booking Entity with the new Booking id number which is Max_bookingId
    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Booking
    UPDATE FIELDS ( BookingId )
    WITH Bookings_update.
  ENDMETHOD.

  METHOD SetBookingDate.
  ENDMETHOD.

  METHOD calculateTotalPrice.

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Booking BY \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Travels).

    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    EXECUTE ReCalcTotalPrice
    FROM CORRESPONDING #( Travels ).

  ENDMETHOD.

ENDCLASS.
**********************************************************************************************************************************************************************

****************Travel***************************************************************************************************************************
CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS SetTravelID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~SetTravelID.
    METHODS SetOverallstatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~SetOverallstatus.
    METHODS AcceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~AcceptTravel RESULT result.

    METHODS RejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~RejectTravel RESULT result.
    METHODS DeductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~DeductDiscount RESULT result.
    METHODS GetDefaultsForDeductDiscount FOR READ
      IMPORTING keys FOR FUNCTION Travel~GetDefaultsForDeductDiscount RESULT result.
    METHODS ReCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~ReCalcTotalPrice.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.
    METHODS ValidateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateCustomer.
    METHODS ValidateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateAgency.

    METHODS ValidateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateDates.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD SetTravelID.

    "{"local mode specifies that improves performance,skip all authorizations and validations because You are in the inside your BO
    "if there is no local mode it will operates in the external mode and it will check all the authorizations and validations then only
    "it will perform the operations. }

    "Read the Entity Travel
    READ ENTITIES OF Zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_Travel).

*DELETE the entry if already Travelid existed
    DELETE lt_travel WHERE TravelId IS NOT INITIAL.

*reading the entry which is maximum or highest Travelid number from database table
    SELECT SINGLE FROM zvk_des_travel FIELDS MAX( travel_id ) INTO @DATA(lv_travelid_max).

*Modify EML
    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TravelId )
    WITH VALUE #( FOR ls_travel_id IN lt_travel INDEX INTO lv_index
                    ( %tky = ls_travel_id-%tky
                    travelid = lv_travelid_max + 1 ) ).

  ENDMETHOD.

  METHOD SetOverallstatus.
    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_status).

    DELETE lt_status WHERE OverallStatus IS NOT INITIAL.

    MODIFY ENTITIES OF Zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_status IN lt_status
                    ( %tky = ls_status-%tky
                      OverallStatus = 'O'     ) ).

  ENDMETHOD.
  METHOD AcceptTravel.
    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                    OverallStatus = 'A' ) ).

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(Travels).

    result = VALUE #( FOR Travel IN travels ( %tky = Travel-%tky
                                              %param = travel ) ).

  ENDMETHOD.

  METHOD RejectTravel.
    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                      OverallStatus = 'R' ) ).

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(Travels).

    result = VALUE #( FOR Travel IN travels ( %tky = travel-%tky
                                              %param = travel ) ).

  ENDMETHOD.

  METHOD DeductDiscount.

    DATA : Travel_for_Update TYPE TABLE FOR UPDATE zvk_travel_i.

    DATA(keys_temp) = keys.   "KEYS_TEMP = INTERNAL TABLE HERE.
*keys is a system-provided internal table containing the keys of the entities on which the action was triggered.
*keys_temp is a local copy used for processing.

    LOOP AT keys_temp ASSIGNING FIELD-SYMBOL(<key_temp>) WHERE %param-Discount_Percent IS INITIAL OR
                                                                %param-Discount_Percent > 100 OR
                                                                %param-Discount_Percent < 0.

*Adds the current key to the failed-travel table, indicating that this instance of the action has failed.
      APPEND VALUE #( %tky = <key_temp>-%tky
                     ) TO failed-travel.

      APPEND VALUE #( %tky = <key_temp>-%tky
                      %msg = new_message_with_text( text = 'INVALID DISCOUNT'
                                                    severity = if_abap_behv_message=>severity-error )
                      %element-totalprice    = if_abap_behv=>mk-on
                      %action-DeductDiscount = if_abap_behv=>mk-on ) TO reported-travel .

      DELETE keys_temp .
    ENDLOOP.

    CHECK Keys_temp IS NOT INITIAL.

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TotalPrice )
    WITH CORRESPONDING #( keys_temp )
    RESULT DATA(lt_travels).

    DATA : lv_percentage TYPE decfloat16.

    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<fs_travel>).

      DATA(lv_discount_percent) = keys[ KEY id %tky = <fs_travel>-%tky ]-%param-Discount_Percent.
      lv_percentage = lv_discount_percent / 100.

      DATA(reduced_value) = <fs_travel>-TotalPrice * lv_percentage.
      reduced_value = <fs_travel>-TotalPrice - reduced_value.

      APPEND VALUE #( %tky = <fs_travel>-%tky
                      totalprice = reduced_value ) TO travel_for_update.
    ENDLOOP.

*IT IS MODIFYING THE BACKEND TABLE
    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( TotalPrice )
    WITH travel_for_update.

*NOW WE HAVE TO SEND IT BACK TO THE OUTPUT SCREEN ,SO WE ARE READING ALL THE FIELDS TO lt_travel_updated
    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(lt_travel_updated).

*    AND THE RESULT IS THE CHANGING PARAMETER OF "DeductDiscount" method  SO WE CAN SEND IT TO OUTPUT SCREEN
    result = VALUE #( FOR ls_travel IN lt_travel_updated (  %tky = ls_travel-%tky
                                                            %param = ls_travel ) ).

  ENDMETHOD.

  METHOD GetDefaultsForDeductDiscount.
*  Reading Total price
    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TotalPrice )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Travels).

    LOOP AT travels INTO DATA(travel).
      IF travel-TotalPrice >= 4000.
        APPEND VALUE #( %tky = travel-%tky
                        %param-Discount_Percent = 30 ) TO result.
      ELSE.
        APPEND VALUE #( %tky = Travel-%tky
                        %param-Discount_Percent = 15 ) TO result.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD ReCalcTotalPrice.

    TYPES : BEGIN OF ty_amount_per_currencycode,
              amount        TYPE /dmo/total_price,
              currency_code TYPE /dmo/currency_code,
            END OF ty_amount_per_currencycode.

    DATA : amounts_per_Currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BookingFee CurrencyCode )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY travel BY \_Booking
    FIELDS ( flightprice Currencycode )
    WITH CORRESPONDING #( travels )
    LINK DATA(Booking_Links)
    RESULT DATA(Bookings).

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Booking BY \_Bookingsupplement
    FIELDS ( Price CurrencyCode )
    WITH CORRESPONDING #( bookings )
    LINK DATA(BookingSupplements_links)
    RESULT DATA(BookingSupplements).

    LOOP AT Travels ASSIGNING FIELD-SYMBOL(<Travel>).

      amounts_per_Currencycode = VALUE #( ( amount = <Travel>-BookingFee
                                          currency_code = <Travel>-CurrencyCode ) ).

      LOOP AT Booking_links INTO DATA(Booking_link) USING KEY id WHERE source-%tky = <Travel>-%tky.

        DATA(Booking) = Bookings[ KEY id %tky = booking_link-target-%tky ].
        COLLECT VALUE ty_amount_per_currencycode( amount = booking-FlightPrice
                                                    currency_code = booking-CurrencyCode ) INTO amounts_per_Currencycode.

        LOOP AT BookingSupplements_links INTO DATA(BookingSupplements_link) USING KEY id WHERE source-%tky = Booking-%tky.

          DATA(BookingSupplement) = BookingSupplements[ KEY id %tky = BookingSupplements_link-target-%tky ].
          COLLECT VALUE ty_amount_per_currencycode( amount = BookingSupplement-Price
                                                    currency_code = BookingSupplement-CurrencyCode ) INTO amounts_per_Currencycode.

        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

    DELETE amounts_per_currencycode WHERE currency_code IS INITIAL.

    LOOP AT amounts_per_currencycode INTO DATA(amount_per_currencycode).
      ""Travel-Bookingfee (Having Totalprice = Bookingfee+Flightprice+Price)
      ""Booking-Flightprice
      ""Booking Supplement-Price

      IF <Travel>-CurrencyCode = amount_per_currencycode-currency_code.
        <Travel>-TotalPrice += amount_per_currencycode-amount.
      ELSE.
        /dmo/cl_flight_amdp=>convert_currency(
        EXPORTING
        iv_amount               = amount_per_currencycode-amount
        iv_currency_code_source = amount_per_currencycode-currency_code
        iv_currency_code_target = <travel>-CurrencyCode
        iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
        IMPORTING
        ev_amount               = DATA(total_booking_price_per_curr)             ).

        <Travel>-TotalPrice += total_booking_price_per_curr.
      ENDIF.

      MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
      ENTITY Travel
      UPDATE FIELDS ( TotalPrice )
      WITH CORRESPONDING #( Travels ).

    ENDLOOP.
  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    EXECUTE ReCalcTotalPrice    """LIKE FM
    FROM CORRESPONDING #( keys ).
  ENDMETHOD.

  METHOD ValidateCustomer.
    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DATA : customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).

    SELECT FROM /dmo/customer FIELDS customer_id
    FOR ALL ENTRIES IN @customers
    WHERE customer_id = @customers-customer_id
    INTO TABLE @DATA(valid_customers).

    LOOP AT travels INTO DATA(travel).
      APPEND VALUE #(  %tky = travel-%tky
                      %state_area = 'Validate_Customer' )
                      TO reported-travel.
      IF travel-CustomerId IS NOT INITIAL AND NOT line_exists( valid_Customers[ customer_id = travel-CustomerId ] ).

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'Validate_Customer'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = |Not a Valid Customer   { travel-CustomerId }|
                                                     )
                        %element-customerid = if_abap_behv=>mk-on
                      )  TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD ValidateAgency.
    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
     ENTITY Travel
     FIELDS ( AgencyId )
     WITH CORRESPONDING #( keys )
     RESULT DATA(travels).

    DATA : Agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    Agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = AgencyId EXCEPT * ).

    SELECT FROM /dmo/agency FIELDS agency_id
    FOR ALL ENTRIES IN @Agencies
    WHERE agency_id = @Agencies-agency_id
    INTO TABLE @DATA(valid_Agencies).

    LOOP AT travels INTO DATA(travel).
      APPEND VALUE #( %tky = travel-%tky
                      %state_area = 'Validate_Agency' ) TO reported-travel.
      IF travel-AgencyId IS NOT INITIAL AND NOT line_exists( valid_Agencies[ agency_id = travel-AgencyId ] ).

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
         %state_area = 'Validate_Agency'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = |Not a Valid AgencyID   { travel-AgencyId }|
                                                     )
                        %element-AgencyId = if_abap_behv=>mk-on
                      )  TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD ValidateDates.
    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
      ENTITY Travel
      FIELDS ( BeginDate EndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      APPEND VALUE #( %tky = travel-%tky
                    %state_area = 'Validate_Dates' ) TO reported-travel.
      IF travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                     %state_area = 'Validate_Dates'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = |Begin date should not be empty|
                                                     )
                        %element-BeginDate = if_abap_behv=>mk-on
                      )  TO reported-travel.
      ENDIF.

      IF travel-EndDate IS INITIAL .

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                      %state_area = 'Validate_Dates'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = |End Date should not be empty|
                                                     )
                        %element-EndDate = if_abap_behv=>mk-on
                      )  TO reported-travel.

      ENDIF.

      IF travel-EndDate < travel-BeginDate  AND travel-BeginDate IS NOT INITIAL
                                            AND travel-EndDate IS  NOT INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'Validate_Dates'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                       text = |End Date should not be less than Begin date  |
                                                     )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate = if_abap_behv=>mk-on
                      )  TO reported-travel.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zvk_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR ls_travel IN travels
                        ( %tky = ls_travel-%tky
                          %field-BookingFee = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                      THEN if_abap_behv=>fc-f-read_only
                                                      ELSE if_abap_behv=>fc-f-unrestricted )
                        %action-AcceptTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )
                        %action-RejectTravel = COND #( WHEN ls_travel-OverallStatus = 'R'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )
*                        %action-DeductDiscount = COND #( WHEN ls_travel-OverallStatus = 'A'
*                                                       THEN if_abap_behv=>fc-o-disabled
*                                                       ELSE if_abap_behv=>fc-o-enabled )
*when the status is A or R it should be in disabled mode ,only when status is Open it should be enabled mode.
                         %action-DeductDiscount = COND #( WHEN ls_travel-OverallStatus = 'O'
                                                       THEN if_abap_behv=>fc-o-enabled
                                                       ELSE if_abap_behv=>fc-o-disabled )
                        )
                    ).
  ENDMETHOD.
ENDCLASS.
**********************************************************************************************************************************************************************
