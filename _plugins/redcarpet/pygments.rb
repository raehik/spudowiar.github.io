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
end
