CLASS zcl_rom_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_order_hdr,
             orderid TYPE char10,
           END OF ty_order_hdr,

           BEGIN OF ty_order_item,
             orderid TYPE char10,
             itemno  TYPE n LENGTH 6,
           END OF ty_order_item.

    TYPES: tt_order_hdr  TYPE STANDARD TABLE OF ty_order_hdr,
           tt_order_item TYPE STANDARD TABLE OF ty_order_item.

    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO zcl_rom_utility.    "← Fixed: was zcl_rom_util_umg

    METHODS:
      set_hdr_value
        IMPORTING im_order_hdr TYPE zrom_header_t
        EXPORTING ex_created   TYPE abap_boolean,

      get_hdr_value
        EXPORTING ex_order_hdr TYPE zrom_header_t,

      set_itm_value
        IMPORTING im_order_itm TYPE zrom_item_t
        EXPORTING ex_created   TYPE abap_boolean,

      get_itm_value
        EXPORTING ex_order_itm TYPE zrom_item_t,

      set_hdr_t_deletion
        IMPORTING im_order_hdr TYPE ty_order_hdr,

      get_hdr_t_deletion
        EXPORTING ex_order_hdrs TYPE tt_order_hdr,

      set_itm_t_deletion
        IMPORTING im_order_itm TYPE ty_order_item,

      get_itm_t_deletion
        EXPORTING ex_order_itms TYPE tt_order_item,

      set_hdr_deletion_flag
        IMPORTING im_order_delete TYPE abap_boolean,

      get_deletion_flags
        EXPORTING ex_order_hdr_del TYPE abap_boolean,

      set_status_flag
        IMPORTING im_status TYPE char15,

      get_status_flag
        EXPORTING ex_status TYPE char15,

      cleanup_buffer.

  PRIVATE SECTION.
    CLASS-DATA: gs_order_hdr_buff   TYPE zrom_header_t,
                gs_order_itm_buff   TYPE zrom_item_t,
                gt_order_hdr_t_buff TYPE tt_order_hdr,
                gt_order_itm_t_buff TYPE tt_order_item,
                gv_order_delete     TYPE abap_boolean,
                gv_status_flag      TYPE char15.

    CLASS-DATA mo_instance          TYPE REF TO zcl_rom_utility.  "← Fixed: was zcl_rom_util_umg

ENDCLASS.


CLASS zcl_rom_utility IMPLEMENTATION.

  METHOD get_instance.
    IF mo_instance IS INITIAL.
      CREATE OBJECT mo_instance.
    ENDIF.
    ro_instance = mo_instance.
  ENDMETHOD.

  METHOD set_hdr_value.
    IF im_order_hdr-orderid IS NOT INITIAL.
      gs_order_hdr_buff = im_order_hdr.
      ex_created = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD get_hdr_value.
    ex_order_hdr = gs_order_hdr_buff.
  ENDMETHOD.

  METHOD set_itm_value.
    IF im_order_itm IS NOT INITIAL.
      gs_order_itm_buff = im_order_itm.
      ex_created = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD get_itm_value.
    ex_order_itm = gs_order_itm_buff.
  ENDMETHOD.

  METHOD set_hdr_t_deletion.
    APPEND im_order_hdr TO gt_order_hdr_t_buff.
  ENDMETHOD.

  METHOD get_hdr_t_deletion.
    ex_order_hdrs = gt_order_hdr_t_buff.
  ENDMETHOD.

  METHOD set_itm_t_deletion.
    APPEND im_order_itm TO gt_order_itm_t_buff.
  ENDMETHOD.

  METHOD get_itm_t_deletion.
    ex_order_itms = gt_order_itm_t_buff.
  ENDMETHOD.

  METHOD set_hdr_deletion_flag.
    gv_order_delete = im_order_delete.
  ENDMETHOD.

  METHOD get_deletion_flags.
    ex_order_hdr_del = gv_order_delete.
  ENDMETHOD.

  METHOD set_status_flag.
    CASE im_status.
      WHEN 'Pending' OR 'Preparing' OR 'Completed'.
        gv_status_flag = im_status.
      WHEN OTHERS.
        gv_status_flag = 'Pending'.
    ENDCASE.
  ENDMETHOD.

  METHOD get_status_flag.
    ex_status = gv_status_flag.
  ENDMETHOD.

  METHOD cleanup_buffer.
    CLEAR: gs_order_hdr_buff,
           gs_order_itm_buff,
           gt_order_hdr_t_buff,
           gt_order_itm_t_buff,
           gv_order_delete,
           gv_status_flag.
  ENDMETHOD.

ENDCLASS.
