# frozen_string_literal: true

require_relative 'item'

module Tooling
  module Graphql
    module Docs
      module Schema
        # Temporary class for types that do not yet have a docs page.
        # Removed once all types have pages.
        class TempUndocumented < Item
        end
      end
    end
  end
end
