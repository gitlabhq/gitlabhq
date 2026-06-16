# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TenantContainerLifecycle::Stateful::TransitionValidation, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  describe '#ensure_transition_user' do
    describe 'events requiring transition_user' do
      where(:event, :from_state, :to_state) do
        :soft_delete         | :active                | :soft_deleted
        :hard_delete         | :soft_deleted          | :deletion_in_progress
        :abort_hard_deletion | :deletion_in_progress  | :soft_deleted
      end

      with_them do
        before do
          organization.update_column(:state, Organizations::Organization.states[from_state.to_s])
        end

        it "blocks #{params[:event]} when transition_user is not provided" do
          expect { organization.public_send(event) }.not_to change { organization.reload.state_name }
          expect(organization.errors[:state]).to include("#{event} transition needs transition_user")
        end

        it "allows #{params[:event]} when transition_user is provided" do
          expect { organization.public_send(event, transition_user: user) }
            .to change { organization.reload.state_name }
            .from(from_state)
            .to(to_state)
          expect(organization.errors).to be_empty
        end
      end
    end

    describe 'events not requiring transition_user' do
      where(:event, :from_state, :to_state) do
        :restore | :soft_deleted | :active
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
