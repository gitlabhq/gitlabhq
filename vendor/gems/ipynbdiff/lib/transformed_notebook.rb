# frozen_string_literal: true

module IpynbDiff
  # Notebook that was transformed into md, including location of source cells
  class TransformedNotebook
    attr_reader :blocks

    def as_text
      @blocks.map { |b| b[:content].gsub(/\n/, '\\n') }.join("\n")
    end

    private

    def initialize(lines = [], symbol_map = {})
      @blocks = lines.map do |line|
        { content: line[:content], source_symbol: (symbol = line[:symbol]), source_line: symbol && symbol_map[symbol] }
      end
    end
  end
end
