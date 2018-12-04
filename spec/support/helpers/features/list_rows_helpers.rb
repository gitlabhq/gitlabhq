# frozen_string_literal: true
# These helpers allow you to access rows in the list
#
# Usage:
#   describe "..." do
#   include Spec::Support::Helpers::Features::ListRowsHelpers
#     ...
#
#     expect(first_row.text).to include("John Doe")
#     expect(second_row.text).to include("John Smith")
#
module Spec
  module Support
    module Helpers
      module Features
        module ListRowsHelpers
          def first_row
            page.all('ul.content-list > li')[0]
          end

          def second_row
            page.all('ul.content-list > li')[1]
          end
        end
      end
    end
  end
end
