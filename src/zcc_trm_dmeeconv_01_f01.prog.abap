*&---------------------------------------------------------------------*
*&  Include           DMEECONVERT1_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  upload
*&---------------------------------------------------------------------*
*& Reads in text-file from PC or application server.
*& Regardless of the format of the read text file, each line
*& corresponds to one entry in it_init-content.
*& For uploads from PC: The length of the line is given in
*& it_init-length.
*&---------------------------------------------------------------------*
FORM upload.

  DATA: l_filelength TYPE i,
        l_filename   TYPE string,
        lt_init      TYPE STANDARD TABLE OF string, "note 2073464
        lwa_init     TYPE string,
        l_codepage   TYPE abap_encoding.


  l_filename = p_dmein.

* ------- Case 1: Upload from presentation server ---------------------
  IF rb1_upps = 'X'.

    IF  p_cdpage IS NOT INITIAL.                         "note 2073464
      l_codepage = p_cdpage .
    ENDIF.


    CALL METHOD cl_gui_frontend_services=>gui_upload     "note 2073464
      EXPORTING
        filename        = l_filename
        codepage        = l_codepage
      CHANGING
        data_tab        = lt_init
      EXCEPTIONS
        file_open_error = 1
        file_read_error = 2
        OTHERS          = 19.
    IF sy-subrc NE 0.
      MESSAGE e078(dmee_aba) WITH p_dmein.
    ELSE.
      LOOP AT lt_init INTO lwa_init.
        CLEAR wa_init.
        wa_init-length  = strlen( lwa_init ).
        wa_init-content = lwa_init.
        APPEND wa_init TO it_init.
      ENDLOOP.
    ENDIF.
* ------- Case 2: Upload from application server ---------------------
  ELSEIF rb2_upas = 'X'.
*    OPEN DATASET p_dmein  IN TEXT MODE ENCODING DEFAULT FOR INPUT
*                     IGNORING CONVERSION ERRORS.         "Note 1341395

    CALL FUNCTION 'FILE_VALIDATE_NAME'                   "note 2086464
      EXPORTING
        logical_filename           = c_dmee_upload_file
      CHANGING
        physical_filename          = l_filename
      EXCEPTIONS
        logical_filename_not_found = 1
        validation_failed          = 2
        OTHERS                     = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.


******************************Note 1347026*************
      IF p_cdpage IS INITIAL.
        OPEN DATASET l_filename  IN TEXT MODE ENCODING DEFAULT FOR INPUT.
      ELSE.
        OPEN DATASET l_filename  IN LEGACY TEXT MODE CODE PAGE
          p_cdpage FOR INPUT.
      ENDIF.
*****************Note 1347026''''''''''''''''''''''''''''''''''''

      IF sy-subrc NE 0.
        MESSAGE e078(dmee_aba) WITH l_filename.               "Provisorisch
      ENDIF.
      DO.
        CLEAR wa_init.
        READ DATASET l_filename INTO wa_init-content.
        IF sy-subrc EQ 0.                                  "Note 1260266
          APPEND wa_init TO it_init.
        ELSE.
          EXIT.
        ENDIF.
      ENDDO.
      CLOSE DATASET l_filename.

    ENDIF.

  ENDIF.

ENDFORM.                    " upload


*&---------------------------------------------------------------------*
*&      Form  convert_it_in
*&---------------------------------------------------------------------*
*& Converts p_it_init such that each entry in p_dmeein corresponds
*& to exactly one record.
*& Cuts off <cr/lf> and <END>.
*&---------------------------------------------------------------------*
FORM convert_it_in USING    p_it_init        LIKE it_init
                   CHANGING p_it_dmeein      LIKE it_dmeein.

  DATA: lwa_init   LIKE LINE OF p_it_init,
        lwa_dmeein LIKE LINE OF p_it_dmeein,
        l_pos      TYPE i,
        l_trash    TYPE string.

  CATCH SYSTEM-EXCEPTIONS data_offset_length_too_large = 1.

* ------- Case 1: Separation by <CR/LF> -------------------------------
    IF p_format = '0'.                    "Record-Begrenzung durch <CR/LF>

*   Check whether incoming file really contains <CR/LF>.
      CLEAR x_format_correct.
      LOOP AT p_it_init INTO lwa_init.
        IF lwa_init-content CS '<CR/LF>'.
          x_format_correct = 'X'.
          CLEAR: lwa_init.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF x_format_correct = ' '.
        RETURN.
      ENDIF.

      LOOP AT p_it_init INTO lwa_init.
        IF NOT lwa_init-content CS '<CR/LF>' AND
           NOT lwa_init-content CS '<END>'.
          IF lwa_init-length NE 0.
            lwa_dmeein+l_pos(lwa_init-length) = lwa_init-content.
          ENDIF.
          l_pos = l_pos + lwa_init-length.
        ELSE.
          SPLIT lwa_init-content AT   '<CR/LF>'
                                 INTO lwa_init-content l_trash.
          IF lwa_init-content CS '<END>'. "<CR/LF> must be before <END>
            EXIT.
          ENDIF.
          lwa_dmeein+l_pos = lwa_init-content.
          APPEND lwa_dmeein TO p_it_dmeein.
          CLEAR: lwa_dmeein, lwa_init, l_pos.
*       There are more than one '<CR/LF>' in text line
          WHILE l_trash CS '<CR/LF>'.
            lwa_init-content = l_trash.
            SPLIT lwa_init-content AT   '<CR/LF>'
                                   INTO lwa_init-content l_trash.
            lwa_dmeein = lwa_init-content.
            APPEND lwa_dmeein TO p_it_dmeein.
            CLEAR: lwa_dmeein.
          ENDWHILE.
        ENDIF.
      ENDLOOP.

* ------- Case 2: Each text line corresponds to exactly one record ----
    ELSEIF p_format = '1'.
      LOOP AT p_it_init INTO lwa_init.
        SPLIT lwa_init-content AT '<CR/LF>' INTO lwa_init-content l_trash.
        SPLIT lwa_init-content AT '<END>'   INTO lwa_dmeein l_trash.
        APPEND lwa_dmeein TO p_it_dmeein.
      ENDLOOP.

    ENDIF.

  ENDCATCH.
  IF sy-subrc = 1.
    MESSAGE e082(dmee_aba).
  ENDIF.

ENDFORM.                    "convert_it_in


*&---------------------------------------------------------------------*
*&      Form  get_linetype
*&---------------------------------------------------------------------*
*&  Reads linetype(s) for DMEE-output tables from database
*&---------------------------------------------------------------------*
FORM get_linetype CHANGING p_linetype LIKE linetype.

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
      dd03p_tab     = lit_struc_comp
    EXCEPTIONS
      illegal_input = 1.

  git_struc_comp[] = lit_struc_comp[]. " GM@@@

  CLEAR linetype.
  LOOP AT lit_struc_comp INTO lwa_struc_comp WHERE datatype = 'STRU'.
    IF p_linetype-struc1 IS INITIAL.
      p_linetype-struc1 = lwa_struc_comp-fieldname.
    ELSEIF p_linetype-struc2 IS INITIAL.
      p_linetype-struc2 = lwa_struc_comp-fieldname.
    ELSE.
      MESSAGE e074(dmee_aba).
    ENDIF.
  ENDLOOP.

  SELECT SINGLE tab_name INTO g_tabname
    FROM zcc_tabela_ddme
    WHERE tr_typ = p_tr_typ
      AND if_typ = l_if_type.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE 'Tabela não cadastrada' TYPE 'E'.
  ENDIF.
  CREATE DATA ref_tab TYPE STANDARD TABLE OF (g_tabname).
  ASSIGN ref_tab->* TO <fs_tab>.

  CREATE DATA ref_wat TYPE (g_tabname).

  ASSIGN ref_wat->* TO <fs_wat>.




ENDFORM.                    " get_linetype


*&---------------------------------------------------------------------*
*&      Form  read_log_selection
*&---------------------------------------------------------------------*
FORM read_log_selection CHANGING p_log_selection LIKE log_selection.

  IF x_log1 = 'X'.
    p_log_selection-error_log = 'X'.
  ENDIF.
  IF p_typel2 = '0'.
    p_log_selection-summary_log = '0'.
  ELSEIF p_typel2 = '1'.
    p_log_selection-summary_log = '1'.
  ELSEIF p_typel2 = '2'.
    p_log_selection-summary_log = '2'.
  ENDIF.

ENDFORM.                    " read_log_selection


*&---------------------------------------------------------------------*
*&      Form  convert_it_out
*&---------------------------------------------------------------------*
*& 1. Converts DMEE output table(s) <fs_it*> such that each entry in
*&    p_it_dmeout corresponds to one line in the output DME file.
*& 2. Reads delimiters from DMEE_TREE_TYPE and inserts them.
*&---------------------------------------------------------------------*
FORM convert_it_out USING    p_fs_it TYPE STANDARD TABLE
                    CHANGING p_it_dmeout LIKE it_dmeout1
                             p_fs_wa TYPE any.

  DATA: lwa_dmeout    LIKE LINE OF p_it_dmeout,
        l_length_fs   TYPE i,         "structure length
        l_pos_s       TYPE i,         "position in structure p_fs_wa
        l_pos_w       TYPE i,         "position in workarea lwa_dmeout
        l_no_comp     TYPE i,         "number of components in structure
        l_tab_ind     TYPE i,
        l_strucdesc   TYPE sydes_desc,  "description of structure type
        lwa_types     LIKE LINE OF l_strucdesc-types,
        lwa_tree_type TYPE dmee_type_aba,
        l_fdelim_len  TYPE i,           "length of field delimiter.
        l_fdelim      TYPE string,      "field delimiter
        l_rdelim      TYPE string,      "record delimiter
        l_gdelim      TYPE string.      "group delimiter

* -------------------------------------------------------------
  FIELD-SYMBOLS: <x_container> TYPE c,
                 <x_struc>     TYPE c.
  DATA: container(1000) TYPE c.

*  DATA: l_seq TYPE num5.
* -------------------------------------------------------------
* read delimiter information from DMEE_TREE_TYPE
  CALL FUNCTION 'DMEE_READ_DB_ABA'
    EXPORTING
      i_tabname  = 'TYPE'
      i_treetype = p_tr_typ
    IMPORTING
      e_type     = lwa_tree_type
    EXCEPTIONS
      OTHERS     = 1.

**  IF sy-subrc = 0.
**    l_fdelim = lwa_tree_type-field_delim.
**    l_fdelim_len = strlen( l_fdelim ).
**    l_rdelim = lwa_tree_type-rec_delim.
**    l_gdelim = lwa_tree_type-group_delim.
**  ENDIF.
**
**  CATCH SYSTEM-EXCEPTIONS conversion_errors = 1.
**
*** ------ Copy field content and insert field delimiter (if required) ---
**
**    DESCRIBE FIELD p_fs_wa INTO l_strucdesc.
**    DESCRIBE TABLE l_strucdesc-types LINES l_no_comp.
**
**  CLEAR g_con.

  LOOP AT p_fs_it INTO p_fs_wa.

    CLEAR: lwa_dmeout, l_pos_s, l_pos_w.
    l_tab_ind = 2.             "1st entry refers to entire structure

    MOVE-CORRESPONDING p_fs_wa TO <fs_wat>.
*    MOVE l_seq TO lwa_ZCC_ZFXDEAL-seq.
    MODIFY (g_tabname) FROM <fs_wat>.
    IF sy-subrc IS INITIAL.
      ADD 1 TO g_con.
    ENDIF.


  ENDLOOP.


*** ------ Insert record delimiter --------------------------------------
**
**  IF NOT l_rdelim IS INITIAL.
**
***     Determine position for record delimiter
**    l_pos_w = l_length_fs + ( l_no_comp - 2 ) * l_fdelim_len.
**
**    CLEAR lwa_dmeout.
**    LOOP AT p_it_dmeout INTO lwa_dmeout.
**      lwa_dmeout+l_pos_w = l_rdelim.
**      MODIFY p_it_dmeout FROM lwa_dmeout INDEX sy-tabix.
**    ENDLOOP.
**
***     Insert '<END>'
**    IF l_rdelim = '<CR/LF>'.
**      CLEAR lwa_dmeout.
**      lwa_dmeout = '<END>'.
**      APPEND lwa_dmeout TO p_it_dmeout.
**    ENDIF.
**
**  ENDIF.
**
*** ------ Insert group delimiter ---------------------------------------
**  IF NOT l_gdelim IS INITIAL.
***     MUSS NOCH IMPLEMENTIERT WERDEN!
**  ENDIF.
**
** ENDCATCH.

ENDFORM.                    "convert_it_out


*&---------------------------------------------------------------------*
*&      Form  download
*&---------------------------------------------------------------------*
* Writes dme file to presentation or to application server.
* If the treetype contains two structures, two files will be generated
* with the names <filename>_1* and <filename>_2*
*----------------------------------------------------------------------*
FORM download USING    p_it_dmeout LIKE it_dmeout1
                       p_nameno    TYPE c
              CHANGING p_filename  TYPE localfile.

  DATA: l_filename     TYPE string,
        hlp_filename   TYPE string,
        l_extension    TYPE string,
        lwa_dmeout     LIKE LINE OF p_it_dmeout,
        lit_dmeout_cut LIKE it_dmeout1,
        l_str          TYPE string,
        l_str_length   TYPE i,
        l_filepath     TYPE string,                         "1809918
        l_codepage     TYPE abap_encoding,                  "note 2073464
        l_fname        TYPE string.

  IF  p_cdpage IS NOT INITIAL.                              "note 2073464
    l_codepage = p_cdpage .
  ENDIF.

  PERFORM get_download_file_name USING p_nameno             "note 2086464
                        CHANGING l_filename.
  p_filename = l_filename.

* cut off last field DMEE_RELNUM (only for internal purposes)
  LOOP AT p_it_dmeout INTO lwa_dmeout.
    l_str = lwa_dmeout.
    l_str_length = strlen( l_str ) - 21.
    CLEAR lwa_dmeout+l_str_length(21).
    APPEND lwa_dmeout TO lit_dmeout_cut.
  ENDLOOP.

*** ------- Case 1: Save dme file on presentation server ---------------
**  IF rb1_dops = 'X'.
**    CALL FUNCTION 'GUI_DOWNLOAD'
**      EXPORTING
**        filename         = l_filename
**        filetype         = 'ASC'
**        codepage         = l_codepage                       "note 2073464
**      TABLES
**        data_tab         = lit_dmeout_cut
**      EXCEPTIONS
**        file_not_found   = 1
**        file_write_error = 2.
**
**    CASE sy-subrc.
**      WHEN 0.
**        IF p_nameno = '2' AND linetype-struc2 IS INITIAL.
**          MESSAGE s071(dmee_aba) WITH l_filename.
**        ELSEIF p_nameno = '1'.
**          hlp_filename = l_filename.
**          REPLACE '_1' IN hlp_filename WITH '_2'.
**          MESSAGE s072(dmee_aba) WITH l_filename hlp_filename.
**        ENDIF.
**      WHEN 1.
**        MESSAGE e070(dmee_aba) WITH l_filename.
**      WHEN 2.
**        MESSAGE e073(dmee_aba) WITH l_filename.
**    ENDCASE.
**
*** ------- Case 2: Save dme file on application server ---------------
**  ELSEIF rb2_doas = 'X'.
**    IF l_codepage IS INITIAL.
**      OPEN DATASET l_filename IN TEXT MODE FOR OUTPUT
***                            ENCODING NON-UNICODE *Note 1262145
**                             ENCODING DEFAULT
**                            IGNORING CONVERSION ERRORS.
**    ELSE.
**      OPEN DATASET l_filename IN LEGACY TEXT MODE CODE PAGE
**              l_codepage FOR OUTPUT IGNORING CONVERSION ERRORS.
**    ENDIF.
**    IF sy-subrc NE 0.
**      MESSAGE e073(dmee_aba) WITH l_filename.
**    ENDIF.
**
**    LOOP AT lit_dmeout_cut INTO lwa_dmeout.
**      TRANSFER lwa_dmeout TO l_filename.
**      IF sy-subrc NE 0.
**        EXIT.
**      ENDIF.
**    ENDLOOP.
**
**    CLOSE DATASET l_filename.
**
**    IF sy-subrc EQ 0.
**      IF p_nameno = '2' AND linetype-struc2 IS INITIAL.
**        MESSAGE s071(dmee_aba) WITH l_filename.
**      ELSEIF p_nameno = '1'.
**        hlp_filename = l_filename.
**        REPLACE '_1' IN hlp_filename WITH '_2'.
**        MESSAGE s072(dmee_aba) WITH l_filename hlp_filename.
**      ENDIF.
**    ENDIF.
**  ENDIF.

ENDFORM.                    " download

*&---------------------------------------------------------------------*
*&      Form error_msg_in_log
*&---------------------------------------------------------------------*
*       Check whether error messages exist in logs.
*----------------------------------------------------------------------*

FORM error_msg_in_log CHANGING p_x_contains_error_msg TYPE xfeld.

  DATA: l_s_msg_filter TYPE bal_s_mfil,
        l_r_msgty      TYPE bal_s_msty.

* Define message type (error):
  l_r_msgty-option   = 'EQ'.
  l_r_msgty-sign     = 'I'.
  l_r_msgty-low      = 'E'. "Fehler
  APPEND l_r_msgty TO l_s_msg_filter-msgty.

  CALL FUNCTION 'BAL_GLB_SEARCH_MSG'
    EXPORTING
      i_s_msg_filter = l_s_msg_filter
    EXCEPTIONS
      msg_not_found  = 1.

  IF sy-subrc = 0.
    p_x_contains_error_msg = 'X'.
  ENDIF.

ENDFORM.                    "error_msg_in_log

*&---------------------------------------------------------------------*
*&      Form  display_logs
*&---------------------------------------------------------------------*
*       Display error log and/or data content log
*----------------------------------------------------------------------*

FORM display_logs USING    p_logh_summary TYPE balloghndl
                           p_logh_error   TYPE balloghndl.

  DATA:  l_profile      TYPE bal_s_prof.

  CALL FUNCTION 'BAL_DSP_PROFILE_POPUP_GET'
    IMPORTING
      e_s_display_profile = l_profile.

  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
    EXPORTING
      i_s_display_profile = l_profile
      i_amodal            = 'X'
    EXCEPTIONS
      no_data_available   = 1.

  IF sy-subrc = 1.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " display_logs
*&---------------------------------------------------------------------*
*&      Form  GET_DOWNLOAD_FILE_NAME
*&---------------------------------------------------------------------*
*       Validate and specify the physical download file name
*----------------------------------------------------------------------*
FORM get_download_file_name USING p_nameno    TYPE c
                CHANGING p_filename  TYPE string.
  DATA:
    l_filename  TYPE string,
    l_extension TYPE string,
    l_filepath  TYPE string,
    l_fname     TYPE string.

**  l_filename = p_dmeout.
**
***   generate filenames if two output files are generated
***   e.g. for MCSH: AUSZUG = <name>_1.txt, UMSATZ = <name>_2.txt
**  IF NOT linetype-struc2 IS INITIAL.
**    IF l_filename CA '.'.
***     Split file name und file path
**      CALL FUNCTION 'TRINT_SPLIT_FILE_AND_PATH'             "note 2073464
**        EXPORTING
**          full_name     = l_filename
**        IMPORTING
**          stripped_name = l_filename
**          file_path     = l_filepath
**        EXCEPTIONS
**          x_error       = 1
**          OTHERS        = 2.
**
**      IF sy-subrc <> 0.
**        CONCATENATE l_filename '_' p_nameno INTO l_filename.
**      ELSE.
***       Split the filename, and extension
**        CALL METHOD cl_bcs_utilities=>split_name
**          EXPORTING
**            iv_name      = l_filename
***           iv_delimiter = GC_DOT
**          IMPORTING
**            ev_name      = l_fname
**            ev_extension = l_extension.
**
**        CONCATENATE l_filepath l_fname '_' p_nameno '.' l_extension
**            INTO l_filename.
**
**      ENDIF.
**
**    ELSE.
**      CONCATENATE l_filename '_' p_nameno  INTO l_filename.                                              "eoi 1809918
**    ENDIF.
**  ENDIF.
**
*** ------- Check file name in case of dme file on application server ---------------
**  IF rb2_doas = 'X'.
**    CALL FUNCTION 'FILE_VALIDATE_NAME'
**      EXPORTING
**        logical_filename           = c_dmee_download_file
**        parameter_1                = sy-cprog
**      CHANGING
**        physical_filename          = l_filename
**      EXCEPTIONS
**        logical_filename_not_found = 1
**        validation_failed          = 2
**        OTHERS                     = 3.
**    IF sy-subrc <> 0.
**      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**    ENDIF.
**  ENDIF.
**
**
**  p_filename = l_filename.

ENDFORM.
