class Jekyll::Post
    alias_method :old_initialize, :initialize
    def initialize(site, source, dir, name)
        old_initialize site, source, dir, name
        self.categories = name.split('/').reject { |x| x.empty? }
        self.categories.pop
        populate_categories
    end
end
