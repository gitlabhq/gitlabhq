# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      module Features
        module MembersHelpers
          def members_table
            page.find('[data-testid="members-table"]')
          end

          def all_rows
            page.within(members_table) do
              page.all('tbody > tr')
            end
          end

          def first_row
            all_rows[0]
          end

          def second_row
            all_rows[1]
          end

          def third_row
            all_rows[2]
          end

          def invite_users_form
            page.find('[data-testid="invite-users-form"]')
          end
        end
      end
    end
  end
end
