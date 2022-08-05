FUNCTION ZCC_DMEE_COUNTERPARTY_BP.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_INTERFACE) TYPE  DMEE_EXIT_INTERFACE_INCOM_ABA
*"  EXPORTING
*"     REFERENCE(E_VALUE)
*"----------------------------------------------------------------------

DATA:
      lt_partner_guid TYPE TABLE OF bus_partner_guid,
      lt_return       TYPE TABLE OF bapiret2,
      lv_bu_id_type   TYPE bu_id_type,
      lv_id_number    LIKE bapibus1006_identification_key-identificationnumber.


  READ TABLE i_interface-ref_table INTO DATA(wa_ref) WITH KEY c_value = i_interface-node_value.
  IF sy-subrc = 0.
    lv_bu_id_type = wa_ref-ref_name.
  ELSE.
    lv_bu_id_type = space.
  ENDIF.
  lv_id_number = i_interface-node_value.

  CALL FUNCTION 'FMCA_PARTNER_GET_BY_IDNUMBER'
    EXPORTING
      iv_identificationtype         = lv_bu_id_type
      iv_identificationnumber       =  lv_id_number
    TABLES
     t_partner_guid                = lt_partner_guid
     et_return                     = lt_return.

  IF lt_return[] is INITIAL.
   READ TABLE lt_partner_guid INDEX 1 INTO DATA(wa_partner).
   e_value = wa_partner-partner.
  ELSE.
    CLEAR e_value.
    " Insert a message in the log table??
  ENDIF.



ENDFUNCTION.
