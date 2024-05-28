# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::DependencyProxy::ImageTtlGroupPolicies::UpdateService, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { {} }

  describe '#execute' do
    subject { described_class.new(container: group, current_user: user, params: params).execute }

    shared_examples 'returning a success' do
      it 'returns a success' do
        result = subject

        expect(result.payload[:dependency_proxy_image_ttl_policy]).to be_present
        expect(result).to be_success
      end
    end

    shared_examples 'returning an error' do |message, http_status|
      it 'returns an error' do
        result = subject

        expect(result).to have_attributes(
          message: message,
          status: :error,
          http_status: http_status
        )
      end
    end

    shared_examples 'updating the dependency proxy image ttl policy' do
      it_behaves_like 'updating the dependency proxy image ttl policy attributes',
        from: { enabled: true, ttl: 90 },
        to: { enabled: false, ttl: 2 }

      it_behaves_like 'returning a success'

      context 'with invalid params' do
        let_it_be(:params) { { enabled: nil } }

        it_behaves_like 'not creating the dependency proxy image ttl policy'

        it "doesn't update" do
          expect { subject }
            .not_to change { ttl_policy.reload.enabled }
        end

        it_behaves_like 'returning an error', 'Enabled is not included in the list', 400
      end
    end

    shared_examples 'denying access to dependency proxy image ttl policy' do
      context 'with existing dependency proxy image ttl policy' do
        it_behaves_like 'not creating the dependency proxy image ttl policy'

        it_behaves_like 'returning an error', 'Access Denied', 403
      end
    end

    before do
      stub_config(dependency_proxy: { enabled: true })
    end

    context 'with existing dependency proxy image ttl policy' do
      let_it_be(:ttl_policy) { create(:image_ttl_group_policy, group: group) }
      let_it_be(:params) { { enabled: false, ttl: 2 } }

      where(:user_role, :shared_examples_name) do
        :owner      | 'updating the dependency proxy image ttl policy'
        :maintainer | 'denying access to dependency proxy image ttl policy'
        :developer  | 'denying access to dependency proxy image ttl policy'
        :reporter   | 'denying access to dependency proxy image ttl policy'
        :guest      | 'denying access to dependency proxy image ttl policy'
        :anonymous  | 'denying access to dependency proxy image ttl policy'
      end

      with_them do
        before do
          group.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing dependency proxy image ttl policy' do
      let_it_be(:ttl_policy) { group.dependency_proxy_image_ttl_policy }

      where(:user_role, :shared_examples_name) do
        :owner      | 'creating the dependency proxy image ttl policy'
        :maintainer | 'denying access to dependency proxy image ttl policy'
        :developer  | 'denying access to dependency proxy image ttl policy'
        :reporter   | 'denying access to dependency proxy image ttl policy'
        :guest      | 'denying access to dependency proxy image ttl policy'
        :anonymous  | 'denying access to dependency proxy image ttl policy'
      end

      with_them do
        before do
          group.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end

      context 'when the policy is not found' do
        before_all do
          group.add_owner(user)
        end

        before do
          expect(group).to receive(:dependency_proxy_image_ttl_policy).and_return nil
        end

        it_behaves_like 'returning an error', 'Dependency proxy image TTL Policy not found', 404
      end
    end
  end
end
