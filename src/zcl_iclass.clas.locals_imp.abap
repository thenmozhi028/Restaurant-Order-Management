CLASS lhc_OrderItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE OrderItem.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE OrderItem.

    METHODS read FOR READ
      IMPORTING keys FOR READ OrderItem RESULT result.

    METHODS rba_OrderHeader FOR READ
      IMPORTING keys_rba FOR READ OrderItem\_orderHeader
      FULL result_requested RESULT result LINK association_links.

ENDCLASS.


CLASS lhc_OrderItem IMPLEMENTATION.
  METHOD update.
    DATA: ls_order_itm TYPE zrom_item_t.

    LOOP AT entities INTO DATA(ls_entities).
      ls_order_itm = CORRESPONDING #( ls_entities MAPPING FROM ENTITY ).

      IF ls_order_itm-orderid IS NOT INITIAL AND
         ls_order_itm-itemno  IS NOT INITIAL.

        SELECT FROM zrom_item_t FIELDS *
          WHERE orderid = @ls_order_itm-orderid
          AND   itemno  = @ls_order_itm-itemno
          INTO TABLE @DATA(lt_order_itm).

        IF sy-subrc EQ 0.
          "--- Recalculate total → Update buffer ---
          ls_order_itm-totalamount = ls_order_itm-quantity
                                   * ls_order_itm-price.

          DATA(lo_util) = zcl_rom_utility=>get_instance( ).
          lo_util->set_itm_value(
            EXPORTING im_order_itm = ls_order_itm
            IMPORTING ex_created   = DATA(lv_created) ).

          IF lv_created EQ abap_true.
            APPEND VALUE #(
              orderid = ls_order_itm-orderid
              itemno  = ls_order_itm-itemno )
            TO mapped-orderitem.

            APPEND VALUE #(
              %key = ls_entities-%key
              %msg = new_message(
                id       = 'ZROM_MSG'
                number   = 001
                v1       = 'Item Updated Successfully'
                severity = if_abap_behv_message=>severity-success ) )
            TO reported-orderitem.
          ENDIF.

        ELSE.
          "--- Item Not Found ---
          APPEND VALUE #(
            %cid    = ls_entities-%cid_ref
            orderid = ls_order_itm-orderid
            itemno  = ls_order_itm-itemno )
          TO failed-orderitem.

          APPEND VALUE #(
            %cid    = ls_entities-%cid_ref
            orderid = ls_order_itm-orderid
            %msg    = new_message(
              id       = 'ZROM_MSG'
              number   = 003
              v1       = 'Item Not Found'
              severity = if_abap_behv_message=>severity-error ) )
          TO reported-orderitem.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    DATA: ls_order_itm TYPE zcl_rom_utility=>ty_order_item.
    DATA(lo_util) = zcl_rom_utility=>get_instance( ).

    LOOP AT keys INTO DATA(ls_key).
      CLEAR ls_order_itm.
      ls_order_itm-orderid = ls_key-orderid.
      ls_order_itm-itemno  = ls_key-itemno.

      lo_util->set_itm_t_deletion(
        EXPORTING im_order_itm = ls_order_itm ).

      APPEND VALUE #(
        %cid    = ls_key-%cid_ref
        orderid = ls_key-orderid
        itemno  = ls_key-itemno
        %msg    = new_message(
          id       = 'ZROM_MSG'
          number   = 001
          v1       = 'Item Deleted Successfully'
          severity = if_abap_behv_message=>severity-success ) )
      TO reported-orderitem.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    LOOP AT keys INTO DATA(ls_key).

      SELECT SINGLE FROM zrom_item_t FIELDS *
        WHERE orderid = @ls_key-orderid
        AND   itemno  = @ls_key-itemno
        INTO @DATA(ls_itm).

      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_itm ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_OrderHeader.
    LOOP AT keys_rba INTO DATA(ls_key).

      SELECT SINGLE FROM zrom_header_t FIELDS *
        WHERE orderid = @ls_key-orderid
        INTO @DATA(ls_hdr).

      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_hdr ) TO result.
        APPEND VALUE #(
          source-orderid = ls_key-orderid
          source-itemno  = ls_key-itemno
          target-orderid = ls_hdr-orderid )
        TO association_links.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
