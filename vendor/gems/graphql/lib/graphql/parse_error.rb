# frozen_string_literal: true
module GraphQL
  class ParseError < GraphQL::Error
    attr_reader :line, :col, :query
    def initialize(message, line, col, query, filename: nil)
      if filename
        message += " (#{filename})"
      end

      super(message)
      @line = line
      @col = col
      @query = query
    end

    def to_h
      locations = line ? [{ "line" => line, "column" => col }] : []
      {
        "message" => message,
        "locations" => locations,
      }
    end
  end
end
