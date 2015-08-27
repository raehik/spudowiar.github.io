=begin
* adds syntax:

    [spudowiar/spudowiar.github.io](!GitHub)
    [this](!GitHub "spudowiar.github.io")
    [http://google.co.uk/]()

* adjusts code tags
=end

require 'redcarpet'
require 'csv'

require 'uri'
require 'cgi'

class Jekyll::Converters::Markdown::RedcarpetParser
    module WithPygments
        def add_code_tags(code, lang, filename, url)
            code = code.to_s
            code = code.gsub /<pre>/, "<pre><code class=\"language-#{lang}\" data-lang=\"#{lang}\">"
            code = code.gsub /<\/pre>/,"</code></pre>"
            code = code.gsub /(<span class="lineno">.+?)<\/span> /, "\\1 </span>"
            html = code
            code = "<figure class=\"code\">"
            if filename then
                code << "<figcaption>"
                code << "<a href=\"#{CGI.escapeHTML url}\">" if url
                code << CGI.escapeHTML(filename)
                code << "</a>" if url
                code << "</figcaption>"
            end
            code << "#{html}</figure>"
        end

        def block_code(code, lang)
            return nil if code.strip.empty?
            lang &&= lang.split.first
            lang ||= ""
            lang, filename, url = CSV.parse(lang)[0]
            require 'pygments'
            lang = nil if lang && lang.empty?
            options = { :encoding => 'utf-8' }
            @config["redcarpet"]["pygments"] && @config["redcarpet"]["pygments"].each { |k, v| options[k.to_sym] = v }
            add_code_tags(
                Pygments.highlight(code, :lexer => lang, :options => options),
                lang, filename, url
            )
        end
    end

    def convert(content)
        @redcarpet_extensions[:fenced_code_blocks] = !@redcarpet_extensions[:no_fenced_code_blocks]
        @renderer.send :include, Redcarpet::Render::SmartyPants if @redcarpet_extensions[:smart]
        markdown = Redcarpet::Markdown.new(@renderer.new(@redcarpet_extensions, @config), @redcarpet_extensions)
        markdown.render(content)
    end
end

class Redcarpet::Render::HTML
    alias_method :old_initialize, :initialize
    def initialize(options={}, config={})
        old_initialize options
        @config = config
    end

    SHORTLINK_IDENTIFIER = "!"

    def link(link, title, content)
        shortlinks = {
            :Google => lambda { |query| "http://google.com/?q=#{CGI.escape query}" },
            :Wikipedia => lambda { |topic| "https://wikipedia.org/wiki/#{CGI.escape(topic).gsub "+", "%20"}" },

            :source => lambda { |path| shortlinks[:GitHub]["./#{@config["github"]["repository"]}", @config["github"]["branch"], path] },
            :repo => lambda { shortlinks[:source][nil] },

            :GitHub => lambda { |repo, branch=nil, path=nil|
                repo.sub! /^\./, @config["github"]["owner"]
                if branch then
                    "https://github.com/#{repo}/tree/#{branch}/#{path}"
                else
                    "https://github.com/#{repo}"
                end
            },

            :phpBB => lambda { |url, params|
                if url !~ /^.*:\/\// then
                    url.prepend "http://"
                end
                "#{url}/viewtopic.php?#{params}"
            }
        }

        if link && link.start_with?(SHORTLINK_IDENTIFIER) then
            args = "#{link.sub SHORTLINK_IDENTIFIER, ""} \"#{title}\"".split /\s(?=(?:[^"]|"[^"]*")*$)/
            shortlink = args.shift.to_sym

            if args.length >= 2 && args[-2].end_with?(",") then
                title = args.pop
                args[-1].sub! /,$/, ""
            else
                title = nil
            end

            args.map! do |arg|
                arg.sub(/^'|"/, "").sub(/'|"$/, "")
            end.delete_if &:blank?

            function = shortlinks[shortlink]
            if function then
                arity = function.arity
                if arity < 0 then
                    arity = -arity - 1
                end

                if args.length < arity then
                    args.unshift content
                end
                link = function[*args]
            end
        end

        link ||= content

        anchor = "<a href=\"#{CGI.escapeHTML link}"

        if title then
            anchor << "\" title=\"#{CGI.escapeHTML title}"
        end

        anchor << "\">#{content}</a>"
    end
end
