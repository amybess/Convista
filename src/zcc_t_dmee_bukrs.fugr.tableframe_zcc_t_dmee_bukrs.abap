*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZCC_T_DMEE_BUKRS
*   generation date: 05.08.2022 at 15:56:30
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZCC_T_DMEE_BUKRS   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
