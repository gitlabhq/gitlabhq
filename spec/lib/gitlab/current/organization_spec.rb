# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Current::Organization, feature_category: :cell do
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:organization) { create(:organization, name: 'Current Organization') }
  let_it_be(:default_organization) { create(:organization, :default) }
  let_it_be(:group) { create(:group, organization: organization) }

  let(:group_path) { group.full_path }
  let(:controller) { 'some_controller' }
  let(:action) { 'some_action' }
  let(:params) do
    {
      controller: controller,
      action: action
    }
  end

  shared_examples 'operation that derives organization from user' do
    let_it_be(:user) do
      create(:user, organization_users: [create(:organization_user, organization: organization)])
    end

    subject(:current_organization) { described_class.new(params: params, user: user).organization }

    it 'returns that organization' do
      expect(current_organization).to eq(organization)
    end
  end

  describe '.organization' do
    context 'when params result in an organization', :request_store do
      let(:params) { super().merge(namespace_id: group_path) }

      subject(:current_organization) { described_class.new(params: params).organization }

      it 'returns that organization' do
        expect(current_organization).to eq(organization)
      end

      it 'does not enable fallback organization tracking', :request_store do
        current_organization

        expect(Gitlab::Organizations::FallbackOrganizationTracker.enabled?).to be(false)
      end
    end

    context 'when only current user result in an organization' do
      it_behaves_like 'operation that derives organization from user'
    end

    context 'when no organization can be derived' do
      subject(:current_organization) { described_class.new(params: params).organization }

      it 'falls back to default organization' do
        expect(current_organization).to eq(default_organization)
      end

      it 'enables fallback organization tracking', :request_store do
        current_organization

        expect(Gitlab::Organizations::FallbackOrganizationTracker.enabled?).to be(true)
      end
    end
  end

  describe '.from_params' do
    subject(:current_organization) { described_class.new(params: params).from_params }

    context 'when params contains namespace_id' do
      let(:params) { super().merge(namespace_id: group_path) }

      context 'and namespace is found' do
        it { is_expected.to eq(organization) }
      end

      context 'and namespace is not found' do
        let(:group_path) { 'not_found' }

        it { is_expected.to be(nil) }
      end

      context 'and namespace_id is empty string' do
        let(:params) { super().merge(namespace_id: '') }

        it { is_expected.to be(nil) }

        it 'does not execute query' do
          expect { current_organization }.to match_query_count(0)
        end
      end
    end

    context 'when params contains group_id' do
      let(:params) { super().merge(group_id: group_path) }

      context 'and namespace is found' do
        it { is_expected.to eq(organization) }
      end

      context 'and namespace is not found' do
        let(:group_path) { 'not_found' }

        it { is_expected.to be(nil) }
      end
    end

    context 'when params contains id' do
      let(:params) { super().merge(id: group_path) }

      context 'and controller is groups' do
        let(:controller) { 'groups' }

        context 'and namespace is found' do
          it { is_expected.to eq(organization) }
        end

        context 'and namespace is not found' do
          let(:group_path) { non_existing_record_id }

          it { is_expected.to be(nil) }
        end
      end

      context 'and controller is not groups' do
        it { is_expected.to be(nil) }
      end
    end

    context 'when params contains organization_path' do
      context 'and path exists' do
        let(:params) { super().merge(organization_path: other_organization.path) }

        it { is_expected.to eq(other_organization) }
      end

      context 'and path does not exists' do
        let(:params) { super().merge(organization_path: non_existing_record_id) }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '.from_user' do
    it_behaves_like 'operation that derives organization from user'
  end
end
