require 'shellwords'

# 'tweet' tag {{{
class Jekyll::Tags::Tweet < Liquid::Tag
    def initialize(tag, args, tokens)
        super
        args = args.shellsplit
        init(*args)
    end

    def init(tweet, params="")
        @params = {
            :id => tweet,
            :align => "center",
            :maxwidth => 550
        }
        @params.merge! CGI.parse params
    end

    def render(context)
        params = @params.map do |k, v|
            "#{CGI.escape k.to_s}=#{CGI.escape v.to_s}"
        end.join '&'
        url = "https://api.twitter.com/1/statuses/oembed.json?#{params}"
        response = JSON.parse Net::HTTP.get URI url
        response["html"]
    end
end

Liquid::Template.register_tag 'tweet', Jekyll::Tags::Tweet
# }}}
