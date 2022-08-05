*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZCC_T_DMEE_GSART................................*
DATA:  BEGIN OF STATUS_ZCC_T_DMEE_GSART              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZCC_T_DMEE_GSART              .
CONTROLS: TCTRL_ZCC_T_DMEE_GSART
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZCC_T_DMEE_GSART              .
TABLES: ZCC_T_DMEE_GSART               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
