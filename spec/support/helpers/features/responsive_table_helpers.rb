# frozen_string_literal: true

# These helpers allow you to access rows in a responsive table
#
# Usage:
#   describe "..." do
#   include Features::ResponsiveTableHelpers
#     ...
#
#     expect(first_row.text).to include("John Doe")
#     expect(second_row.text).to include("John Smith")
#
# Note:
#   index starts at 1 as index 0 is expected to be the table header
#
#
module Features
  module ResponsiveTableHelpers
    def first_row
      page.all('.gl-responsive-table-row')[1]
    end

    def second_row
      page.all('.gl-responsive-table-row')[2]
    end
  end
end
