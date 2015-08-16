module Aruba
  class Headers
    def initialize(content = {})
      @content = content.each_with_object({}) do |kv, h|
        key, value = kv
        h[key.downcase] = value
      end
    end

    def [](key)
      @content[key.downcase.gsub(/_/, '-')]
    end

    def []=(key, value)
      @content[key.downcase.gsub(/_/, '-')] = value
    end

    def key?(key)
      @content.key?(key)
    end

    def each
      @content.each { |k,v| yield(k,v) }
    end

    def to_hash
      @content
    end
  end
end
