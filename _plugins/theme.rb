# defines new global 'theme' in Liquid, alias for 'site.theme' {{{
class Jekyll::Site
    alias_method :old_site_payload, :site_payload
    def site_payload
        payload = old_site_payload
        if payload["site"].has_key? "theme" then
            payload["theme"] = payload["site"]["theme"]
        end
        payload
    end
end
# }}}

# changes 'include_dir' for SASS files to 'sass_dir' {{{
class Jekyll::Tags::IncludeTag
    alias_method :old_resolved_includes_dir, :resolved_includes_dir
    def resolved_includes_dir(context)
        document = Jekyll::Document.new(context["page"]["path"], { "site" => nil })
        if document.sass_file? then
            Jekyll::Converters::Scss.new(context).sass_dir
        else
            old_resolved_includes_dir context
        end
    end
end
# }}}

# 'canonical' tag {{{
class Jekyll::Tags::Canonical < Liquid::Tag
    def initialize(tag, markup, tokens)
        @url = markup unless markup.empty?
        super
    end

    def render(context)
        @url ||= context["page"]["url"]
        "#{context["site"]["url"]}#{context["site"]["baseurl"]}#{@url.sub /\/index.html?$/i, "/"}"
    end
end

Liquid::Template.register_tag 'canonical', Jekyll::Tags::Canonical
# }}}
# 'self' tag {{{
class Jekyll::Tags::Self < Liquid::Tag
    def initialize(tag, markup, tokens)
        @url = markup unless markup.empty?
        super
    end

    def render(context)
        @url ||= context["page"]["url"]
        "#{context["site"]["baseurl"]}#{@url.sub /\/index.html?$/i, "/"}"
    end
end

Liquid::Template.register_tag 'self', Jekyll::Tags::Self
# }}}

# 'sass_box' filter {{{
module Jekyll::SassFilters
    def sass_box_get(hash, side)
        hash.has_key?(side) ? hash[side] : hash["all"]
    end

    def sass_box(hash, property="")
        property &&= "#{property}-"
        css = ""
        ["top", "right", "bottom", "left"].each do |side|
            css << "#{property}#{side}: #{sass_box_get(hash, side)};\n"
        end
        css
    end
end

Liquid::Template.register_filter Jekyll::SassFilters
# }}}

# vim: fdm=marker
