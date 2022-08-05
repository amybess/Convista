*&---------------------------------------------------------------------*
*&  Include           DMEECONVERT1_TOP
*&---------------------------------------------------------------------*
* Table, in which each entry corresponds to one line in read text-file:
DATA: BEGIN OF wa_init,
        length  TYPE i,
*        content(10000) TYPE c,
        content TYPE string,
      END OF wa_init,

      it_init LIKE TABLE OF wa_init.

* Input table for DMEE: Each entry corresponds to one record in DME file
DATA: it_dmeein TYPE TABLE OF dmee_input_file_aba.

* Output table: Each entry corresponds to one record in output DME-file
DATA: it_dmeout1   TYPE TABLE OF dmee_input_file_aba,
      it_dmeout2   TYPE TABLE OF dmee_input_file_aba,
      dmeout_name1 TYPE localfile,    "Name of level1 output file
      dmeout_name2 TYPE localfile.    "Name of level2 output file

* Log handling:
DATA: log_selection        LIKE dmee_par_incoming_aba,
      logh_summary         TYPE balloghndl,
      logh_error           TYPE balloghndl,
      x_contains_error_msg TYPE xfeld.

* BADI for tree_type-specific processing
CLASS cl_exithandler DEFINITION LOAD.
DATA: ref_to_badi         TYPE REF TO   if_ex_badi_dmeeconvert_aba,
      ref_to_badi_generic TYPE REF TO   object,
      it_selection_fields TYPE TABLE OF rsparams.

* Determination of line types of DMEE output tables
TYPE-POOLS sydes.

DATA: BEGIN OF linetype,
        struc1 TYPE string,                          "e.g. MCSH: UMSATZ
        struc2 TYPE string,                          "e.g. MCSH: AUSZUG
      END OF linetype,
      ref_it1 TYPE REF TO data,
      ref_it2 TYPE REF TO data,
      ref_wa1 TYPE REF TO data,
      ref_wa2 TYPE REF TO data.
DATA: ref_tab TYPE REF TO data,
      ref_wat TYPE REF TO data.


FIELD-SYMBOLS: <fs_it1> TYPE STANDARD TABLE,          "e.g. MCSH: UMSATZ
               <fs_wa1> TYPE any,
               <fs_it2> TYPE STANDARD TABLE,          "e.g. MCSH: AUSZUG
               <fs_wa2> TYPE any.
FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE,          "e.g. MCSH: UMSATZ
               <fs_wat> TYPE any.


* Help variables for checks at_selection_screen
DATA: hlp_category          TYPE dmee_category_aba,
      hlp_wa_dmee_tree_head LIKE dmee_head_aba,
      x_format_correct      TYPE xfeld VALUE 'X',
      wa_type               TYPE dmee_type_aba,
      wa_head               TYPE dmee_head_aba.

* BADI calls
DATA: tree_layer(4)   TYPE c,      "tree type is ABA or APPL type
      badi_method(50) TYPE c.

* Constants
CONSTANTS: c_active_version     TYPE dmee_version_aba VALUE '000',
           c_dmee_download_file TYPE fileintern VALUE 'DMEE_DOWNLOAD_FILE', "note 2086464
           c_dmee_upload_file   TYPE fileintern VALUE 'DMEE_UPLOAD_FILE'.

*----------------------------------------------------------------------------------------------
DATA: git_struc_comp TYPE TABLE OF dd03p.
DATA: g_con TYPE num5.
DATA: g_tabname TYPE tabname16.
