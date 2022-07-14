# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      module Features
        module InviteMembersModalHelper
          def invite_member(names, role: 'Guest', expires_at: nil, refresh: true)
            click_on 'Invite members'

            page.within invite_modal_selector do
              select_members(names)
              choose_options(role, expires_at)
              click_button 'Invite'
            end

            page.refresh if refresh
          end

          def input_invites(names)
            click_on 'Invite members'

            page.within invite_modal_selector do
              select_members(names)
            end
          end

          def select_members(names)
            Array.wrap(names).each do |name|
              find(member_dropdown_selector).set(name)

              wait_for_requests
              click_button name
            end
          end

          def invite_group(name, role: 'Guest', expires_at: nil)
            click_on 'Invite a group'

            click_on 'Select a group'
            wait_for_requests
            click_button name
            choose_options(role, expires_at)

            click_button 'Invite'

            page.refresh
          end

          def choose_options(role, expires_at)
            unless role == 'Guest'
              click_button 'Guest'
              wait_for_requests
              click_button role
            end

            fill_in 'YYYY-MM-DD', with: expires_at.strftime('%Y-%m-%d') if expires_at
          end

          def click_groups_tab
            expect(page).to have_link 'Groups'
            click_link "Groups"
          end

          def group_dropdown_selector
            '[data-testid="group-select-dropdown"]'
          end

          def member_dropdown_selector
            '[data-testid="members-token-select-input"]'
          end

          def invite_modal_selector
            '[data-testid="invite-modal"]'
          end

          def member_token_error_selector(id)
            "[data-testid='error-icon-#{id}']"
          end

          def member_token_avatar_selector
            "[data-testid='token-avatar']"
          end

          def member_token_selector(id)
            "[data-token-id='#{id}']"
          end

          def remove_token(id)
            page.within member_token_selector(id) do
              find('[data-testid="close-icon"]').click
            end
          end

          def expect_to_have_group(group)
            expect(page).to have_selector("[entity-id='#{group.id}']")
          end

          def expect_not_to_have_group(group)
            expect(page).not_to have_selector("[entity-id='#{group.id}']")
          end
        end
      end
    end
  end
end
