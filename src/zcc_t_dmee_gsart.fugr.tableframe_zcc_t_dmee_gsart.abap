*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZCC_T_DMEE_GSART
*   generation date: 03.08.2022 at 17:18:55
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZCC_T_DMEE_GSART   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
