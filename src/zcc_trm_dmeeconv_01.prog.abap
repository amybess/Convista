*&---------------------------------------------------------------------*
*& Report  DMEECONVERT1
*&
*&---------------------------------------------------------------------*
*& 1. The report reads in a DME file of specified format and
*&    converts it into an internal table of linetype CHAR(1500).
*& 2. The report calls the DME Engine for incoming files (function
*&    group DMEE8).
*&    Input parameters:  internal table, DMEE format tree, output
*&                       format (tree type), selection on log handling
*&    Output parameters: internal table(s) with line type of output
*&                       format, logs
*& 3. The report converts the DMEE output table(s) into DME-file(s) of
*&    specified (standard) format and writes it to the presentation or
*&    application server.
*&
*& Note: For additional tree type-specific processing, the following
*&       BADI-methods are provided:
*&       (i)  BADI_DMEECONVERT->PROCESS_INPUT_DME
*&            for file modification directly after upload
*&       (ii) BADI_DMEECONVERT->PROCESS_OUTPUT_DME
*&            for modification of internal table(s) output by the DMEE
*&       (iii)BADI_DMEECONVERT->call_report
*&            for calling subsequent report for postings
*&       The filter value for this BADI is the DMEE tree type.
*&---------------------------------------------------------------------*

REPORT zcc_trm_dmeeconv_01.


INCLUDE zcc_trm_dmeeconv_01_top.      " global data declarations

INCLUDE zcc_trm_dmeeconv_01_ini.      " Initialization

INCLUDE zcc_trm_dmeeconv_01_sel.      " selection screen

INCLUDE zcc_trm_dmeeconv_01_f01.      " FORM-routines


***********************************************************************
*                       Main program
***********************************************************************
START-OF-SELECTION.

* Check tree layer ---------------------------------------------------
  CALL FUNCTION 'DMEE_CHECK_TYPE_LAYER'
    EXPORTING
      i_treetype = p_tr_typ
    IMPORTING
      e_layer    = tree_layer.

*------ Create data objects for DMEE output tables -------------------
  PERFORM get_linetype CHANGING linetype.

* internal tables
  CREATE DATA ref_it1 TYPE STANDARD TABLE OF (linetype-struc1).
  IF NOT linetype-struc2 IS INITIAL.
    CREATE DATA ref_it2 TYPE STANDARD TABLE OF (linetype-struc2).
  ENDIF.

  ASSIGN ref_it1->* TO <fs_it1>.
  IF NOT linetype-struc2 IS INITIAL.
    ASSIGN ref_it2->* TO <fs_it2>.
  ENDIF.

* corresponding work areas
  CREATE DATA ref_wa1 TYPE (linetype-struc1).
  IF NOT linetype-struc2 IS INITIAL.
    CREATE DATA ref_wa2 TYPE (linetype-struc2).
  ENDIF.

  ASSIGN ref_wa1->* TO <fs_wa1>.
  IF NOT linetype-struc2 IS INITIAL.
    ASSIGN ref_wa2->* TO <fs_wa2>.
  ENDIF.

*---------------------------------------------------------------------

  PERFORM upload.

*------ BADI-Exit for tree-type specific processing of read dme file ---
  IF tree_layer = 'ABA'.
    CALL METHOD cl_exithandler=>get_instance
      CHANGING
        instance = ref_to_badi.
  ELSE.   "tree layer is APPL
    CALL METHOD cl_exithandler=>get_instance
      EXPORTING
        exit_name = 'BADI_DMEECONVERT'
      CHANGING
        instance  = ref_to_badi_generic.
  ENDIF.

  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'   "read selection fields
    EXPORTING
      curr_report     = sy-repid
    TABLES
      selection_table = it_selection_fields.

  IF tree_layer = 'ABA'.
    CALL METHOD ref_to_badi->process_input_dme
      EXPORTING
        flt_val                = p_tr_typ
        im_it_selection_fields = it_selection_fields
      CHANGING
        ch_it_init             = it_init.
  ELSE.    "tree layer is APPL
    badi_method = 'IF_EX_BADI_DMEECONVERT~PROCESS_INPUT_DME'.
    CALL METHOD ref_to_badi_generic->(badi_method)
      EXPORTING
        flt_val                = p_tr_typ
        im_it_selection_fields = it_selection_fields
      CHANGING
        ch_it_init             = it_init.

  ENDIF.
*---------------------------------------------------------------------

  PERFORM convert_it_in USING    it_init
                        CHANGING it_dmeein.

  IF x_format_correct = ' '.
    MESSAGE s081(dmee_aba).           "wrong selection of record-format
    RETURN.
  ENDIF.

  PERFORM read_log_selection CHANGING log_selection.

*----- Call DME Engine -----------------------------------------------
  IF linetype-struc2 IS INITIAL.
    CALL FUNCTION 'DMEE_PROCESS_INCOMING_FILE_ABA'
      EXPORTING
        i_treetype        = p_tr_typ
        i_treeid          = p_tr_id
        i_parameter       = log_selection
      IMPORTING
        e_logh_summary    = logh_summary
        e_logh_error      = logh_error
      TABLES
        file_input        = it_dmeein
        result_tab1       = <fs_it1>
      EXCEPTIONS
        tree_incomplete   = 1
        tree_inconsistent = 2.
  ELSE.
    CALL FUNCTION 'DMEE_PROCESS_INCOMING_FILE_ABA'
      EXPORTING
        i_treetype        = p_tr_typ
        i_treeid          = p_tr_id
        i_parameter       = log_selection
      IMPORTING
        e_logh_summary    = logh_summary
        e_logh_error      = logh_error
      TABLES
        file_input        = it_dmeein
        result_tab1       = <fs_it1>
        result_tab2       = <fs_it2>
      EXCEPTIONS
        tree_incomplete   = 1
        tree_inconsistent = 2.
  ENDIF.


*------ BADI-Exit for tree-type specific processing of output dme file
  IF linetype-struc2 IS INITIAL.
    IF tree_layer = 'ABA'.
      CALL METHOD ref_to_badi->process_output_dme
        EXPORTING
          flt_val                = p_tr_typ
          im_it_selection_fields = it_selection_fields
          im_logh_summary        = logh_summary
          im_logh_error          = logh_error
        CHANGING
          ch_result_tab1         = <fs_it1>.
    ELSE.    "tree layer is APPL
      badi_method = 'IF_EX_BADI_DMEECONVERT~PROCESS_OUTPUT_DME'.
      CALL METHOD ref_to_badi_generic->(badi_method)
        EXPORTING
          flt_val                = p_tr_typ
          im_it_selection_fields = it_selection_fields
          im_logh_summary        = logh_summary
          im_logh_error          = logh_error
        CHANGING
          ch_result_tab1         = <fs_it1>.
    ENDIF.
  ELSE.
    IF tree_layer = 'ABA'.
      CALL METHOD ref_to_badi->process_output_dme
        EXPORTING
          flt_val                = p_tr_typ
          im_it_selection_fields = it_selection_fields
          im_logh_summary        = logh_summary
          im_logh_error          = logh_error
        CHANGING
          ch_result_tab1         = <fs_it1>
          ch_result_tab2         = <fs_it2>.
    ELSE.    "tree layer is APPL
      badi_method = 'IF_EX_BADI_DMEECONVERT~PROCESS_OUTPUT_DME'.
      CALL METHOD ref_to_badi_generic->(badi_method)
        EXPORTING
          flt_val                = p_tr_typ
          im_it_selection_fields = it_selection_fields
          im_logh_summary        = logh_summary
          im_logh_error          = logh_error
        CHANGING
          ch_result_tab1         = <fs_it1>
          ch_result_tab2         = <fs_it2>.
    ENDIF.
  ENDIF.

* Check whether error messages exist in log
  PERFORM error_msg_in_log CHANGING x_contains_error_msg.

* Error log and data content log
  IF x_log1 = 'X' OR p_typel2 <> '0' OR x_contains_error_msg = 'X'.
    PERFORM display_logs USING logh_summary logh_error.
  ENDIF.

  IF x_contains_error_msg = ' '.

* Convert DMEE output tables into dme files (add <CR/LF>, <END>)
    PERFORM convert_it_out USING    <fs_it1>
                           CHANGING it_dmeout1 <fs_wa1>.
**    IF NOT linetype-struc2 IS INITIAL.
**      PERFORM convert_it_out USING    <fs_it2>
**                             CHANGING it_dmeout2 <fs_wa2>.
**    ENDIF.

*** Save dme file
**    PERFORM download USING    it_dmeout1 '2'
**                     CHANGING dmeout_name2.
**    IF NOT linetype-struc2 IS INITIAL.
**      PERFORM download USING    it_dmeout2 '1'
**                       CHANGING dmeout_name1.
**    ENDIF.
**
*** BADI-Exit for calling subsequent report for postings
**    IF x_submit = 'X' AND NOT p_report IS INITIAL.
**      IF tree_layer = 'ABA'.
**        CALL METHOD ref_to_badi->call_report
**          EXPORTING
**            flt_val      = p_tr_typ
**            im_repname   = p_report
**            im_varname   = p_vari
**            im_filename1 = dmeout_name1
**            im_filename2 = dmeout_name2
**            im_x_pc      = rb1_dops.
**      ELSE.    "tree layer is APPL
**        badi_method = 'IF_EX_BADI_DMEECONVERT~CALL_REPORT'.
**        CALL METHOD ref_to_badi_generic->(badi_method)
**          EXPORTING
**            flt_val      = p_tr_typ
**            im_repname   = p_report
**            im_varname   = p_vari
**            im_filename1 = dmeout_name1
**            im_filename2 = dmeout_name2
**            im_x_pc      = rb1_dops.
**      ENDIF.
**  ENDIF.
**
  ELSE.
    MESSAGE s084(dmee_aba).
    RETURN.
  ENDIF.

  WRITE / 'FIM DO PROCESSAMENTO ---------------------------'.
  WRITE /: 'Total de registros gravados = ', g_con.
  WRITE / '------------------------------------------------'.

  IF p_bapi IS NOT INITIAL.
    PERFORM f_bapi USING    <fs_it1>
                   CHANGING <fs_wa1>.
  ENDIF.
*&---------------------------------------------------------------------*
*& Form f_bapi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_bapi USING    p_fs_it TYPE STANDARD TABLE
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
