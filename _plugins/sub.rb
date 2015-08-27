# regex replace filter (Jekyll::SubFilter) {{{
module Jekyll::SubFilter
    def sub(value, regex, replacement)
        value.sub(Regexp.new(regex), replacement)
    end
    
    def gsub(value, regex, replacement)
        value.gsub(Regexp.new(regex), replacement)
    end
end
# }}}

Liquid::Template.register_filter Jekyll::SubFilter

# vim: fdm=marker
