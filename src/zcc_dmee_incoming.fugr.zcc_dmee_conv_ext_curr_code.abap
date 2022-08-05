FUNCTION ZCC_DMEE_CONV_EXT_CURR_CODE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_INTERFACE) TYPE  DMEE_EXIT_INTERFACE_INCOM_ABA
*"  EXPORTING
*"     REFERENCE(E_VALUE)
*"----------------------------------------------------------------------

DATA:
      lv_data_provider TYPE tb_dfname,
      lv_waers         TYPE waers.

  READ TABLE i_interface-ref_table INTO DATA(wa_ref) WITH KEY c_value = i_interface-node_value.

  IF sy-subrc = 0.
    lv_data_provider = wa_ref-ref_name.
    REPLACE ALL OCCURRENCES OF REGEX '[0-1]' IN lv_data_provider WITH ''.
    SELECT SINGLE waers FROM mducr INTO lv_waers
     WHERE vendor = lv_data_provider
       AND source = 'D'
       AND rkey1  = i_interface-node_value.

    IF sy-subrc = 0.
      e_value = lv_waers.
    ENDIF.
  ENDIF.



ENDFUNCTION.
