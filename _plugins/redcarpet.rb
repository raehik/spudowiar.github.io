=begin
adds syntax:

    [spudowiar/spudowiar.github.io](!GitHub)
    [this](!GitHub "spudowiar.github.io")
    [http://google.co.uk/]()
=end

require 'redcarpet'

require 'shellwords'

require 'uri'
require 'cgi'

class Redcarpet::Render::HTML
    SHORTLINK_IDENTIFIER = "!"
    SHORTLINKS = {
        :GitHub => lambda { |url|
            "https://github.com/#{URI.escape url}"
        },

        :Wikipedia => lambda { |topic|
            "https://wikipedia.org/wiki/#{CGI.escape(topic).gsub "+", "%20"}"
        },

        :Google => lambda { |query|
            "http://google.com/?q=#{CGI.escape query}"
        },

        :phpBB => lambda { |url, params|
            if url !~ /^.*:\/\//
                url.prepend "http://"
            end
            "#{url}/viewtopic.php?#{params}"
        }
    }

    def link(link, title, content)
        if link && link.start_with?(SHORTLINK_IDENTIFIER)
            args = "#{link.sub SHORTLINK_IDENTIFIER, ""} \"#{title}\"".shellsplit.delete_if &:blank?
            shortlink = args.shift.to_sym

            function = SHORTLINKS[shortlink]
            if function
                if args.length < function.arity
                    args.unshift content
                elsif args.length > function.arity
                    title = args.pop
                else
                    title = nil
                end
                link = function[*args]
            end
        end

        link ||= content

        anchor = "<a href=\"#{CGI.escapeHTML link}"

        if title
            anchor << "\" title=\"#{CGI.escapeHTML title}"
        end

        anchor << "\">#{content}</a>"
    end
end
