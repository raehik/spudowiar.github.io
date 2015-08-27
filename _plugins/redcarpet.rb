=begin
* adds syntax:

    [spudowiar/spudowiar.github.io](!GitHub)
    [this](!GitHub "spudowiar.github.io")
    [http://google.co.uk/]()

* adjusts code tags
=end

require 'redcarpet'

class Jekyll::Converters::Markdown::RedcarpetParser
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
        (config["redcarpet"]["custom"] || []).each do |plugin|
            require_relative "redcarpet/#{plugin}"
        end

        old_initialize options
        @config = config
    end
end
