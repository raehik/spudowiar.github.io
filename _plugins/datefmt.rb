# date formatter (Jekyll::DateFmt) {{{
class Jekyll::DateFmt < Liquid::Block
    def initialize(tag, date, tokens)
        super
        @date = date
    end

    def render(context)
        date = Time.parse Liquid::Template.parse("{{ #{@date} }}").render(context)
        fmts = context["theme"]["date"]
        context.merge({
            "date_full" => date.iso8601,
            "date_long" => date.strftime(fmts["human_readable"]),
            "date_short" => date.strftime(fmts["human_readable_short"])
        })
        super
    end
end
# }}}

Liquid::Template.register_tag("datefmt", Jekyll::DateFmt)

# vim: fdm=marker
