class Redcarpet::Render::HTML
    SHORTLINK_IDENTIFIER = "!"

    def shortlinks
        @shortlinks ||= {
            :Google => lambda { |query| "http://google.com/?q=#{CGI.escape query}" },
            :Wikipedia => lambda { |topic| "https://wikipedia.org/wiki/#{CGI.escape(topic).gsub "+", "%20"}" },
            :Git => lambda { |url| "https://git-scm.com/#{url}" },
            :ArchWiki => lambda { |title| "https://wiki.archlinux.org/index.php/#{CGI.escape(title).gsub "+", "_"}" },

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
    end

    def link(link, title, content)
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
