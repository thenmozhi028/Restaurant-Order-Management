CLASS lsc_ZROM_I_ORDER_H DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize          REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save              REDEFINITION.
    METHODS cleanup           REDEFINITION.
    METHODS cleanup_finalize  REDEFINITION.

ENDCLASS.


CLASS lsc_ZROM_I_ORDER_H IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.


  METHOD check_before_save.
    DATA(lo_util) = zcl_rom_utility=>get_instance( ).

    "--- Get Header Buffer ---
    lo_util->get_hdr_value(
      IMPORTING ex_order_hdr = DATA(ls_hdr) ).

    "--- Validate Customer Name ---
    IF ls_hdr-orderid IS NOT INITIAL.
      IF ls_hdr-customername IS INITIAL.
        APPEND VALUE #(
          %key = ls_hdr-orderid
          %msg = new_message(
            id       = 'ZROM_MSG'
            number   = 006
            v1       = 'Customer Name is mandatory'
            severity = if_abap_behv_message=>severity-error ) )
        TO reported-orderheader.
      ENDIF.

      "--- Validate Table Number ---
      IF ls_hdr-tableno IS INITIAL.
        APPEND VALUE #(
          %key = ls_hdr-orderid
          %msg = new_message(
            id       = 'ZROM_MSG'
            number   = 007
            v1       = 'Table Number is mandatory'
            severity = if_abap_behv_message=>severity-error ) )
        TO reported-orderheader.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD save.
    DATA(lo_util) = zcl_rom_utility=>get_instance( ).

    "--- Get Header Buffer ---
    lo_util->get_hdr_value(
      IMPORTING ex_order_hdr = DATA(ls_hdr) ).

    "--- Get Item Buffer ---
    lo_util->get_itm_value(
      IMPORTING ex_order_itm = DATA(ls_itm) ).

    "--- Get Deletion Flags ---
    lo_util->get_deletion_flags(
      IMPORTING ex_order_hdr_del = DATA(lv_hdr_del) ).

    lo_util->get_hdr_t_deletion(
      IMPORTING ex_order_hdrs = DATA(lt_hdr_del) ).

    lo_util->get_itm_t_deletion(
      IMPORTING ex_order_itms = DATA(lt_itm_del) ).

    IF ls_hdr-orderid IS NOT INITIAL.
      SELECT SINGLE FROM zrom_header_t FIELDS *
        WHERE orderid = @ls_hdr-orderid
        INTO @DATA(ls_existing_hdr).

      IF sy-subrc NE 0.
        "--- INSERT new order ---
        INSERT zrom_header_t FROM @ls_hdr.
      ELSE.
        "--- UPDATE existing order ---
        UPDATE zrom_header_t FROM @ls_hdr.
      ENDIF.
    ENDIF.

    IF ls_itm-orderid IS NOT INITIAL.
      SELECT SINGLE FROM zrom_item_t FIELDS *
        WHERE orderid = @ls_itm-orderid
        AND   itemno  = @ls_itm-itemno
        INTO @DATA(ls_existing_itm).

      IF sy-subrc NE 0.
        "--- INSERT new item ---
        INSERT zrom_item_t FROM @ls_itm.
      ELSE.
        "--- UPDATE existing item ---
        UPDATE zrom_item_t FROM @ls_itm.
      ENDIF.

      "--- Recalculate Header Grand Total ---
      SELECT SUM( totalamount )
        FROM zrom_item_t
        WHERE orderid = @ls_itm-orderid
        INTO @DATA(lv_total).

      UPDATE zrom_header_t
        SET totalamount = @lv_total
        WHERE orderid   = @ls_itm-orderid.
    ENDIF.

    LOOP AT lt_itm_del INTO DATA(ls_itm_del).
      DELETE FROM zrom_item_t
        WHERE orderid = @ls_itm_del-orderid
        AND   itemno  = @ls_itm_del-itemno.

      "--- Recalculate Header Total after item delete ---
      SELECT SUM( totalamount )
        FROM zrom_item_t
        WHERE orderid = @ls_itm_del-orderid
        INTO @DATA(lv_new_total).

      UPDATE zrom_header_t
        SET totalamount = @lv_new_total
        WHERE orderid   = @ls_itm_del-orderid.
    ENDLOOP.

    IF lv_hdr_del EQ abap_true.
      LOOP AT lt_hdr_del INTO DATA(ls_hdr_del).
        "--- Delete child items first ---
        DELETE FROM zrom_item_t
          WHERE orderid = @ls_hdr_del-orderid.

        "--- Then delete header ---
        DELETE FROM zrom_header_t
          WHERE orderid = @ls_hdr_del-orderid.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.


  METHOD cleanup.
    DATA(lo_util) = zcl_rom_utility=>get_instance( ).
    lo_util->cleanup_buffer( ).
  ENDMETHOD.

ENDCLASS.
