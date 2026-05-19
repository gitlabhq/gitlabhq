# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TenantContainerLifecycle::Stateful::TransitionValidation, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  describe '#ensure_transition_user' do
    describe 'events requiring transition_user' do
      it 'blocks schedule_deletion when transition_user is not provided' do
        expect { organization.schedule_deletion }.not_to change { organization.reload.state_name }
        expect(organization.errors[:state]).to include('schedule_deletion transition needs transition_user')
      end

      it 'allows schedule_deletion when transition_user is provided' do
        expect { organization.schedule_deletion(transition_user: user) }
          .to change { organization.reload.state_name }
          .from(:active)
          .to(:deletion_scheduled)
        expect(organization.errors).to be_empty
      end
    end

    describe 'events not requiring transition_user' do
      where(:event, :from_state, :to_state) do
        :start_deletion      | :deletion_scheduled   | :deletion_in_progress
        :reschedule_deletion | :deletion_in_progress | :deletion_scheduled
        :cancel_deletion     | :deletion_scheduled   | :active
        :cancel_deletion     | :deletion_in_progress | :active
      end

      with_them do
        before do
          organization.update_column(:state, Organizations::Organization.states[from_state.to_s])
        end

        it "allows #{params[:event]} without transition_user" do
          expect { organization.public_send(event) }
            .to change { organization.reload.state_name }
            .from(from_state)
            .to(to_state)
          expect(organization.errors).to be_empty
        end
      end
    end
  end
end
