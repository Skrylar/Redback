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
definition-params: ["(" identifier any
    ["," identifier ] ")" (print "DEFINE/PARAMETERS")]
definition: ["#define" space identifier (print "DEFINE/IDENTIFIER")
    opt definition-params
    ; TODO support \'s for multiline macros
    newline (print "DEFINE/END")]
undefine: ["#undef" some space identifier newline (print "UNDEFINE")]

macro-parameter: [any [not ["," | ")"] skip]]
macro-parameter-list: ["(" macro-parameter any ["," macro-parameter] ")"]
macro-call: [identifier macro-parameter-list]

stringify: ["#" identifier (print "STRINGIFY")]

paste-constituent: [some [not ["#" | dquot | space] skip]]
paste: [paste-constituent any space "##" any space paste-constituent (print "PASTE")]

print parse "_shit ## 44" paste
