# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::MergeRequestsController, feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'PATCH #update' do
    subject(:update_group_mr_settings) do
      patch group_settings_merge_requests_path(group), params: {
        group_id: group,
        namespace_setting: {
          require_sha_for_merge: true,
          lock_require_sha_for_merge: true
        }
      }
    end

    context 'when user cannot manage merge request settings' do
      it 'respond status :not_found' do
        update_group_mr_settings
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user can manage merge request settings' do
      before_all do
        group.add_owner(user)
      end

      it { is_expected.to redirect_to(edit_group_path(group, anchor: 'js-merge-requests-settings')) }

      context 'when service execution went wrong' do
        let(:update_service) { double }

        before do
          allow_next_instance_of(Groups::UpdateService) do |service|
            allow(service).to receive(:execute).and_return(false)
          end
          update_group_mr_settings
        end

        it 'returns a flash alert' do
          expect(flash[:alert]).to eq("Group '#{group.name}' could not be updated.")
        end
      end

      context 'when service execution was successful' do
        it 'returns a flash notice' do
          update_group_mr_settings

          expect(flash[:notice]).to eq("Group '#{group.name}' was successfully updated.")
          expect(group.namespace_settings.reload).to have_attributes(
            require_sha_for_merge: true,
            lock_require_sha_for_merge: true
          )
        end
      end
    end
  end
end
