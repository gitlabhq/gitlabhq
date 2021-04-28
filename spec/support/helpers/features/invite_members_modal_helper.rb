# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      module Features
        module InviteMembersModalHelper
          def invite_member(name, role: 'Guest', expires_at: nil)
            click_on 'Invite members'

            page.within '#invite-members-modal' do
              fill_in 'Select members or type email addresses', with: name

              wait_for_requests
              click_button name

              fill_in 'YYYY-MM-DD', with: expires_at.try(:strftime, '%Y-%m-%d')

              unless role == 'Guest'
                click_button 'Guest'
                wait_for_requests
                click_button role
              end

              click_button 'Invite'
            end

            page.refresh
          end
        end
      end
    end
  end
end
