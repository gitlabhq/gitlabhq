# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Sharding, feature_category: :organization do
  describe '.sharding_keys' do
    it 'returns sharding keys for the model' do
      expect(Group.sharding_keys).to eq({ 'organization_id' => 'organizations' })
    end

    context 'when no sharding key is defined' do
      let(:entry) { instance_double(Gitlab::Database::Dictionary::Entry, sharding_key: nil) }

      before do
        allow(Gitlab::Database::Dictionary).to receive(:entry).with('namespaces').and_return(entry)
      end

      after do
        Namespace.instance_variable_set(:@sharding_keys, nil)
      end

      it 'returns empty hash' do
        expect(Namespace.sharding_keys).to eq({})
      end
    end

    context 'when table does not exist in data dictionary' do
      before do
        allow(Gitlab::Database::Dictionary).to receive(:entry).with('namespaces').and_return(nil)
      end

      after do
        Namespace.instance_variable_set(:@sharding_keys, nil)
      end

      it 'returns empty hash' do
        expect(Namespace.sharding_keys).to eq({})
      end
    end
  end

  describe '#sharding_organization' do
    subject(:organization) { test_object.sharding_organization }

    context 'when the model is using organizations as sharding key' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:test_object) { create(:group, organization: organization) }

      it { is_expected.to eq(organization) }
    end

    context 'when the model is using namespaces as sharding key' do
      let_it_be(:group_organization) { create(:organization) }
      let_it_be(:group) { create(:group, organization: group_organization) }
      let_it_be(:test_object) { create(:group_member, group: group) }

      it { is_expected.to eq(group_organization) }
    end

    context 'when the model is using projects as sharding key' do
      let_it_be(:project_organization) { create(:organization) }
      let_it_be(:project) { create(:project, organization: project_organization) }
      let_it_be(:test_object) { create(:deploy_token, projects: [project]) }

      it { is_expected.to eq(project_organization) }
    end

    context 'when the model is using users as sharding key' do
      let_it_be(:user_organization) { create(:organization) }
      let_it_be(:user) { create(:user, organization: user_organization) }
      let_it_be(:test_object) { create(:user_detail, user: user) }

      it { is_expected.to eq(user_organization) }
    end

    context 'when the sharding key is nil' do
      let_it_be(:test_object) { create(:group) }

      before do
        attrs = test_object.attributes
        allow(test_object).to receive(:attributes).and_return(attrs)
        allow(attrs).to receive(:[]).with('organization_id').and_return(nil)
      end

      it { is_expected.to be_nil }
    end

    context 'when the sharding key table is not supported' do
      let_it_be(:test_object) { create(:group) }

      before do
        allow(test_object.class).to receive(:sharding_keys).and_return({ 'organization_id' => 'unsupported_table' })
      end

      it { is_expected.to be_nil }
    end

    context 'when no sharding key is defined' do
      let_it_be(:test_object) { create(:group) }

      before do
        allow(test_object.class).to receive(:sharding_keys).and_return({})
      end

      it { is_expected.to be_nil }
    end
  end
end
