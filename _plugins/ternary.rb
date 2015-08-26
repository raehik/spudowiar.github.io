# syntactic sugar filter (Jekyll::Ternary) {{{
module Jekyll::Ternary
    # Ternary operator {{ value | if: truth | else: untruth }} {{{
    def if(value, truth)
        value ? truth : nil
    end

    def else(value, untruth)
        value ? value : untruth
    end
    # }}}
    # Fallback {{ first | fallback: second, third, etc. }} {{{
    def fallback(value, *fallbacks)
        while fallbacks.length > 0
            if value.to_s.empty? then
                value = fallbacks.shift
            else
                break
            end
        end
        value
    end
    # }}}
end
# }}}

Liquid::Template.register_filter(Jekyll::Ternary)

# vim: fdm=marker
