# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::UpdateService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create :project }
  let_it_be(:group_user) { create(:user, maintainer_of: group) }

  let(:group_access) { Gitlab::Access::DEVELOPER }

  let!(:link) { create(:project_group_link, project: project, group: group, group_access: group_access) }

  let(:expiry_date) { 1.month.from_now.to_date }
  let(:group_link_params) do
    { group_access: Gitlab::Access::GUEST,
      expires_at: expiry_date }
  end

  subject { described_class.new(link, user).execute(group_link_params) }

  context 'when the user does not have proper permissions to update a project group link' do
    it 'returns 404 not found' do
      result = subject

      expect(result[:status]).to eq(:error)
      expect(result[:reason]).to eq(:not_found)
    end
  end

  context 'when user has proper permissions to update a project group link' do
    context 'when the user is an OWNER in the project' do
      before do
        project.add_owner(user)
      end

      context 'updating expires_at' do
        let(:group_link_params) do
          { expires_at: 7.days.from_now.to_date }
        end

        it 'updates existing link' do
          expect do
            result = subject

            expect(result[:status]).to eq(:success)
          end.to change { link.reload.expires_at }.to(group_link_params[:expires_at])
        end
      end

      context 'updating group_access' do
        let(:group_link_params) do
          { group_access: Gitlab::Access::MAINTAINER }
        end

        it 'updates existing link' do
          expect do
            result = subject

            expect(result[:status]).to eq(:success)
          end.to change { link.reload.group_access }.to(group_link_params[:group_access])
        end
      end

      context 'updating both expires_at and group_access' do
        it 'updates existing link' do
          expect do
            result = subject

            expect(result[:status]).to eq(:success)
          end.to change { link.reload.group_access }.to(group_link_params[:group_access])
            .and change { link.reload.expires_at }.to(group_link_params[:expires_at])
        end
      end
    end
  end
end
