%define lr.type canonical-lr
%define parse.error verbose
%defines

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "../lib/arvore.h"
    #include "../lib/tabelaSimbolo.h"
    extern int yylex();
    extern int yylex_destroy();
    extern void yyerror(const char* s);
    extern FILE *yyin;
    AST* raiz;
    TabelaSimbolo* id;
    int erros = 0;
    char tipos[4][10] = {"INT", "FLOAT", "INT LIST", "FLOAT LIST"};
    int tipo = 0;
    extern int escopoL[1000];
    extern int escopoAtual;
    extern int escopo;
    extern char type_symbol[20];
%}

%union{
    struct AST* ast;
    struct Token {
        int linha;
        int coluna;
        char id[100];
        int escopo;
    } token;
}

%token <token>  ID
%token <token>  INT
%token <token>  FLOAT
%token <token>  TIPO_INT
%token <token>  TIPO_FLOAT
%token <token>  TIPO_LIST_INT
%token <token>  TIPO_LIST_FLOAT
%token <token>  OP_B_SOMA_SUB
%token <token>  OP_B_MULT_DIV
%token <token>  OP_LOGICA_AND
%token <token>  OP_LOGICA_NEG
%token <token>  OP_LOGICA_OR
%token <token>  OP_B_RELACIONAIS
%token <token> IF
%token <token> ELSE
%right THEN ELSE
%token <token>  FOR
%token <token>  RETORNO
%token <token>  ENTRADA
%token <token>  SAIDA
%token <token>  CONSTRUTOR_LISTA
%token <token>  OP_LISTA
%token <token>  FUNCOES_LISTA
%token <token>  STRING
%token <token>  NIL
%token <token>  ABRE_PARENTESES
%token <token>  FECHA_PARENTESES
%token <token>  ABRE_CHAVES
%token <token>  FECHA_CHAVES
%token <token>  ATRIBUICAO
%token <token>  VIRGULA
%token <token>  PONTOVIRGULA
%token <token>  COLCHETES

%type <ast> programa;
%type <ast> listaDeDeclaracoes;
%type <ast> declaracao;
%type <ast> TIPO;
%type <ast> declaracaoVariavel;
%type <ast> declaracaoFuncao;
%type <ast> listaDeParametros
%type <ast> corpo;
%type <ast> dentroCorpo;
%type <ast> declaracoes;
%type <ast> expressao;
%type <ast> for;
%type <ast> condicional;
%type <ast> exp;
%type <ast> expressaoList;
%type <ast> expressao_logica;
%type <ast> expressao_relacional;
%type <ast> opSomaSub;
%type <ast> opMultDiv;
%type <ast> argumento;
%type <ast> chamadaDeFuncao;
%type <ast> entrada;
%type <ast> saida;
%type <ast> retorno;
%type <ast> nil;
%type <ast> numero;


%%
programa:
    listaDeDeclaracoes {
        $$ = criaNo("programa");
        $$->pai = $1;
        raiz = $$;
    }
;

listaDeDeclaracoes: 
    listaDeDeclaracoes declaracao {
        $$ = criaNo("lista De Declaracoes");
        $$->pai = $1;
        $1->filho = $2;
    }
    | declaracao {
        $$ = $1;
    }
;

TIPO:
    TIPO_INT {
        $$ = criaNo("INT");
        strcpy($$->tipo, "INT");
        tipo += 0;
    }
    | TIPO_FLOAT {
        $$ = criaNo("FLOAT");
        strcpy($$->tipo, "FLOAT");
        tipo += 1;
    }
    | TIPO_LIST_INT {
        $$ = criaNo("INT LIST");
        strcpy($$->tipo, "INT LIST");
        tipo += 2;
    }
    | TIPO_LIST_FLOAT {
        $$ = criaNo("FLOAT LIST");
        strcpy($$->tipo, "FLOAT LIST");
        tipo += 3;
    }
;

declaracao:
    declaracaoVariavel {
        $$ = $1;
    }
    | declaracaoFuncao {
        $$ = $1;
    }
    | error {
        erros++;
    }
;

declaracaoVariavel: 
    TIPO ID PONTOVIRGULA {
        $$ = criaNo("Declaracao de Variavel");
        $$->pai = $1;
        id = insereSimbolo(id, $2.escopo, $2.id, "Variavel", tipos[tipo], $2.linha, $2.coluna, 0);
        strcpy($1->simbolo, $2.id);
        tipo = 0;
    }
;

declaracaoFuncao:
    TIPO ID ABRE_PARENTESES listaDeParametros FECHA_PARENTESES corpo {
        $$ = criaNo("Declaracao de funcao");
        $$->pai = $1;
        $1->filho = $4;
        $4->filho = $6;
        id = insereSimbolo(id, $2.escopo, $2.id, "Funcao", tipos[tipo], $2.linha, $2.coluna, 0);
        strcpy($1->simbolo, $2.id);
        tipo = 0;
    }
;

listaDeParametros:
    TIPO ID VIRGULA listaDeParametros {
        $$ = criaNo("Lista de Parametros");
        $$->pai = $1;
        $1->filho = $4;
        id = insereSimbolo(id, $2.escopo, $2.id, "Variavel", tipos[tipo], $2.linha, $2.coluna, 1);
        tipo = 0;
        strcpy($1->simbolo, $2.id);
    }
    | TIPO ID {
        $$ = criaNo("Lista de Parametros");
        $$->pai = $1;
        escopoL[++escopoAtual] = escopo++;
        id = insereSimbolo(id, escopoL[escopoAtual], $2.id, "Variavel", tipos[tipo], $2.linha, $2.coluna, 1);
        strcpy($1->simbolo, $2.id);
        tipo = 0;
        escopoAtual--;
        escopo--;
    }
    |  {
        $$ = criaNo("Lista de Parametros vazia");
    }
;

corpo:
    ABRE_CHAVES dentroCorpo FECHA_CHAVES {
        $$ = criaNo("dentro das chaves");
        $$->pai = $2;
    }
    | error {
        erros++;
    }
;

dentroCorpo:
    declaracoes dentroCorpo {
        $$ = criaNo("declaracoes");
        $$->pai = $1;
        $$->filho = $2;
    }
    | declaracoes {
        $$ = criaNo("declaracoes");
        $$->pai = $1;
    }
;

declaracoes:
    corpo {
        $$ = $1;
    }
    | declaracaoVariavel {
        $$ = $1;
    }
    | expressao {
        $$ = $1;
    }
    | entrada {
        $$ = $1;
    }
    | retorno {
        $$ = $1;
    }
    | saida {
        $$ = $1;
    }    
    | for {
        $$ = $1;
    }
    | condicional {
        $$ = $1;
    }
;

expressao:
    exp PONTOVIRGULA {
        $$ = criaNo("expressao");
        $$->pai = $1;
        strcpy($$->tipo, $1->tipo);
        castDeTudo($$->tipo, $$, $1);
        strcpy($$->simbolo, $1->simbolo);
    }
    | expressaoList {
        $$ = criaNo("expressao");
        $$->pai = $1;
        strcpy($$->tipo, $1->tipo);
    }
    | ID ATRIBUICAO expressao {
        $$ = criaNo("ATRIBUICAO");
        $$->pai = $3;
        TabelaSimbolo* c = procuraVariavel(id, $1.id);
        if(c == 0){
            printf("Linha: %d - Coluna: %d - Identificador: %s - Erro Semantico - Variavel nao declarada!!!\n", $1.linha, $1.coluna, $1.id);
        } else{
            strcpy($$->tipo, c->tipo);
            castDeTudo($$->tipo, $$, $3);
            strcpy($$->simbolo, $1.id);
        }
    }
    | ID ATRIBUICAO nil {
        $$ = criaNo("NULO");
        $$->pai = $3;
        TabelaSimbolo* c = procuraVariavel(id, $1.id);
        if(c == 0){
            printf("Linha: %d - Coluna: %d - Identificador: %s - Erro Semantico - Variavel nao declarada!!!\n", $1.linha, $1.coluna, $1.id);
        } else{
            strcpy($$->tipo, c->tipo);
            castDeTudo($$->tipo, $$, $3);
        }
    }
;


for:
    FOR ABRE_PARENTESES expressao expressao ID ATRIBUICAO ID FECHA_PARENTESES declaracoes {
        $$ = criaNo("for");
        $$->pai = $3;
        $3->filho = $4;
        $4->filho = $9;
    }
    | FOR ABRE_PARENTESES expressao expressao ID ATRIBUICAO ID OP_B_SOMA_SUB ID FECHA_PARENTESES declaracoes {
        $$ = criaNo("for");
        $$->pai = $3;
        $3->filho = $4;
        $4->filho = $11;
    }
    | FOR ABRE_PARENTESES expressao expressao ID ATRIBUICAO ID OP_B_SOMA_SUB numero FECHA_PARENTESES declaracoes {
        $$ = criaNo("for");
        $$->pai = $3;
        $3->filho = $4;
        $4->filho = $9;
        $9->filho = $11;
    }
    | FOR ABRE_PARENTESES expressao expressao ID ATRIBUICAO OP_LOGICA_NEG ID FECHA_PARENTESES declaracoes {
        $$ = criaNo("for");
        $$->pai = $3;
        $3->filho = $4;
        $4->filho = $10;
    }
;

condicional:
    IF ABRE_PARENTESES exp FECHA_PARENTESES declaracoes %prec THEN {
        $$ = criaNo("IF");
        $$->pai = $3;
        $3->filho = $5;
    }
    | IF ABRE_PARENTESES exp FECHA_PARENTESES declaracoes ELSE declaracoes {
        $$ = criaNo("IF-ELSE");
        $$->pai = $3;
        $3->filho = $5;
        $5->filho = $7;
    }
;

exp:
    expressao_logica {
        $$ = criaNo("exp");
        $$->pai = $1;
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
    }
    | OP_LOGICA_NEG exp {
        $$ = criaNo("exp");
        $$->pai = $2;
        strcpy($$->tipo, $2->tipo);
        strcpy($$->simbolo, $2->simbolo);
    }
;

expressaoList:
    OP_LISTA ID PONTOVIRGULA {
        $$ = criaNo("expressaoList");
        strcpy($$->tipo, "OPERACAOLISTA");
    }
    | exp CONSTRUTOR_LISTA ID PONTOVIRGULA {
        $$ = criaNo("expressaoList");
        $$->pai = $1;
        strcpy($$->tipo, "CONSTRUTORLISTA");
    }
    | exp FUNCOES_LISTA ID PONTOVIRGULA {
        $$ = criaNo("expressaoList");
        $$->pai = $1;
        strcpy($$->tipo, "FUNCAOLISTA");
    }
;

expressao_logica:
    expressao_logica OP_LOGICA_OR expressao_relacional {
        $$ = criaNo("expressaoLogica");
        $$->pai = $1;
        $1->filho = $3;
        //strcpy($$->tipo, "INT");
        castDeTudo($$->tipo, $$, $3);
        
    }
    | expressao_logica OP_LOGICA_AND expressao_relacional {
        $$ = criaNo("expressaoLogica");
        $$->pai = $1;
        $1->filho = $3;
        //strcpy($$->tipo, "INT");
        castDeTudo($$->tipo, $$, $3);
    }
    | expressao_relacional {
        $$ = criaNo("expressaoLogica");
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
    }
;

expressao_relacional:
    opSomaSub {
        $$ = criaNo("expressaoRelacional");
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
    }
    | expressao_relacional OP_B_RELACIONAIS opSomaSub {
        $$ = criaNo("expressaoRelacional");
        $$->pai = $1;
        $1->filho = $3;
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
        castDeTudo($$->tipo, $$, $3);
    }
;

opSomaSub:
    opMultDiv {
        $$ = criaNo("Operando SomaSub");
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
    }
    | opSomaSub OP_B_SOMA_SUB opMultDiv {
        $$ = criaNo("Operando SomaSub");
        $$->pai = $1;
        $1->filho = $3;
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
        castDeTudo($$->tipo, $$, $3);
    }
    | opSomaSub OP_B_SOMA_SUB OP_LISTA opMultDiv {
        $$ = criaNo("Operando SomaSub");
        $$->pai = $1;
        $1->filho = $4;
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
        castDeTudo($$->tipo, $$, $4);
    }
    
;

opMultDiv:
    argumento {
        $$ = criaNo("Operando MultDiv");
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
    }
    | opMultDiv OP_B_MULT_DIV argumento {
        $$ = criaNo("Operando MultDiv");
        $$->pai = $1;
        $1->filho = $3;
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
        castDeTudo($$->tipo, $$, $3);
    }
;

argumento:
    ID {
        $$ = criaNo("ID");
        TabelaSimbolo* c = procuraVariavel(id, $1.id);
        if(c == 0){
            printf("Linha: %d - Coluna: %d - Identificador: %s - Erro Semantico - Variavel nao declarada!!!\n", $1.linha, $1.coluna, $1.id);
        }else{
            strcpy($$->tipo, c->tipo);
            strcpy($$->simbolo, $1.id);
        }
    }
    | numero {
        $$ = criaNo("argumento");
        $$->pai = $1;
        strcpy($$->tipo, $1->tipo);
        strcpy($$->simbolo, $1->simbolo);
    }
    | ABRE_PARENTESES exp FECHA_PARENTESES {
        $$ = criaNo("argumento");
        $$->pai = $2;
        strcpy($$->tipo, $2->tipo);
        strcpy($$->simbolo, $2->simbolo);
    }
    | chamadaDeFuncao {
        $$ = criaNo("argumento");
        $$->pai = $1;
        strcpy($$->tipo, $1->tipo);
    }
;

chamadaDeFuncao:
    ID ABRE_PARENTESES exp FECHA_PARENTESES {
        $$ = criaNo("chamada de funcao");
        $$->pai = $3;
        TabelaSimbolo* c = procuraVariavel(id, $1.id);
        if(c == 0){
            printf("Linha: %d - Coluna: %d - Identificador: %s - Erro Semantico - Funcao nao declarada!!!\n", $1.linha, $1.coluna, $1.id);
        }else{
            strcpy($$->tipo, c->tipo);
        }
    }
    | ID ABRE_PARENTESES FECHA_PARENTESES {
        $$ = criaNo("chamada de funcao");
        TabelaSimbolo* c = procuraVariavel(id, $1.id);
        if(c == 0){
            printf("Linha: %d - Coluna: %d - Identificador: %s - Erro Semantico - Funcao nao declarada!!!\n", $1.linha, $1.coluna, $1.id);
        }else{
            strcpy($$->tipo, c->tipo);
        }
    }
;

entrada:
    ENTRADA ABRE_PARENTESES ID FECHA_PARENTESES PONTOVIRGULA {
        $$ = criaNo("entrada");
        TabelaSimbolo* c = procuraVariavel(id, $3.id);
        if(c == 0){
            printf("Linha: %d - Coluna: %d - Identificador: %s - Erro Semantico - Variavel nao declarada!!!\n", $3.linha, $3.coluna, $3.id);
        }else{
            strcpy($$->tipo, c->tipo);
        }
    }
;

saida:
    SAIDA ABRE_PARENTESES STRING FECHA_PARENTESES PONTOVIRGULA {
        $$ = criaNo("saida");
        strcpy($$->simbolo, $3.id);
    }
    | SAIDA ABRE_PARENTESES ID FECHA_PARENTESES PONTOVIRGULA {
        $$ = criaNo("saida");
        TabelaSimbolo* c = procuraVariavel(id, $3.id);
        if(c == 0){
            printf("Linha: %d - Coluna: %d - Identificador: %s - Erro Semantico - Variavel nao declarada!!!\n", $3.linha, $3.coluna, $3.id);
        }
    }
    | SAIDA ABRE_PARENTESES expressao FECHA_PARENTESES PONTOVIRGULA {
        $$ = criaNo("saida");
        $$->pai = $3;
    }
    | SAIDA ABRE_PARENTESES OP_LISTA ID FECHA_PARENTESES PONTOVIRGULA {
        $$ = criaNo("saida");
    }
;

retorno:
    RETORNO exp PONTOVIRGULA {
        $$ = criaNo("retorno");
        $$->pai = $2;
        char tipoRetornoC[20] = "";
        strcpy(tipoRetornoC, $2->tipo);
    }
    | RETORNO PONTOVIRGULA {
        $$ = criaNo("retorno");
    }
;

nil:
    NIL PONTOVIRGULA {
        $$ = criaNo("NULO");
        strcpy($$->tipo, "NULO");
        strcpy($$->simbolo, $1.id);
    }
    | OP_B_RELACIONAIS NIL {
        $$ = criaNo("NULO");
        strcpy($$->tipo, "NULO");
        strcpy($$->simbolo, $2.id);
    }
;

numero:
    INT {
        $$ = criaNo("Numero");
        strcpy($$->tipo, "INT");
        strcpy($$->simbolo, $1.id);
    }
    | FLOAT {
        $$ = criaNo("Numero");
        strcpy($$->tipo, "FLOAT");
        strcpy($$->simbolo, $1.id);
    }
;


%%

void yyerror(const char* s){
    fprintf(stderr, "Linha: %d - Coluna: %d - Token: %s - Erro: %s\n", yylval.token.linha, yylval.token.coluna, yylval.token.id, s);
}

int main(int argc, char ** argv) {
    
    yyin = fopen(argv[1], "r");
    
    yyparse();

    if(procuraMain(id) == 0){
        printf("Erro Semantico - Funcao Main nao encontrada!!!\n");
    }

    if(erros == 0){
        mostraAST(raiz, 0);
    }
    mostraTabela(id);
    limpaTabela(id);
    liberaAST();
    fclose(yyin);
    yylex_destroy();
    printf("\n\n");
    return 0;
}