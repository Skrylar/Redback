Red []

; NB how do we turn off parse's default whitespace skipping?

; basic building blocks
alpha: charset "abcdefghijklmopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
digit: charset "0123456789"
alnum: [alpha | digit]
identifier: [[opt "_" alnum | alpha] any [alnum | "_"]]

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

macro-parameter: [any [not ["," | ")"] skip]]
macro-parameter-list: ["(" macro-parameter any ["," macro-parameter] ")"]
macro-call: [identifier macro-parameter-list]

stringify: ["#" identifier (print "STRINGIFY")]

paste-constituent: [some [not ["#" | dquot | space] skip]]
paste: [paste-constituent any space "##" any space paste-constituent (print "PASTE")]
