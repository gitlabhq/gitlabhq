# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      module Features
        module InviteMembersModalHelper
          def invite_member(name, role: 'Guest', expires_at: nil)
            click_on 'Invite members'

            page.within '#invite-members-modal' do
              find('[data-testid="members-token-select-input"]').set(name)

              wait_for_requests
              click_button name
              choose_options(role, expires_at)

              click_button 'Invite'

              page.refresh
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

            fill_in 'YYYY-MM-DD', with: expires_at.try(:strftime, '%Y-%m-%d')
          end
        end
      end
    end
  end
end
