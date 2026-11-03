%%%-------------------------------------------------------------------
%% @doc Evaluador de expresiones matemáticas con funciones puras.
%%
%% Gramática (analizador descendente recursivo):
%%
%%   expr   := term (('+' | '-') term)*
%%   term   := factor (('*' | '/') factor)*
%%   factor := numero | '(' expr ')' | '-' factor | '+' factor
%%   numero := digitos ('.' digitos)?
%%
%% La precedencia y los paréntesis se respetan por la estructura de la
%% gramática. Se admiten números negativos mediante el menos unario.
%%
%% Errores:
%%   {error_sintaxis, Resto}                 expresión incompleta o mal formada
%%   {caracter_invalido, Caracter}           carácter no reconocido
%%   {error_aritmetico, division_entre_cero} divisor igual a cero
%%   {entrada_invalida, Valor}               la entrada no es una lista
%% @end
%%%-------------------------------------------------------------------

-module(p09_evaluador).

-export([evaluar/1]).

%%%-------------------------------------------------------------------
%% @doc Evalúa una expresión matemática y devuelve su valor numérico.
%% @end
%%%-------------------------------------------------------------------
-spec evaluar(string()) -> number().
evaluar(Texto) when is_list(Texto) ->
    {Valor, Resto} = expr(saltar_espacios(Texto)),
    validar_final(saltar_espacios(Resto)),
    Valor;
evaluar(Otro) ->
    erlang:error({entrada_invalida, Otro}).

%%%-------------------------------------------------------------------
%% expr := term (('+' | '-') term)*
%%%-------------------------------------------------------------------

expr(Texto) ->
    {Valor, Resto} = term(Texto),
    expr_resto(Valor, saltar_espacios(Resto)).

expr_resto(Acc, [Operador | Resto]) when Operador =:= $+; Operador =:= $- ->
    {Valor, Resto2} = term(saltar_espacios(Resto)),
    expr_resto(aplicar(Operador, Acc, Valor), saltar_espacios(Resto2));
expr_resto(Acc, Resto) ->
    {Acc, Resto}.

%%%-------------------------------------------------------------------
%% term := factor (('*' | '/') factor)*
%%%-------------------------------------------------------------------

term(Texto) ->
    {Valor, Resto} = factor(Texto),
    term_resto(Valor, saltar_espacios(Resto)).

term_resto(Acc, [Operador | Resto]) when Operador =:= $*; Operador =:= $/ ->
    {Valor, Resto2} = factor(saltar_espacios(Resto)),
    term_resto(aplicar(Operador, Acc, Valor), saltar_espacios(Resto2));
term_resto(Acc, Resto) ->
    {Acc, Resto}.

%%%-------------------------------------------------------------------
%% factor := numero | '(' expr ')' | '-' factor | '+' factor
%%%-------------------------------------------------------------------

factor([$\( | Resto]) ->
    {Valor, Resto2} = expr(saltar_espacios(Resto)),
    case saltar_espacios(Resto2) of
        [$\) | Resto3] ->
            {Valor, Resto3};
        _ ->
            erlang:error({error_sintaxis, Resto2})
    end;
factor([$- | Resto]) ->
    {Valor, Resto2} = factor(saltar_espacios(Resto)),
    {-Valor, Resto2};
factor([$+ | Resto]) ->
    factor(saltar_espacios(Resto));
factor([Caracter | _] = Texto) when Caracter >= $0, Caracter =< $9 ->
    numero(Texto);
factor([]) ->
    erlang:error({error_sintaxis, []});
factor([$\) | _] = Texto) ->
    erlang:error({error_sintaxis, Texto});
factor([Caracter | _]) ->
    erlang:error({caracter_invalido, Caracter}).

%%%-------------------------------------------------------------------
%% Números enteros y decimales
%%%-------------------------------------------------------------------

numero(Texto) ->
    {Entero, Resto} = parte_entera(Texto, 0),
    case Resto of
        [$. | Resto2] ->
            {Decimal, Resto3} = parte_decimal(Resto2, 0, 1),
            {Entero + Decimal, Resto3};
        _ ->
            {Entero, Resto}
    end.

parte_entera([Digito | Resto], Acc) when Digito >= $0, Digito =< $9 ->
    parte_entera(Resto, Acc * 10 + (Digito - $0));
parte_entera(Resto, Acc) ->
    {Acc, Resto}.

parte_decimal([Digito | Resto], Acc, Escala) when Digito >= $0, Digito =< $9 ->
    parte_decimal(Resto, Acc * 10 + (Digito - $0), Escala * 10);
parte_decimal(Resto, _Acc, 1) ->
    %% Un punto sin dígitos: "3." no es un número válido.
    erlang:error({error_sintaxis, Resto});
parte_decimal(Resto, Acc, Escala) ->
    {Acc / Escala, Resto}.

%%%-------------------------------------------------------------------
%% Operaciones
%%%-------------------------------------------------------------------

aplicar($+, A, B) ->
    A + B;
aplicar($-, A, B) ->
    A - B;
aplicar($*, A, B) ->
    A * B;
aplicar($/, _A, B) when B == 0 ->
    erlang:error({error_aritmetico, division_entre_cero});
aplicar($/, A, B) ->
    A / B.

%%%-------------------------------------------------------------------
%% Validación y espacios
%%%-------------------------------------------------------------------

%% Tras una expresión completa no debe quedar nada, salvo espacios.
validar_final([]) ->
    ok;
validar_final([Caracter | _] = Resto)
  when Caracter >= $0, Caracter =< $9;
       Caracter =:= $(; Caracter =:= $); Caracter =:= $+;
       Caracter =:= $-; Caracter =:= $*; Caracter =:= $/ ->
    erlang:error({error_sintaxis, Resto});
validar_final([Caracter | _]) ->
    erlang:error({caracter_invalido, Caracter}).

saltar_espacios([Caracter | Resto])
  when Caracter =:= $\s; Caracter =:= $\t;
       Caracter =:= $\n; Caracter =:= $\r ->
    saltar_espacios(Resto);
saltar_espacios(Texto) ->
    Texto.
