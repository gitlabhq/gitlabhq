# frozen_string_literal: true

module Tooling
  module Danger
    module Clickhouse
      def changes
        helper.changes_by_category[:clickhouse]
      end
    end
  end
end
