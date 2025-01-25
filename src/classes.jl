module Classes
abstract type Node end
struct ID<:Node val end
struct SEQ<:Node val end # like (a b c) in scheme
struct ELE<:Node val end #an element in a seq
struct ESC_CHAR<:Node val end # character preceded by escape char "\"
struct CHAR<:Node val end #character
struct SPACE<:Node val end # space
struct NL<:Node val end # newline
struct PROG<:Node val end # all the program
# pattern in regex form
#struct PTN_RGX<:Node val::Regex end
end