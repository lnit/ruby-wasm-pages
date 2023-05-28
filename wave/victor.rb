module Victor
  VERSION = '0.3.4'
end
module Victor
  class SVGBase
    attr_accessor :template, :glue
    attr_reader :content, :svg_attributes
    attr_writer :css

    def initialize(attributes = nil, &block)
      setup attributes
      @content = []
      build(&block) if block
    end

    def <<(additional_content)
      content.push additional_content.to_s
    end
    alias append <<

    def setup(attributes = nil)
      attributes ||= {}
      attributes[:width] ||= '100%'
      attributes[:height] ||= '100%'

      @template = attributes[:template] || @template || :default
      @glue = attributes[:glue] || @glue || "\n"

      attributes.delete :template
      attributes.delete :glue

      @svg_attributes = Attributes.new attributes
    end

    def build(&block)
      instance_eval(&block)
    end

    def element(name, value = nil, attributes = {})
      if value.is_a? Hash
        attributes = value
        value = nil
      end

      escape = true

      if name.to_s.end_with? '!'
        escape = false
        name = name[0..-2]
      end

      attributes = Attributes.new attributes
      empty_tag = name.to_s == '_'

      if block_given? || value
        content.push "#{"<#{name} #{attributes}".strip}>" unless empty_tag
        if value
          content.push(escape ? value.to_s.encode(xml: :text) : value)
        else
          yield
        end
        content.push "</#{name}>" unless empty_tag
      else
        content.push "<#{name} #{attributes}/>"
      end
    end

    def css(defs = nil)
      @css ||= {}
      @css = defs if defs
      @css
    end

    def render(template: nil, glue: nil)
      @template = template if template
      @glue = glue if glue
      css_handler = CSS.new css

      svg_template % {
        css:        css_handler,
        style:      css_handler.render,
        attributes: svg_attributes,
        content:    to_s,
      }
    end

    def to_s
      content.join glue
    end

    def save(filename, template: nil, glue: nil)
      filename = "#{filename}.svg" unless /\..{2,4}$/.match?(filename)
      File.write filename, render(template: template, glue: glue)
    end

  protected

    def svg_template
      File.read template_path
    end

    def template_path
      if template.is_a? Symbol
        File.join File.dirname(__FILE__), 'templates', "#{template}.svg"
      else
        template
      end
    end
  end
end
module Victor
  class SVG < SVGBase
    def method_missing(method_sym, *arguments, &block)
      element method_sym, *arguments, &block
    end

    def respond_to_missing?(*)
      true
    end
  end
end
module Victor
  # Handles conversion from a Hash of attributes, to an XML string or
  # a CSS string.
  class Attributes
    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    def to_s
      mapped = attributes.map do |key, value|
        key = key.to_s.tr '_', '-'

        case value
        when Hash
          style = Attributes.new(value).to_style
          "#{key}=\"#{style}\""
        when Array
          "#{key}=\"#{value.join ' '}\""
        else
          "#{key}=#{value.to_s.encode(xml: :attr)}"
        end
      end

      mapped.join ' '
    end

    def to_style
      mapped = attributes.map do |key, value|
        key = key.to_s.tr '_', '-'
        "#{key}:#{value}"
      end

      mapped.join '; '
    end

    def [](key)
      attributes[key]
    end

    def []=(key, value)
      attributes[key] = value
    end
  end
end
module Victor
  class CSS
    attr_reader :attributes

    def initialize(attributes = nil)
      @attributes = attributes || {}
    end

    def to_s
      convert_hash attributes
    end

    def render
      return '' if attributes.empty?

      %{<style type="text/css">\n<![CDATA[\n#{self}\n]]>\n</style>\n}
    end

  protected

    def convert_hash(hash, indent = 2)
      return hash unless hash.is_a? Hash

      result = []
      hash.each do |key, value|
        key = key.to_s.tr '_', '-'
        result += css_block(key, value, indent)
      end

      result.join "\n"
    end

    def css_block(key, value, indent)
      result = []

      my_indent = ' ' * indent

      case value
      when Hash
        result.push "#{my_indent}#{key} {"
        result.push convert_hash(value, indent + 2)
        result.push "#{my_indent}}"
      when Array
        value.each do |row|
          result.push "#{my_indent}#{key} #{row};"
        end
      else
        result.push "#{my_indent}#{key}: #{value};"
      end

      result
    end
  end
end
require 'forwardable'

module Victor
  module DSL
    extend Forwardable
    def_delegators :svg, :setup, :build, :save, :render, :append, :element, :css

    def svg
      @svg ||= Victor::SVG.new
    end
  end
end
