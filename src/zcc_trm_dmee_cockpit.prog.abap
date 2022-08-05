*----------------------------------------------------------------------*
*  Objeto   : ZCC_TRM_DMEE_COCKPIT                                     *
*  Transação:                                                          *
*  Descrição: Cockpit TRM                                              *
*  Autor    : Geraldo Majella                                          *
*  Data     : 01.08.2022                                            *
* ==================================================================== *
*                 Histórico de modificações                            *
* ==================================================================== *
* -------------------------------------------------------------------- *
* Data       | Nome          | Descrição                               *
* -------------------------------------------------------------------- *
* xx/xx/xxxx | xxxxxxxxxxx   | xxxxxxxxxxxxxxxxxxxxxxxxxxxxx           *
* ---------------------------------------------------------------------*
REPORT zcc_trm_dmee_cockpit MESSAGE-ID zcc_dme LINE-SIZE 154.

PERFORM f_authority_check_transaction.

CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS '100'.
  SET TITLEBAR  '100'.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE PROGRAM.
    WHEN 'TR01'. " Cadastro De Operações
      CALL TRANSACTION 'ZCC_MAIRETRM012'.
    WHEN 'TR02'. " Upload CSV
      CALL TRANSACTION 'ZCC_DMEE_UPLOAD'.
    WHEN 'TR03'. " Relatório de Liquidação de NDFs
      CALL TRANSACTION 'ZCC_MAIRETRM014'.
    WHEN 'TR04'. " Configurações Globais
      CALL TRANSACTION 'ZCC_MAIRETRM015'.
    WHEN 'TR05'. " Relatório de NDF´s Abertas no Mês
      CALL TRANSACTION 'ZCC_MAIRETRM016'.
    WHEN 'TR06'. " Relatório Tipos de Opers: Hedge Accounting ou Resultado
      CALL TRANSACTION 'ZCC_MAIRETRM017'.
    WHEN 'TR07'. " Reprocessamento de NDFs
      CALL TRANSACTION 'ZCC_MAIRETRM018'.
    WHEN 'TR08'. " Reprocessar Cadeia de Transf. VC
      CALL TRANSACTION 'ZCC_MAIRETRM019'.
    WHEN 'TR09'. " Reclassifcação VC e Lçto Imposto Diferido
      CALL TRANSACTION 'ZCC_MAIRETRM020'.
    WHEN 'TR10'. " Entrada da Curva de Juros e Cupom Cambial
      CALL TRANSACTION 'TBEX'.
    WHEN 'TR11'. " Cálculo de Valor Justo de NDF em Aberto
      CALL TRANSACTION 'TPM60'.
    WHEN 'TR12'. " Cálculo do Juros e Variação Cambial NDF´s Aberto
      CALL TRANSACTION 'TPM1'.
    WHEN 'TR13'. " Entrar Registros Swap
      CALL TRANSACTION 'ZCC_MAIRETRM021'.
    WHEN 'TR14'. " Teste de efetividade
      CALL TRANSACTION 'ZCC_MAIRETRM024'.      "Convista(MFS) - chamado 02/2017 - Pacote 1.
    WHEN 'TR15'. " Cockpit Interface
      CALL TRANSACTION 'ZCC_MAIRETRM040'.
    WHEN 'TR16'. " Operação Café Verde
      CALL TRANSACTION 'ZCC_MAIRETRM002'.
    WHEN 'TR18'. " Vinculação da NDF as despesas do período
      CALL TRANSACTION 'ZCC_MAIRETRM044'.
    WHEN 'TR20'. " Tabela De x Para Tipo Produto
      CALL TRANSACTION 'ZCC_DMEE_TP_PROD'.
    WHEN 'TR21'. " Cálculo marcação a mercado com EPL
**      CALL TRANSACTION '/VWK/MAIRETRM004'.
      CALL TRANSACTION 'ZCC_VWK_MAIRETRM004'.
    WHEN 'TR30'. " Tabela De x Para Tipo Produto
      CALL TRANSACTION 'ZCC_DMEE_EMPR'.
    WHEN 'TR50'. " Transferir ref.classif.contábil
      CALL TRANSACTION 'TPM28'.
    WHEN OTHERS.
* Do Nothing
  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Form  F_AUTHORITY_CHECK_TRANSACTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_authority_check_transaction .

  AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
           ID 'BUKRS' FIELD '0500'
           ID 'ACTVT' FIELD '03'.

  IF sy-subrc NE 0.

    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
           ID 'BUKRS' FIELD '0501'
           ID 'ACTVT' FIELD '03'.

    IF sy-subrc NE 0.

*Sem autorização para a empresa XXX.
      MESSAGE e000(oo) WITH TEXT-063. " p_bukrs.

    ENDIF.

  ENDIF.

*  IF sy-subrc <> 0.
**Sem autorização para a empresa XXX.
*    MESSAGE e000(oo) WITH TEXT-063. " p_bukrs.
*  ENDIF.

ENDFORM.
