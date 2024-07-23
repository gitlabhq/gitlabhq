# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Current::Organization, feature_category: :cell do
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:organization) { create(:organization, name: 'Current Organization') }
  let_it_be(:default_organization) { create(:organization, :default) }
  let_it_be(:group) { create(:group, organization: organization) }
  let_it_be(:user) { create(:user) }

  let(:group_path) { group.full_path }
  let(:controller) { 'some_controller' }
  let(:action) { 'some_action' }
  let(:params) do
    {
      controller: controller,
      action: action
    }
  end

  before do
    default_organization.users.delete_all
    default_organization.reload

    organization.users << user
  end

  describe '.organization' do
    subject(:current_organization) { described_class.new(params: params, user: user).organization }

    context 'when params result in an organization' do
      let(:params) { super().merge(namespace_id: group_path) }

      it 'returns that organization' do
        expect(current_organization).to eq(organization)
      end
    end

    context 'when only current user result in an organization' do
      it 'returns that organization' do
        expect(current_organization).to eq(organization)
      end
    end

    context 'when no organization can be derived' do
      subject(:current_organization) { described_class.new(params: params, user: nil).organization }

      it 'falls back to default organization' do
        expect(current_organization).to eq(default_organization)
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
  end

  describe '.from_user' do
    let_it_be(:user) { create(:user) }

    subject(:current_organization) { described_class.new(user: user).from_user }

    it 'returns the organization the user is member of' do
      expect(current_organization).to eq(organization)
    end
  end
end
