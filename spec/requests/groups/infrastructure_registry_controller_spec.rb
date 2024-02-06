# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::InfrastructureRegistryController, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  describe 'GET #index' do
    subject { get group_infrastructure_registry_index_path(group) }

    context 'when user is not signed in' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      context 'when user is not a group member' do
        it_behaves_like 'returning response status', :not_found
      end

      context 'when user is group maintainer' do
        before_all do
          group.add_maintainer(user)
        end

        it_behaves_like 'returning response status', :ok

        context 'when the packages registry is not available' do
          before do
            stub_config(packages: { enabled: false })
          end

          it_behaves_like 'returning response status', :not_found
        end
      end
    end
  end
end
