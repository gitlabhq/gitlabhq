# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::ProjectDeleteService, feature_category: :user_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:service_account_user) { create(:service_account, provisioned_by_project_id: project.id) }
  let_it_be(:options, freeze: false) { { hard_delete: false } }

  subject(:service) { described_class.new(current_user, service_account_user) }

  describe '#execute' do
    context 'when current user is an admin', :enable_admin_mode do
      let_it_be(:current_user) { create(:admin) }

      it_behaves_like 'service account deletion success'
    end

    context 'when current user is a project owner' do
      let_it_be(:current_user) { create(:user, owner_of: project) }

      it_behaves_like 'service account deletion success'
    end

    context 'when current user is a project maintainer' do
      let_it_be(:current_user) { create(:user, maintainer_of: project) }

      it_behaves_like 'service account deletion success'
    end

    context 'when current user is a project developer' do
      let_it_be(:current_user) { create(:user, developer_of: project) }

      it_behaves_like 'service account deletion failure'
    end

    context 'when user to be deleted is not provisioned by a project' do
      let_it_be(:non_provisioned_user) { create(:user) }
      let_it_be(:current_user) { create(:user, maintainer_of: project) }

      subject(:service) { described_class.new(current_user, non_provisioned_user) }

      it_behaves_like 'service account deletion failure' do
        let(:user_under_test) { non_provisioned_user }
      end
    end
  end
end
