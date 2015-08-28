# regex replace filter (Jekyll::Filters::Sub) {{{
module Jekyll::Filters::Sub
    def sub(value, regex, replacement)
        value.sub(Regexp.new(regex), replacement)
    end
    
    def gsub(value, regex, replacement)
        value.gsub(Regexp.new(regex), replacement)
    end
end
# }}}

Liquid::Template.register_filter Jekyll::Filters::Sub

# vim: fdm=marker
