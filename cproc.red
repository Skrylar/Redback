Red []

active-definitions: []

; NB how do we turn off parse's default whitespace skipping?

; basic building blocks
alpha: charset [#"a" - #"z" #"A" - #"Z"]
digit: charset [#"0" - #"9"]
digit-nz: charset [#"1" - #"9"]	; TODO replace with append from doc
alnum: [alpha | digit]
identifier: [["_" alnum | alpha] any [alnum | "_"]]

; comments are not macro expanded
linecomment: ["//" thru newline (print "LINE COMMENT")]
blockcomment: ["/*" thru "*/" (print "BLOCK COMMENT")]
comment: [linecomment | blockcomment]

; strings are also not macro expanded
dquot: "^""
string: [dquot any [#"\" dquot | not dquot skip] dquot (print "STRING")]

; defining new macro stuff
; TODO support variadic declarations
; https://gcc.gnu.org/onlinedocs/cpp/Variadic-Macros.html#Variadic-Macros
definition-variadic: ["..." (print "DEFINE/VARIADIC")]
   definition-params: ["(" [definition-variadic | identifier any ["," any space [identifier | definition-variadic break]]] ")" (print "DEFINE/PARAMETERS")]
definition: ["#define" space identifier (print "DEFINE/IDENTIFIER")
    opt definition-params
    ; TODO support \'s for multiline macros
    thru newline (print "DEFINE/END")]
undefine: ["#undef" some space identifier newline (print "UNDEFINE")]

ifskip: [["#ifdef" | "#if"] to "#" any [ifskip | ["#else" | "#elif"] to "#"] "#endif" thru newline]

ifdef: [["#ifdef" | "#ifndef"] some space identifier (print "IFDEF/IDENTIFIER") thru newline
   ; TODO check if the identifier is defined
   ; TODO either do a full substitution pass inside this block, or a minimal pass to ignore #ifs and #ifdefs within the block properly
   opt ["#else" thru newline (print "IFDEF/ELSE")]
   ; TODO either do a full substitution pass inside this block, or a minimal pass to ignore #ifs and #ifdefs within the block properly
   "#endif" thru newline (print "IFDEF/END")
]

ifexpr: ["#if" (print "IF/EXPR") thru newline
   ; TODO evaluate the expression for truth
   ; TODO either do a full substitution pass inside this block, or a minimal pass to ignore #ifs and #ifdefs within the block properly
   any ["#elif" thru newline]
   ; TODO evaluate the expression for truth
   ; TODO either do a full substitution pass inside this block, or a minimal pass to ignore #ifs and #ifdefs within the block properly
   opt ["#else" thru newline]
   ; TODO either do a full substitution pass inside this block, or a minimal pass to ignore #ifs and #ifdefs within the block properly
   "#endif" thru newline
]

integer: [copy read-value ["0" | digit-nz any digit] (print ["INTEGER" to integer! read-value] append number-stack to integer! read-value)]

; TODO actually escape the character and figure out its value
character: ["'" ["\" skip | skip] "'" (print "CHARACTER")]

number-stack: make block! 100

pop-number: func [][
   index: back tail number-stack
   ret: index/1
   remove index
   return ret
]

muldiv: [value-inner
   any [set operation ["*" | "/"]
      (append number-stack operation)
      value-inner (
	 rhs: pop-number
	 operation: pop-number
	 lhs: pop-number
	 switch operation [
	    #"*" [value: lhs * rhs print ["MUL" value]]
	    #"/" [value: lhs / rhs print ["DIV" value]]
	 ]
	 append number-stack value
      )]]

addsub: [muldiv
   any [set operation ["+" | "-"]
      (append number-stack operation)
      muldiv (
	 rhs: pop-number
	 operation: pop-number
	 lhs: pop-number
	 switch operation [
	    #"+" [value: lhs + rhs print ["ADD" value]]
	    #"-" [value: lhs - rhs print ["SUB" value]]
	 ]
	 append number-stack value
      )
   ]
]

andor: [addsub
   any [set operation ["||" | "&&"]
      (append number-stack operation)
      addsub (
	 rhs: pop-number
	 operation: pop-number
	 lhs: pop-number
	 switch operation [
	    #"|" [value: lhs or rhs print ["OR" value]]
	    #"&" [value: lhs and rhs print ["AND" value]]
	 ]
	 append number-stack value
      )
   ]
]

value-list: [opt [value-outer ["," value-outer]]]
;ifcall: ["defined(" any [not ")" skip] ")" (print "DEFINED/CALL") | identifier (print "MACRO") opt ["(" value-list ")" (print "MACRO/CALL")]]
ifcall: [value-position: remove copy value identifier (
      print ["MACRO:" value]
      value: select active-definitions value
      insert value-position value
   ) value-inner
]

value-inner: [character | integer | ifcall | "(" (print "SUBEXPR/IN") value ")" (print "SUBEXPR/OUT")]
value-outer: andor

macro-parameter: [any [not ["," | ")"] skip]]
macro-parameter-list: ["(" macro-parameter any ["," macro-parameter] ")"]
macro-call: [identifier macro-parameter-list]

stringify: ["#" identifier (print "STRINGIFY")]

paste-constituent: [some [not ["#" | dquot | space] skip]]
paste: [paste-constituent any space "##" any space paste-constituent (print "PASTE")]
