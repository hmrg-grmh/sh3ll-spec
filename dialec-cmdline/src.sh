dialec_cmdlines ()
{
    ask_user ()
    {
        predesc="${1:-Hey 👻}"
        ask="${2:-what should i ask ???}" &&
        anss="${3:-[y/n] (:p)}" &&
        
        cases="${4:-
            case \"\$ans\" in 
                
                y|\'\') echo 😦 yup\?\? ; break ;; 
                n) echo 🤔 no\? ; break ;; 
                *) echo 🤨 ahh\? what is \'\$"{"ans:-:p"}"\' \? ;; esac }" &&
        
        
        echo "$predesc" &&
        while read -p "$ask $anss " -- ans ;
        do eval "$cases" ; done ;
    } ;
    
    :;
} ;

