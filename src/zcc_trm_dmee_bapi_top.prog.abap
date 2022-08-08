*&---------------------------------------------------------------------*
*& Include          ZCC_TRM_DMEE_BAPI_TOP
*&---------------------------------------------------------------------*
* BADI for tree_type-specific processing
CLASS cl_exithandler DEFINITION LOAD.
* Determination of line types of DMEE output tables
TYPE-POOLS sydes.

DATA: g_con TYPE num5.
DATA: g_con1 TYPE num5.
DATA: g_tabname TYPE tabname16.
DATA: git_struc_comp TYPE TABLE OF dd03p.
DATA: ref_tab TYPE REF TO data,
      ref_wat TYPE REF TO data.
FIELD-SYMBOLS: <fs_tab> TYPE STANDARD TABLE,          "e.g. MCSH: UMSATZ
               <fs_wat> TYPE any.


* Tela de Seleção -------------------------------------------------
* Indicações de formato
SELECTION-SCREEN: BEGIN OF BLOCK 1 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_tr_typ TYPE dmee_treetype_aba OBLIGATORY,
              p_tr_id  TYPE dmee_treeid_aba OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK 1.
* Tipo de Bapi
SELECTION-SCREEN: BEGIN OF BLOCK 2 WITH FRAME TITLE TEXT-003.
  PARAMETERS: p_tbapi TYPE zcc_tp_bapi OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK 2.
