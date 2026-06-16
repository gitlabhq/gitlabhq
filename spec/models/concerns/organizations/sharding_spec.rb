# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Sharding, feature_category: :organization do
  before_all do
    Organizations::ShardingTestModel.ensure_table_exists
  end

  after(:all) do
    Organizations::ShardingTestModel.cleanup_table
  end

  describe '#after_commit' do
    describe 'check_organization_isolation_status' do
      let_it_be_with_reload(:issue) { create(:issue) }
      let_it_be(:other_issue) { create(:issue) }

      context "when the feature flag 'isolation_status_check' is disabled" do
        before do
          stub_feature_flags(isolation_status_check: false)
        end

        it 'does not schedule a organization isolation status check' do
          expect(Organizations::CheckOrganizationIsolationStatusWorker).not_to receive(:perform_async)

          issue.update!(duplicated_to: other_issue)
        end
      end

      context "when the feature flag 'isolation_status_check' is enabled" do
        before do
          stub_feature_flags(isolation_status_check: true)
        end

        it 'schedules a organization isolation status check when belongs_to relation is updated' do
          expect(Organizations::CheckOrganizationIsolationStatusWorker)
            .to receive(:perform_async)
            .with(issue.class.name, issue.id, { 'duplicated_to_id' => [nil, other_issue.id] })

          issue.update!(duplicated_to: other_issue)
        end
      end

      context 'when belongs_to relation is updated' do
        context 'and the model does not have sharding keys' do
          before do
            allow(issue.class).to receive(:sharding_keys).and_return({})
          end

          it 'does not schedule a organization isolation status check' do
            expect(Organizations::CheckOrganizationIsolationStatusWorker).not_to receive(:perform_async)

            issue.update!(
              title: "new title",
              duplicated_to: other_issue
            )
          end
        end

        context 'and the model has sharding keys' do
          it 'schedules a organization isolation status check' do
            expect(Organizations::CheckOrganizationIsolationStatusWorker)
              .to receive(:perform_async)
              .with(issue.class.name, issue.id, { 'duplicated_to_id' => [nil, other_issue.id] })

            issue.update!(
              title: "new title",
              duplicated_to: other_issue
            )
          end
        end
      end

      context 'when no belongs_to relation is updated' do
        it 'does not schedule a organization isolation status check' do
          expect(Organizations::CheckOrganizationIsolationStatusWorker).not_to receive(:perform_async)

          issue.update!(title: "new title")
        end
      end
    end
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

  describe '#organization' do
    let_it_be(:namespace) { create(:namespace, organization: create(:organization)) }
    let_it_be(:project) { create(:project, organization: create(:organization)) }
    let_it_be(:user) { create(:user, organization: create(:organization)) }
    let_it_be(:organization) { create(:organization) }

    let(:test_model_class) do
      Organizations::ShardingTestModel.create_test_model(
        sharding_keys: sharding_keys
      )
    end

    subject(:sharded_organization) { test_object.organization }

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
        { 'project_id' => 'unsupported_table' }
      end

      let(:test_object) { test_model_class.create!(project: project) }

      it { is_expected.to be_nil }
    end

    context 'when no sharding key is defined' do
      let(:sharding_keys) do
        {}
      end

      let(:test_object) { test_model_class.create!(project: project) }

      it { is_expected.to be_nil }
    end

    context 'when the model is having two sharding keys' do
      let(:sharding_keys) do
        {
          'namespace_id' => 'namespaces',
          'project_id' => 'projects'
        }
      end

      context 'and the first is set' do
        let(:test_object) { test_model_class.create!(namespace: namespace) }

        it { is_expected.to eq(namespace.organization) }
      end

      context 'and the second is set' do
        let(:test_object) { test_model_class.create!(project: project) }

        it { is_expected.to eq(project.organization) }
      end

      context 'and no organization is found' do
        let(:test_object) { test_model_class.create!(project: project) }

        before do
          allow(::Organizations::Organization)
            .to receive_message_chain(:joins, :find_by)
            .and_return(nil)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
