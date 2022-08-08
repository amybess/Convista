
*&---------------------------------------------------------------------*
*& Report ZCC_TRM_DMEE_BAPI
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zcc_trm_dmee_bapi.

INCLUDE ZCC_TRM_DMEE_BAPI_top.

INCLUDE ZCC_TRM_DMEE_BAPI_f01.


START-OF-SELECTION.

  PERFORM f_selec_tab.

  PERFORM f_carrega_tab.

  CASE p_tbapi.
    WHEN '1'.
      PERFORM f_bapi_ftr_create USING    <fs_tab>
                                CHANGING <fs_wat>.
    WHEN '2'.
      PERFORM f_bapi_swap.
  ENDCASE.
