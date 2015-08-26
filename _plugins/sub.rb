# regex replace filter (Jekyll::RegexSub) {{{
module Jekyll::RegexSub
    def sub(value, regex, replacement)
        value.sub(Regexp.new(regex), replacement)
    end
    
    def gsub(value, regex, replacement)
        value.gsub(Regexp.new(regex), replacement)
    end
end
# }}}

Liquid::Template.register_filter(Jekyll::RegexSub)

# vim: fdm=marker
