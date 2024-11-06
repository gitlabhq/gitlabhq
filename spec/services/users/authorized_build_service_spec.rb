# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::AuthorizedBuildService, feature_category: :user_management do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:organization) { create(:organization) }
    let_it_be(:organization_params) { { organization_id: organization.id } }

    let(:base_params) do
      build_stubbed(:user)
        .slice(:first_name, :last_name, :name, :username, :email, :password)
        .merge(organization_params)
    end

    let(:params) { base_params }

    subject(:user) { described_class.new(current_user, params).execute }

    it_behaves_like 'common user build items'
    it_behaves_like 'current user not admin build items'

    context 'for additional authorized build allowed params' do
      before do
        params.merge!(external: true)
      end

      it { expect(user).to be_external }

      context 'when user_type is provided' do
        context 'when project_bot' do
          let_it_be(:group) { create(:group) }

          before do
            params.merge!({ user_type: :project_bot, bot_namespace: group })
          end

          it { expect(user.project_bot?).to be true }
          it { expect(user.bot_namespace).to eq(group) }
        end

        context 'when not a project_bot' do
          before do
            params.merge!({ user_type: :alert_bot })
          end

          it { expect(user).to be_human }
        end
      end
    end
  end
end
