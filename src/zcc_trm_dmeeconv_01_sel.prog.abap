*&---------------------------------------------------------------------*
*&  Include           DMEECONVERT1_SEL
*&---------------------------------------------------------------------*
* Indicações de formato
SELECTION-SCREEN: BEGIN OF BLOCK 1 WITH FRAME TITLE text-002.
PARAMETERS: p_tr_typ TYPE dmee_treetype_aba OBLIGATORY,
            p_tr_id  TYPE dmee_treeid_aba OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK 1.

SELECTION-SCREEN: BEGIN OF BLOCK 1a WITH FRAME TITLE text-008.
PARAMETERS: p_bapi AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK 1a.

* File IDS de Entrada
SELECTION-SCREEN: BEGIN OF BLOCK 2 WITH FRAME TITLE text-001.
PARAMETERS: rb1_upps TYPE xfeld RADIOBUTTON GROUP up_s DEFAULT 'X',
            rb2_upas TYPE xfeld RADIOBUTTON GROUP up_s,
            p_dmein  LIKE rlgrap-filename OBLIGATORY,
            p_format TYPE dmee_dmeformat_aba DEFAULT '0',
            p_cdpage LIKE tcp00-CPCODEPAGE.
SELECTION-SCREEN: END OF BLOCK 2.

*** Ausgegebene Datei
**SELECTION-SCREEN: BEGIN OF BLOCK 3 WITH FRAME TITLE text-003.
**PARAMETERS: rb1_dops TYPE xfeld RADIOBUTTON GROUP do_s DEFAULT 'X',
**            rb2_doas TYPE xfeld RADIOBUTTON GROUP do_s,
**            p_dmeout TYPE dmee_outputdme_aba OBLIGATORY.
**SELECTION-SCREEN: END OF BLOCK 3.

* Protocols
SELECTION-SCREEN: BEGIN OF BLOCK 4 WITH FRAME TITLE text-004.
PARAMETERS: x_log1   TYPE dmee_error_log_aba AS CHECKBOX DEFAULT 'X'.
PARAMETERS: p_typel2 TYPE dmee_summary_log_aba DEFAULT '0'.
SELECTION-SCREEN: END OF BLOCK 4.

*** Verbuchung (Weitergabe an RFEBKA00)
**SELECTION-SCREEN: BEGIN OF BLOCK 5 WITH FRAME TITLE text-007.
**PARAMETERS: x_submit TYPE dmee_call_report_aba,
**            p_report TYPE dmee_repname_aba,
**            p_vari   TYPE dmee_varname_aba.
**SELECTION-SCREEN: END OF BLOCK 5.


*************************************************************
AT SELECTION-SCREEN.

* check: dmee_tree_type-category = '1' (incoming files)
  CALL FUNCTION 'DMEE_READ_DB_ABA'
    EXPORTING
      i_tabname  = 'TYPE'
      i_treetype = p_tr_typ
    IMPORTING
      e_type     = wa_type
    EXCEPTIONS
      OTHERS     = 1.
  hlp_category = wa_type-category.
  IF hlp_category NE '1'.
    MESSAGE e076(dmee_aba).
  ENDIF.

* check: An active version exists
  CALL FUNCTION 'DMEE_READ_DB_ABA'
    EXPORTING
      i_tabname  = 'HEAD'
      i_treetype = p_tr_typ
      i_treeid   = p_tr_id
      i_version  = c_active_version
    IMPORTING
      e_head     = wa_head
    EXCEPTIONS
      NOT_SELECTED = 1
      OTHERS     = 2.
  IF sy-subrc NE 0.
    MESSAGE e077(dmee_aba) WITH p_tr_id p_tr_typ.
  ENDIF.

* check: Record format is 0 or 1.
  IF p_format <> 0 AND p_format <> 1.
    MESSAGE e085(dmee_aba).
  ENDIF.

* F4-help for input file name
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_dmein.
  CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
    EXPORTING
      static    = 'X'
    CHANGING
      file_name = p_dmein.

*** F4-help for output file name
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_dmeout.
**  CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
**    EXPORTING
**      static    = 'X'
**    CHANGING
**      file_name = p_dmeout.
