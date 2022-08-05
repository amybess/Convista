class ZCL_IM_CC_BD_DMEECONVERT definition
  public
  final
  create public .

public section.

  interfaces IF_EX_BADI_DMEECONVERT .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_CC_BD_DMEECONVERT IMPLEMENTATION.


  method IF_EX_BADI_DMEECONVERT~CALL_REPORT.
  endmethod.


  METHOD if_ex_badi_dmeeconvert~process_input_dme.

    DATA: lv_dme_format TYPE tree_id,
          lv_to_replace TYPE string,
          lv_replaced   TYPE string,
          is_s4         TYPE flag.
    FIELD-SYMBOLS:
        <fs_content> TYPE any.


    READ TABLE im_it_selection_fields ASSIGNING FIELD-SYMBOL(<fs_sel_fields>) WITH KEY selname = 'P_TR_ID'.

    IF <fs_sel_fields> IS ASSIGNED.
      SELECT SINGLE * INTO @DATA(wa_dmee_head)
        FROM dmee_tree_head
        WHERE tree_type = @flt_val
          AND tree_id = @<fs_sel_fields>-low
          AND version = 0.
      TRY.
          LOOP AT ch_it_init ASSIGNING FIELD-SYMBOL(<fs_init>).
            ASSIGN COMPONENT 'CONTENT' OF STRUCTURE  <fs_init> TO <fs_content>.
            FIND ALL OCCURRENCES OF PCRE '([' && wa_dmee_head-escape_symb && '])(?:(?=(\\?))\2.)*?\1' IN <fs_content> RESULTS DATA(result_tab).
*            FIND ALL OCCURRENCES OF REGEX wa_dmee_head-escape_symb &&
*                                          '[^' && wa_dmee_head-escape_symb && ']*' &&
*                                          wa_dmee_head-escape_symb &&
*                                          '|^[^' && wa_dmee_head-escape_symb && ']*$' IN <fs_content> RESULTS DATA(result_tab).
            LOOP AT result_tab INTO DATA(wa_result).
              lv_to_replace = <fs_content>+wa_result-offset(wa_result-length).
              lv_replaced = lv_to_replace.
              REPLACE ALL OCCURRENCES OF wa_dmee_head-comp_delim IN lv_replaced WITH space.
              REPLACE lv_to_replace IN <fs_content> WITH lv_replaced.
            ENDLOOP.
          ENDLOOP.
        CATCH cx_root.

      ENDTRY.
    ENDIF.
  ENDMETHOD.


  METHOD if_ex_badi_dmeeconvert~process_output_dme.

    FIELD-SYMBOLS:
      <fs_product_type> TYPE any,
      <fs_transaction_type> TYPE any.


    DATA: lv_gsart   TYPE gsart,
          lv_sfhaart TYPE tb_sfhaart,
          lv_tabname TYPE tabname16,
          ref_tab    TYPE REF TO data,
          ref_wat    TYPE REF TO data.


    READ TABLE im_it_selection_fields ASSIGNING FIELD-SYMBOL(<fs_sel_fields>) WITH KEY selname = 'P_TR_TYP'.

    IF <fs_sel_fields> IS ASSIGNED.


      LOOP AT ch_result_tab1 ASSIGNING FIELD-SYMBOL(<fs_wat>).

        ASSIGN COMPONENT 'PRODUCT_TYPE' OF STRUCTURE <fs_wat> TO <fs_product_type>.
        IF <fs_product_type> IS ASSIGNED.
          SELECT SINGLE gsart FROM zcc_t_dmee_gsart
            INTO lv_gsart
           WHERE ref_name = <fs_product_type>.

          <fs_product_type> = lv_gsart.
        ENDIF.

        ASSIGN COMPONENT 'TRANSACTION_TYPE' OF STRUCTURE <fs_wat> TO <fs_transaction_type>.
        IF <fs_transaction_type> IS ASSIGNED.
          SELECT SINGLE sfhaart FROM zcc_t_dmee_sfhaa
            INTO lv_sfhaart
           WHERE ref_name = <fs_transaction_type>.

          <fs_transaction_type> = lv_sfhaart.
        ENDIF.
      ENDLOOP.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
