# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InvitationReminderEmailService, feature_category: :groups_and_projects do
  describe 'sending invitation reminders' do
    subject { described_class.new(invitation).execute }

    let_it_be(:frozen_time) { Date.today.beginning_of_day }
    let_it_be(:invitation) { build(:group_member, :invited, created_at: frozen_time) }

    before do
      invitation.expires_at = frozen_time + expires_at_days.days if expires_at_days
    end

    using RSpec::Parameterized::TableSyntax

    where(:expires_at_days, :send_reminder_at_days) do
      0   | []
      1   | []
      2   | [1]
      3   | [1, 2]
      4   | [1, 2, 3]
      5   | [1, 2, 4]
      6   | [1, 3, 5]
      7   | [1, 3, 5]
      8   | [2, 3, 6]
      9   | [2, 4, 7]
      10  | [2, 4, 8]
      11  | [2, 4, 8]
      12  | [2, 5, 9]
      13  | [2, 5, 10]
      14  | [2, 5, 10]
      15  | [2, 5, 10]
      nil | [2, 5, 10]
    end

    with_them do
      # Create an invitation today with an expiration date from 0 to 10 days in the future or without an expiration date
      # We chose 10 days here, because we fetch invitations that were created at most 10 days ago.
      11.times do |day|
        it 'sends an invitation reminder only on the expected days' do
          next if day > (expires_at_days || 10) # We don't need to test after the invitation has already expired

          # We are traveling in a loop from today to 10 days from now
          travel_to(frozen_time + day.days) do
            # Given an expiration date and the number of days after the creation of the invitation based on the current day in the loop, a reminder may be sent
            if (reminder_index = send_reminder_at_days.index(day))
              expect(invitation).to receive(:send_invitation_reminder).with(reminder_index)
            else
              expect(invitation).not_to receive(:send_invitation_reminder)
            end

            subject
          end
        end
      end
    end
  end
end
