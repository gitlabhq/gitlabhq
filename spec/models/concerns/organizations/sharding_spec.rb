# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Sharding, feature_category: :organization do
  before_all do
    Organizations::ShardingTestModel.ensure_table_exists
  end

  after(:all) do
    Organizations::ShardingTestModel.cleanup_table
  end

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
    let_it_be(:namespace) { create(:namespace, organization: create(:organization)) }
    let_it_be(:project) { create(:project, organization: create(:organization)) }
    let_it_be(:user) { create(:user, organization: create(:organization)) }
    let_it_be(:organization) { create(:organization) }

    let(:test_model_class) do
      Organizations::ShardingTestModel.create_test_model(
        sharding_keys: sharding_keys
      )
    end

    subject(:sharded_organization) { test_object.sharding_organization }

    context 'when the model is using organizations as sharding key' do
      let(:sharding_keys) do
        { 'organization_id' => 'organizations' }
      end

      let(:test_object) { test_model_class.create!(organization: organization) }

      it { is_expected.to eq(organization) }
    end

    context 'when the model is using namespaces as sharding key' do
      let(:sharding_keys) do
        { 'namespace_id' => 'namespaces' }
      end

      let(:test_object) { test_model_class.create!(namespace: namespace) }

      it { is_expected.to eq(namespace.organization) }
    end

    context 'when the model is using projects as sharding key' do
      let(:sharding_keys) do
        { 'project_id' => 'projects' }
      end

      let(:test_object) { test_model_class.create!(project: project) }

      it { is_expected.to eq(project.organization) }
    end

    context 'when the model is using users as sharding key' do
      let(:sharding_keys) do
        { 'user_id' => 'users' }
      end

      let(:test_object) { test_model_class.create!(user: user) }

      it { is_expected.to eq(user.organization) }
    end

    context 'when the sharding key attribute is nil' do
      let(:sharding_keys) do
        { 'organization_id' => 'organizations' }
      end

      let(:test_object) { test_model_class.create! }

      it { is_expected.to be_nil }
    end

    context 'when the sharding key table is not supported' do
      let(:sharding_keys) do
        { 'organization_id' => 'unsupported_table' }
      end

      let(:test_object) { test_model_class.create!(organization: organization) }

      it { is_expected.to be_nil }
    end

    context 'when no sharding key is defined' do
      let(:sharding_keys) do
        {}
      end

      let(:test_object) { test_model_class.create!(organization: organization) }

      it { is_expected.to be_nil }
    end

    context 'when the model is having multiple sharding keys' do
      let(:sharding_keys) do
        {
          'organization_id' => 'organizations',
          'project_id' => 'projects'
        }
      end

      context 'and they refer to the same organization' do
        let(:test_object) { test_model_class.create!(project: project, organization: project.organization) }

        it { is_expected.to eq(project.organization) }
      end

      context 'and they refer to different organizations' do
        let(:test_object) { test_model_class.create!(project: project, organization: create(:organization)) }

        it { is_expected.to be_nil }
      end

      context 'and no organization is found' do
        let(:test_object) { test_model_class.create!(organization: create(:organization)) }

        before do
          allow(::Organizations::Organization).to receive(:find_by).and_return(nil)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
