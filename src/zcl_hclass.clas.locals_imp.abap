CLASS lhc_OrderHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR OrderHeader RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR OrderHeader RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE OrderHeader.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE OrderHeader.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE OrderHeader.

    METHODS read FOR READ
      IMPORTING keys FOR READ OrderHeader RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK OrderHeader.

    METHODS rba_Orderitems FOR READ
      IMPORTING keys_rba FOR READ OrderHeader\_Orderitems
      FULL result_requested RESULT result LINK association_links.

    METHODS cba_Orderitems FOR MODIFY
      IMPORTING entities_cba FOR CREATE OrderHeader\_Orderitems.

    METHODS MarkCompleted FOR MODIFY
      IMPORTING keys FOR ACTION OrderHeader~MarkCompleted RESULT result.

    METHODS StartPreparing FOR MODIFY
      IMPORTING keys FOR ACTION OrderHeader~StartPreparing RESULT result.

ENDCLASS.


CLASS lhc_OrderHeader IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD create.
    DATA: ls_order_hdr TYPE zrom_header_t.

    LOOP AT entities INTO DATA(ls_entities).
      ls_order_hdr = CORRESPONDING #( ls_entities MAPPING FROM ENTITY ).

      IF ls_order_hdr-orderid IS NOT INITIAL.

        SELECT FROM zrom_header_t FIELDS *
          WHERE orderid = @ls_order_hdr-orderid
          INTO TABLE @DATA(lt_order_hdr).

        IF sy-subrc NE 0.
          "--- New Order → Set defaults and save to buffer ---
          ls_order_hdr-orderstatus = 'Pending'.
          ls_order_hdr-orderdate   = sy-datum.
          ls_order_hdr-ordertime   = sy-uzeit.
          ls_order_hdr-currency    = 'INR'.

          DATA(lo_util) = zcl_rom_utility=>get_instance( ).
          lo_util->set_hdr_value(
            EXPORTING im_order_hdr = ls_order_hdr
            IMPORTING ex_created   = DATA(lv_created) ).

          IF lv_created EQ abap_true.
            APPEND VALUE #(
              %cid    = ls_entities-%cid
              orderid = ls_order_hdr-orderid )
            TO mapped-orderheader.

            APPEND VALUE #(
              %cid    = ls_entities-%cid
              orderid = ls_order_hdr-orderid
              %msg    = new_message(
                id       = 'ZROM_MSG'
                number   = 001
                v1       = 'Order Created Successfully'
                severity = if_abap_behv_message=>severity-success ) )
            TO reported-orderheader.
          ENDIF.

        ELSE.
          "--- Duplicate Order ---
          APPEND VALUE #(
            %cid    = ls_entities-%cid
            orderid = ls_order_hdr-orderid )
          TO failed-orderheader.

          APPEND VALUE #(
            %cid    = ls_entities-%cid
            orderid = ls_order_hdr-orderid
            %msg    = new_message(
              id       = 'ZROM_MSG'
              number   = 002
              v1       = 'Order ID Already Exists'
              severity = if_abap_behv_message=>severity-error ) )
          TO reported-orderheader.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD update.
    DATA: ls_order_hdr TYPE zrom_header_t.

    LOOP AT entities INTO DATA(ls_entities).
      ls_order_hdr = CORRESPONDING #( ls_entities MAPPING FROM ENTITY ).

      IF ls_order_hdr-orderid IS NOT INITIAL.

        SELECT FROM zrom_header_t FIELDS *
          WHERE orderid = @ls_order_hdr-orderid
          INTO TABLE @DATA(lt_order_hdr).

        IF sy-subrc EQ 0.
          "--- Order exists → Update buffer ---
          DATA(lo_util) = zcl_rom_utility=>get_instance( ).
          lo_util->set_hdr_value(
            EXPORTING im_order_hdr = ls_order_hdr
            IMPORTING ex_created   = DATA(lv_created) ).

          IF lv_created EQ abap_true.
            APPEND VALUE #(
              orderid = ls_order_hdr-orderid )
            TO mapped-orderheader.

            APPEND VALUE #(
              %key = ls_entities-%key
              %msg = new_message(
                id       = 'ZROM_MSG'
                number   = 001
                v1       = 'Order Updated Successfully'
                severity = if_abap_behv_message=>severity-success ) )
            TO reported-orderheader.
          ENDIF.

        ELSE.
          "--- Order Not Found ---
          APPEND VALUE #(
            %cid    = ls_entities-%cid_ref
            orderid = ls_order_hdr-orderid )
          TO failed-orderheader.

          APPEND VALUE #(
            %cid    = ls_entities-%cid_ref
            orderid = ls_order_hdr-orderid
            %msg    = new_message(
              id       = 'ZROM_MSG'
              number   = 003
              v1       = 'Order Not Found'
              severity = if_abap_behv_message=>severity-error ) )
          TO reported-orderheader.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    DATA: ls_order_hdr TYPE zcl_rom_utility=>ty_order_hdr.
    DATA(lo_util) = zcl_rom_utility=>get_instance( ).

    LOOP AT keys INTO DATA(ls_key).
      CLEAR ls_order_hdr.
      ls_order_hdr-orderid = ls_key-orderid.

      lo_util->set_hdr_t_deletion(
        EXPORTING im_order_hdr = ls_order_hdr ).
      lo_util->set_hdr_deletion_flag(
        EXPORTING im_order_delete = abap_true ).

      APPEND VALUE #(
        %cid    = ls_key-%cid_ref
        orderid = ls_key-orderid
        %msg    = new_message(
          id       = 'ZROM_MSG'
          number   = 001
          v1       = 'Order Deleted Successfully'
          severity = if_abap_behv_message=>severity-success ) )
      TO reported-orderheader.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    LOOP AT keys INTO DATA(ls_key).

      SELECT SINGLE FROM zrom_header_t FIELDS *
        WHERE orderid = @ls_key-orderid
        INTO @DATA(ls_hdr).

      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_hdr ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD rba_Orderitems.
    LOOP AT keys_rba INTO DATA(ls_key).

      SELECT FROM zrom_item_t FIELDS *
        WHERE orderid = @ls_key-orderid
        INTO TABLE @DATA(lt_items).

      LOOP AT lt_items INTO DATA(ls_item).
        APPEND CORRESPONDING #( ls_item ) TO result.
        APPEND VALUE #(
          source-orderid = ls_key-orderid
          target-orderid = ls_item-orderid
          target-itemno  = ls_item-itemno )
        TO association_links.
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Orderitems.
    DATA ls_order_itm TYPE zrom_item_t.

    LOOP AT entities_cba INTO DATA(ls_entities_cba).
      ls_order_itm = CORRESPONDING #( ls_entities_cba-%target[ 1 ] ).

      IF ls_order_itm-orderid IS NOT INITIAL AND
         ls_order_itm-itemno  IS NOT INITIAL.

        SELECT FROM zrom_item_t FIELDS *
          WHERE orderid = @ls_order_itm-orderid
          AND   itemno  = @ls_order_itm-itemno
          INTO TABLE @DATA(lt_items).

        IF sy-subrc NE 0.
          "--- Auto calculate item total ---
          ls_order_itm-totalamount = ls_order_itm-quantity
                                   * ls_order_itm-price.
          ls_order_itm-currency    = 'INR'.

          DATA(lo_util) = zcl_rom_utility=>get_instance( ).
          lo_util->set_itm_value(
            EXPORTING im_order_itm = ls_order_itm
            IMPORTING ex_created   = DATA(lv_created) ).

          IF lv_created EQ abap_true.
            APPEND VALUE #(
              %cid    = ls_entities_cba-%target[ 1 ]-%cid
              orderid = ls_order_itm-orderid
              itemno  = ls_order_itm-itemno )
            TO mapped-orderitem.

            APPEND VALUE #(
              %cid    = ls_entities_cba-%target[ 1 ]-%cid
              orderid = ls_order_itm-orderid
              %msg    = new_message(
                id       = 'ZROM_MSG'
                number   = 001
                v1       = 'Item Added Successfully'
                severity = if_abap_behv_message=>severity-success ) )
            TO reported-orderitem.
          ENDIF.

        ELSE.
          "--- Duplicate Item ---
          APPEND VALUE #(
            %cid    = ls_entities_cba-%target[ 1 ]-%cid
            orderid = ls_order_itm-orderid
            itemno  = ls_order_itm-itemno )
          TO failed-orderitem.

          APPEND VALUE #(
            %cid    = ls_entities_cba-%target[ 1 ]-%cid
            orderid = ls_order_itm-orderid
            %msg    = new_message(
              id       = 'ZROM_MSG'
              number   = 002
              v1       = 'Duplicate Item in Order'
              severity = if_abap_behv_message=>severity-error ) )
          TO reported-orderitem.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD StartPreparing.
    LOOP AT keys INTO DATA(ls_key).

      SELECT SINGLE FROM zrom_header_t FIELDS *
        WHERE orderid = @ls_key-orderid
        INTO @DATA(ls_hdr).

      IF sy-subrc = 0.
        IF ls_hdr-orderstatus = 'Pending'.

          ls_hdr-orderstatus = 'Preparing'.
          DATA(lo_util) = zcl_rom_utility=>get_instance( ).
          lo_util->set_hdr_value(
            EXPORTING im_order_hdr = ls_hdr
            IMPORTING ex_created   = DATA(lv_created) ).
          lo_util->set_status_flag(
            EXPORTING im_status = 'Preparing' ).

          APPEND VALUE #( %key = ls_key-%key ) TO mapped-orderheader.
          APPEND CORRESPONDING #( ls_hdr )     TO result.

        ELSE.
          APPEND VALUE #(
            %key = ls_key-%key
            %msg = new_message(
              id       = 'ZROM_MSG'
              number   = 004
              v1       = 'Order must be in Pending status'
              severity = if_abap_behv_message=>severity-error ) )
          TO reported-orderheader.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD MarkCompleted.
    LOOP AT keys INTO DATA(ls_key).

      SELECT SINGLE FROM zrom_header_t FIELDS *
        WHERE orderid = @ls_key-orderid
        INTO @DATA(ls_hdr).

      IF sy-subrc = 0.
        IF ls_hdr-orderstatus = 'Preparing'.

          ls_hdr-orderstatus = 'Completed'.
          DATA(lo_util) = zcl_rom_utility=>get_instance( ).
          lo_util->set_hdr_value(
            EXPORTING im_order_hdr = ls_hdr
            IMPORTING ex_created   = DATA(lv_created) ).
          lo_util->set_status_flag(
            EXPORTING im_status = 'Completed' ).

          APPEND VALUE #( %key = ls_key-%key ) TO mapped-orderheader.
          APPEND CORRESPONDING #( ls_hdr )     TO result.

        ELSE.
          APPEND VALUE #(
            %key = ls_key-%key
            %msg = new_message(
              id       = 'ZROM_MSG'
              number   = 005
              v1       = 'Order must be in Preparing status'
              severity = if_abap_behv_message=>severity-error ) )
          TO reported-orderheader.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
