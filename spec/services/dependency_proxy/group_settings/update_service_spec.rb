# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::DependencyProxy::GroupSettings::UpdateService, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:group_settings) { create(:dependency_proxy_group_setting, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { { enabled: false } }

  describe '#execute' do
    subject { described_class.new(container: group, current_user: user, params: params).execute }

    shared_examples 'updating the dependency proxy group settings' do
      it_behaves_like 'updating the dependency proxy group settings attributes',
        from: { enabled: true },
        to: { enabled: false }

      it 'returns a success' do
        result = subject

        expect(result.payload[:dependency_proxy_setting]).to be_present
        expect(result).to be_success
      end
    end

    shared_examples 'denying access to dependency proxy group settings' do
      context 'with existing dependency proxy group settings' do
        it 'returns an error' do
          result = subject

          expect(result).to have_attributes(
            message: 'Access Denied',
            status: :error,
            http_status: 403
          )
        end
      end
    end

    where(:user_role, :shared_examples_name) do
      :owner      | 'updating the dependency proxy group settings'
      :maintainer | 'denying access to dependency proxy group settings'
      :developer  | 'denying access to dependency proxy group settings'
      :reporter   | 'denying access to dependency proxy group settings'
      :guest      | 'denying access to dependency proxy group settings'
      :anonymous  | 'denying access to dependency proxy group settings'
    end

    with_them do
      before do
        stub_config(dependency_proxy: { enabled: true })
        group.send("add_#{user_role}", user) unless user_role == :anonymous
      end

      it_behaves_like params[:shared_examples_name]
    end
  end
end
