*&---------------------------------------------------------------------*
*& Include          ZCC_TRM_DMEE_BAPI_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form f_selec_tab
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM
  f_selec_tab .
  DATA: lit_struc_comp TYPE TABLE OF dd03p,
        lwa_struc_comp TYPE dd03p,
        l_if_type      TYPE dmee_iftype_aba,
        lwa_type       TYPE dmee_type_aba.
* Read interface name from dmee_tree_type
  CALL FUNCTION 'DMEE_READ_DB_ABA'
    EXPORTING
      i_tabname  = 'TYPE'
      i_treetype = p_tr_typ
    IMPORTING
      e_type     = lwa_type
    EXCEPTIONS
      OTHERS     = 1.
  l_if_type = lwa_type-if_type.

* Get name of interface components
  CALL FUNCTION 'DDIF_TABL_GET'
    EXPORTING
      name          = l_if_type
    TABLES
      dd03p_tab     = git_struc_comp
    EXCEPTIONS
      illegal_input = 1.

* seleciona tabela com dados a serem processados
  SELECT SINGLE tab_name INTO g_tabname
    FROM zcc_tabela_ddme
    WHERE tr_typ = p_tr_typ
      AND if_typ = l_if_type.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE 'Tabela não cadastrada' TYPE 'E'.
  ENDIF.

* assinala formato conforme tabela selecionada
  CREATE DATA ref_tab TYPE STANDARD TABLE OF (g_tabname).
  ASSIGN ref_tab->* TO <fs_tab>.

  CREATE DATA ref_wat TYPE (g_tabname).
  ASSIGN ref_wat->* TO <fs_wat>.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_bapi_ftr_create
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_bapi_ftr_create USING   p_fs_it TYPE STANDARD TABLE
                      CHANGING p_fs_wa TYPE any.
  DATA: ls_forex               TYPE bapi_ftr_create_fxt,
        ls_GENERALCONTRACTDATA TYPE bapi_ftr_create,
        ls_ACTIVITY_CATEGORY   TYPE tb_sfgzuty.
  DATA l_company_code TYPE bukrs.
  DATA l_deal_number TYPE tb_rfha.
  DATA l_deal_number2 TYPE tb_rfha.
  DATA l_bapi_ret TYPE TABLE OF bapiret2.

  LOOP AT p_fs_it INTO p_fs_wa.

    CLEAR: ls_forex, ls_GENERALCONTRACTDATA.
    MOVE-CORRESPONDING p_fs_wa  TO <fs_wat>.
    MOVE-CORRESPONDING <fs_wat> TO ls_forex.
    MOVE-CORRESPONDING <fs_wat> TO ls_GENERALCONTRACTDATA.


    CALL FUNCTION 'BAPI_FTR_FXT_CREATE'
      EXPORTING
        forex                = ls_forex
        generalcontractdata  = ls_GENERALCONTRACTDATA
      IMPORTING
        financialtransaction = l_deal_number
        companycode          = l_company_code
      TABLES
        return               = l_bapi_ret.

    IF sy-subrc IS INITIAL.
      ADD 1 TO g_con1.
    ENDIF.


  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_bapi_swap
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_bapi_swap .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_carrega_tab
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_carrega_tab.

  SELECT *
    FROM (g_tabname)
    INTO TABLE <fs_tab>. "@data(lt_tab).

  LOOP AT <fs_tab> INTO <fs_wat>.
  ENDLOOP.

ENDFORM.
