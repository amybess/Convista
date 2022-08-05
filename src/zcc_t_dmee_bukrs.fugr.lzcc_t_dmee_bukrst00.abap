*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZCC_T_DMEE_BUKRS................................*
DATA:  BEGIN OF STATUS_ZCC_T_DMEE_BUKRS              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZCC_T_DMEE_BUKRS              .
CONTROLS: TCTRL_ZCC_T_DMEE_BUKRS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZCC_T_DMEE_BUKRS              .
TABLES: ZCC_T_DMEE_BUKRS               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
