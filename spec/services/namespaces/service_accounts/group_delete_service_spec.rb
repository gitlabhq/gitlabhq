# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::GroupDeleteService, feature_category: :user_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:service_account_user) { create(:service_account, provisioned_by_group: group) }
  let_it_be(:options, freeze: false) { { hard_delete: false } }

  subject(:service) { described_class.new(current_user, service_account_user) }

  describe '#execute' do
    context 'when current user is an admin', :enable_admin_mode do
      let_it_be(:current_user) { create(:admin) }

      it_behaves_like 'service account deletion success'
    end

    context 'when current user is a maintainer' do
      let_it_be(:current_user) { create(:user, maintainer_of: group) }

      it_behaves_like 'service account deletion failure'
    end

    context 'when user to be deleted is not provisioned by a group' do
      let_it_be(:current_user) { create(:admin) }
      let_it_be(:non_provisioned_user) { create(:user) }

      subject(:service) { described_class.new(current_user, non_provisioned_user) }

      it_behaves_like 'service account deletion failure' do
        let(:user_under_test) { non_provisioned_user }
      end
    end
  end
end
