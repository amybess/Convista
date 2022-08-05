FUNCTION zcc_dmee_conv_ext_company.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_INTERFACE) TYPE  DMEE_EXIT_INTERFACE_INCOM_ABA
*"  EXPORTING
*"     REFERENCE(E_VALUE)
*"----------------------------------------------------------------------

  DATA:
    lv_data_provider TYPE tb_dfname,
    lv_bukrs         TYPE bukrs.

  READ TABLE i_interface-ref_table INTO DATA(wa_ref) WITH KEY c_value = i_interface-node_value.

  IF sy-subrc = 0.
    lv_data_provider = wa_ref-ref_name.
    SELECT SINGLE bukrs FROM zcc_t_dmee_bukrs INTO lv_bukrs
     WHERE rfeedname = lv_data_provider
       AND extbukrs  = i_interface-node_value.

    IF sy-subrc = 0.
      e_value = lv_bukrs.
    ELSE.
      CLEAR e_value.
    ENDIF.
  ENDIF.


ENDFUNCTION.
