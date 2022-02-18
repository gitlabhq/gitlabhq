# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe "Associations" do
    it { is_expected.to belong_to(:project).inverse_of(:integrations) }
    it { is_expected.to belong_to(:group).inverse_of(:integrations) }
    it { is_expected.to have_one(:service_hook).inverse_of(:integration).with_foreign_key(:service_id) }
    it { is_expected.to have_one(:issue_tracker_data).autosave(true).inverse_of(:integration).with_foreign_key(:service_id).class_name('Integrations::IssueTrackerData') }
    it { is_expected.to have_one(:jira_tracker_data).autosave(true).inverse_of(:integration).with_foreign_key(:service_id).class_name('Integrations::JiraTrackerData') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to validate_exclusion_of(:type).in_array(described_class::BASE_CLASSES) }

    where(:project_id, :group_id, :instance, :valid) do
      1    | nil  | false  | true
      nil  | 1    | false  | true
      nil  | nil  | true   | true
      nil  | nil  | false  | false
      1    | 1    | false  | false
      1    | nil  | false  | true
      1    | nil  | true   | false
      nil  | 1    | false  | true
      nil  | 1    | true   | false
    end

    with_them do
      it 'validates the integration' do
        expect(build(:integration, project_id: project_id, group_id: group_id, instance: instance).valid?).to eq(valid)
      end
    end

    context 'with existing integrations' do
      before_all do
        create(:integration, :instance)
        create(:integration, project: project)
        create(:integration, group: group, project: nil)
      end

      it 'allows only one instance integration per type' do
        expect(build(:integration, :instance)).to be_invalid
      end

      it 'allows only one project integration per type' do
        expect(build(:integration, project: project)).to be_invalid
      end

      it 'allows only one group integration per type' do
        expect(build(:integration, group: group, project: nil)).to be_invalid
      end
    end
  end

  describe 'Scopes' do
    describe '.with_default_settings' do
      it 'returns the correct integrations' do
        instance_integration = create(:integration, :instance)
        inheriting_integration = create(:integration, inherit_from_id: instance_integration.id)

        expect(described_class.with_default_settings).to match_array([inheriting_integration])
      end
    end

    describe '.with_custom_settings' do
      it 'returns the correct integrations' do
        instance_integration = create(:integration, :instance)
        create(:integration, inherit_from_id: instance_integration.id)

        expect(described_class.with_custom_settings).to match_array([instance_integration])
      end
    end

    describe '.by_type' do
      let!(:integration1) { create(:jira_integration) }
      let!(:integration2) { create(:jira_integration) }
      let!(:integration3) { create(:redmine_integration) }

      subject { described_class.by_type(type) }

      context 'when type is "JiraService"' do
        let(:type) { 'JiraService' }

        it { is_expected.to match_array([integration1, integration2]) }
      end

      context 'when type is "RedmineService"' do
        let(:type) { 'RedmineService' }

        it { is_expected.to match_array([integration3]) }
      end
    end

    describe '.for_group' do
      let!(:integration1) { create(:jira_integration, project_id: nil, group_id: group.id) }
      let!(:integration2) { create(:jira_integration) }

      it 'returns the right group integration' do
        expect(described_class.for_group(group)).to match_array([integration1])
      end
    end

    shared_examples 'hook scope' do |hook_type|
      describe ".#{hook_type}_hooks" do
        it "includes services where #{hook_type}_events is true" do
          create(:integration, active: true, "#{hook_type}_events": true)

          expect(described_class.send("#{hook_type}_hooks").count).to eq 1
        end

        it "excludes services where #{hook_type}_events is false" do
          create(:integration, active: true, "#{hook_type}_events": false)

          expect(described_class.send("#{hook_type}_hooks").count).to eq 0
        end
      end
    end

    include_examples 'hook scope', 'confidential_note'
    include_examples 'hook scope', 'alert'
    include_examples 'hook scope', 'archive_trace'
  end

  describe '#operating?' do
    it 'is false when the integration is not active' do
      expect(build(:integration).operating?).to eq(false)
    end

    it 'is false when the integration is not persisted' do
      expect(build(:integration, active: true).operating?).to eq(false)
    end

    it 'is true when the integration is active and persisted' do
      expect(create(:integration, active: true).operating?).to eq(true)
    end
  end

  describe '#testable?' do
    context 'when integration is project-level' do
      subject { build(:integration, project: project) }

      it { is_expected.to be_testable }
    end

    context 'when integration is not project-level' do
      subject { build(:integration, project: nil) }

      it { is_expected.not_to be_testable }
    end
  end

  describe '#test' do
    let(:integration) { build(:integration, project: project) }
    let(:data) { 'test' }

    it 'calls #execute' do
      expect(integration).to receive(:execute).with(data)

      integration.test(data)
    end

    it 'returns a result' do
      result = 'foo'
      allow(integration).to receive(:execute).with(data).and_return(result)

      expect(integration.test(data)).to eq(
        success: true,
        result: result
      )
    end
  end

  describe '#project_level?' do
    it 'is true when integration has a project' do
      expect(build(:integration, project: project)).to be_project_level
    end

    it 'is false when integration has no project' do
      expect(build(:integration, project: nil)).not_to be_project_level
    end
  end

  describe '#group_level?' do
    it 'is true when integration has a group' do
      expect(build(:integration, group: group)).to be_group_level
    end

    it 'is false when integration has no group' do
      expect(build(:integration, group: nil)).not_to be_group_level
    end
  end

  describe '#instance_level?' do
    it 'is true when integration has instance-level integration' do
      expect(build(:integration, :instance)).to be_instance_level
    end

    it 'is false when integration does not have instance-level integration' do
      expect(build(:integration, instance: false)).not_to be_instance_level
    end
  end

  describe '.find_or_initialize_non_project_specific_integration' do
    let!(:integration_1) { create(:jira_integration, project_id: nil, group_id: group.id) }
    let!(:integration_2) { create(:jira_integration) }

    it 'returns the right integration' do
      expect(Integration.find_or_initialize_non_project_specific_integration('jira', group_id: group))
        .to eq(integration_1)
    end

    it 'does not create a new integration' do
      expect { Integration.find_or_initialize_non_project_specific_integration('redmine', group_id: group) }
        .not_to change(Integration, :count)
    end
  end

  describe '.find_or_initialize_all_non_project_specific' do
    shared_examples 'integration instances' do
      it 'returns the available integration instances' do
        expect(Integration.find_or_initialize_all_non_project_specific(Integration.for_instance).map(&:to_param))
          .to match_array(Integration.available_integration_names(include_project_specific: false))
      end

      it 'does not create integration instances' do
        expect { Integration.find_or_initialize_all_non_project_specific(Integration.for_instance) }
          .not_to change(Integration, :count)
      end
    end

    it_behaves_like 'integration instances'

    context 'with all existing instances' do
      before do
        Integration.insert_all(
          Integration.available_integration_types(include_project_specific: false).map { |type| { instance: true, type: type } }
        )
      end

      it_behaves_like 'integration instances'

      context 'with a previous existing integration (MockCiService) and a new integration (Asana)' do
        before do
          Integration.insert({ type: 'MockCiService', instance: true })
          Integration.delete_by(type: 'AsanaService', instance: true)
        end

        it_behaves_like 'integration instances'
      end
    end

    context 'with a few existing instances' do
      before do
        create(:jira_integration, :instance)
      end

      it_behaves_like 'integration instances'
    end
  end

  describe '.build_from_integration' do
    context 'when integration is invalid' do
      let(:invalid_integration) do
        build(:prometheus_integration, :instance, active: true, properties: {})
          .tap { |integration| integration.save!(validate: false) }
      end

      it 'sets integration to inactive' do
        integration = described_class.build_from_integration(invalid_integration, project_id: project.id)

        expect(integration).to be_valid
        expect(integration.active).to be false
      end
    end

    context 'when integration is an instance-level integration' do
      let(:instance_integration) { create(:jira_integration, :instance) }

      it 'sets inherit_from_id from integration' do
        integration = described_class.build_from_integration(instance_integration, project_id: project.id)

        expect(integration.inherit_from_id).to eq(instance_integration.id)
      end
    end

    context 'when integration is a group-level integration' do
      let(:group_integration) { create(:jira_integration, :group, group: group) }

      it 'sets inherit_from_id from integration' do
        integration = described_class.build_from_integration(group_integration, project_id: project.id)

        expect(integration.inherit_from_id).to eq(group_integration.id)
      end
    end

    describe 'build issue tracker from an integration' do
      let(:url) { 'http://jira.example.com' }
      let(:api_url) { 'http://api-jira.example.com' }
      let(:username) { 'jira-username' }
      let(:password) { 'jira-password' }
      let(:data_params) do
        {
          url: url, api_url: api_url,
          username: username, password: password
        }
      end

      shared_examples 'integration creation from an integration' do
        it 'creates a correct integration for a project integration' do
          new_integration = described_class.build_from_integration(integration, project_id: project.id)

          expect(new_integration).to be_active
          expect(new_integration.url).to eq(url)
          expect(new_integration.api_url).to eq(api_url)
          expect(new_integration.username).to eq(username)
          expect(new_integration.password).to eq(password)
          expect(new_integration.instance).to eq(false)
          expect(new_integration.project).to eq(project)
          expect(new_integration.group).to eq(nil)
        end

        it 'creates a correct integration for a group integration' do
          new_integration = described_class.build_from_integration(integration, group_id: group.id)

          expect(new_integration).to be_active
          expect(new_integration.url).to eq(url)
          expect(new_integration.api_url).to eq(api_url)
          expect(new_integration.username).to eq(username)
          expect(new_integration.password).to eq(password)
          expect(new_integration.instance).to eq(false)
          expect(new_integration.project).to eq(nil)
          expect(new_integration.group).to eq(group)
        end
      end

      # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
      context 'when data is stored in properties' do
        let(:properties) { data_params }
        let!(:integration) do
          create(:jira_integration, :without_properties_callback, properties: properties.merge(additional: 'something'))
        end

        it_behaves_like 'integration creation from an integration'
      end

      context 'when data are stored in separated fields' do
        let(:integration) do
          create(:jira_integration, data_params.merge(properties: {}))
        end

        it_behaves_like 'integration creation from an integration'
      end

      context 'when data are stored in both properties and separated fields' do
        let(:properties) { data_params }
        let(:integration) do
          create(:jira_integration, :without_properties_callback, active: true, properties: properties).tap do |integration|
            create(:jira_tracker_data, data_params.merge(integration: integration))
          end
        end

        it_behaves_like 'integration creation from an integration'
      end
    end
  end

  describe '.default_integration' do
    context 'with an instance-level integration' do
      let_it_be(:instance_integration) { create(:jira_integration, :instance) }

      it 'returns the instance integration' do
        expect(described_class.default_integration('JiraService', project)).to eq(instance_integration)
      end

      it 'returns nil for nonexistent integration type' do
        expect(described_class.default_integration('HipchatService', project)).to eq(nil)
      end

      context 'with a group integration' do
        let_it_be(:group_integration) { create(:jira_integration, group_id: group.id, project_id: nil) }

        it 'returns the group integration for a project' do
          expect(described_class.default_integration('JiraService', project)).to eq(group_integration)
        end

        it 'returns the instance integration for a group' do
          expect(described_class.default_integration('JiraService', group)).to eq(instance_integration)
        end

        context 'with a subgroup' do
          let_it_be(:subgroup) { create(:group, parent: group) }

          let!(:project) { create(:project, group: subgroup) }

          it 'returns the closest group integration for a project' do
            expect(described_class.default_integration('JiraService', project)).to eq(group_integration)
          end

          it 'returns the closest group integration for a subgroup' do
            expect(described_class.default_integration('JiraService', subgroup)).to eq(group_integration)
          end

          context 'having a integration with custom settings' do
            let!(:subgroup_integration) { create(:jira_integration, group_id: subgroup.id, project_id: nil) }

            it 'returns the closest group integration for a project' do
              expect(described_class.default_integration('JiraService', project)).to eq(subgroup_integration)
            end
          end

          context 'having a integration inheriting settings' do
            let!(:subgroup_integration) { create(:jira_integration, group_id: subgroup.id, project_id: nil, inherit_from_id: group_integration.id) }

            it 'returns the closest group integration which does not inherit from its parent for a project' do
              expect(described_class.default_integration('JiraService', project)).to eq(group_integration)
            end
          end
        end
      end
    end
  end

  describe '.create_from_active_default_integrations' do
    context 'with an active instance-level integration' do
      let!(:instance_integration) { create(:prometheus_integration, :instance, api_url: 'https://prometheus.instance.com/') }

      it 'creates an integration from the instance-level integration' do
        described_class.create_from_active_default_integrations(project, :project_id)

        expect(project.reload.integrations.size).to eq(1)
        expect(project.reload.integrations.first.api_url).to eq(instance_integration.api_url)
        expect(project.reload.integrations.first.inherit_from_id).to eq(instance_integration.id)
      end

      context 'passing a group' do
        it 'creates an integration from the instance-level integration' do
          described_class.create_from_active_default_integrations(group, :group_id)

          expect(group.reload.integrations.size).to eq(1)
          expect(group.reload.integrations.first.api_url).to eq(instance_integration.api_url)
          expect(group.reload.integrations.first.inherit_from_id).to eq(instance_integration.id)
        end
      end

      context 'with an active group-level integration' do
        let!(:group_integration) { create(:prometheus_integration, :group, group: group, api_url: 'https://prometheus.group.com/') }

        it 'creates an integration from the group-level integration' do
          described_class.create_from_active_default_integrations(project, :project_id)

          expect(project.reload.integrations.size).to eq(1)
          expect(project.reload.integrations.first.api_url).to eq(group_integration.api_url)
          expect(project.reload.integrations.first.inherit_from_id).to eq(group_integration.id)
        end

        context 'passing a group' do
          let!(:subgroup) { create(:group, parent: group) }

          it 'creates an integration from the group-level integration' do
            described_class.create_from_active_default_integrations(subgroup, :group_id)

            expect(subgroup.reload.integrations.size).to eq(1)
            expect(subgroup.reload.integrations.first.api_url).to eq(group_integration.api_url)
            expect(subgroup.reload.integrations.first.inherit_from_id).to eq(group_integration.id)
          end
        end

        context 'with an active subgroup' do
          let!(:subgroup_integration) { create(:prometheus_integration, :group, group: subgroup, api_url: 'https://prometheus.subgroup.com/') }
          let!(:subgroup) { create(:group, parent: group) }
          let(:project) { create(:project, group: subgroup) }

          it 'creates an integration from the subgroup-level integration' do
            described_class.create_from_active_default_integrations(project, :project_id)

            expect(project.reload.integrations.size).to eq(1)
            expect(project.reload.integrations.first.api_url).to eq(subgroup_integration.api_url)
            expect(project.reload.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
          end

          context 'passing a group' do
            let!(:sub_subgroup) { create(:group, parent: subgroup) }

            context 'traversal queries' do
              shared_examples 'correct ancestor order' do
                it 'creates an integration from the subgroup-level integration' do
                  described_class.create_from_active_default_integrations(sub_subgroup, :group_id)

                  sub_subgroup.reload

                  expect(sub_subgroup.integrations.size).to eq(1)
                  expect(sub_subgroup.integrations.first.api_url).to eq(subgroup_integration.api_url)
                  expect(sub_subgroup.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
                end

                context 'having an integration inheriting settings' do
                  let!(:subgroup_integration) { create(:prometheus_integration, :group, group: subgroup, inherit_from_id: group_integration.id, api_url: 'https://prometheus.subgroup.com/') }

                  it 'creates an integration from the group-level integration' do
                    described_class.create_from_active_default_integrations(sub_subgroup, :group_id)

                    sub_subgroup.reload

                    expect(sub_subgroup.integrations.size).to eq(1)
                    expect(sub_subgroup.integrations.first.api_url).to eq(group_integration.api_url)
                    expect(sub_subgroup.integrations.first.inherit_from_id).to eq(group_integration.id)
                  end
                end
              end

              context 'recursive' do
                before do
                  stub_feature_flags(use_traversal_ids: false)
                end

                include_examples 'correct ancestor order'
              end

              context 'linear' do
                before do
                  stub_feature_flags(use_traversal_ids: true)

                  sub_subgroup.reload # make sure traversal_ids are reloaded
                end

                include_examples 'correct ancestor order'
              end
            end
          end
        end
      end
    end
  end

  describe '.inherited_descendants_from_self_or_ancestors_from' do
    let_it_be(:subgroup1) { create(:group, parent: group) }
    let_it_be(:subgroup2) { create(:group, parent: group) }
    let_it_be(:project1) { create(:project, group: subgroup1) }
    let_it_be(:project2) { create(:project, group: subgroup2) }
    let_it_be(:group_integration) { create(:prometheus_integration, :group, group: group) }
    let_it_be(:subgroup_integration1) { create(:prometheus_integration, :group, group: subgroup1, inherit_from_id: group_integration.id) }
    let_it_be(:subgroup_integration2) { create(:prometheus_integration, :group, group: subgroup2) }
    let_it_be(:project_integration1) { create(:prometheus_integration, project: project1, inherit_from_id: group_integration.id) }
    let_it_be(:project_integration2) { create(:prometheus_integration, project: project2, inherit_from_id: subgroup_integration2.id) }

    it 'returns the groups and projects inheriting from integration ancestors', :aggregate_failures do
      expect(described_class.inherited_descendants_from_self_or_ancestors_from(group_integration)).to eq([subgroup_integration1, project_integration1])
      expect(described_class.inherited_descendants_from_self_or_ancestors_from(subgroup_integration2)).to eq([project_integration2])
    end
  end

  describe '.integration_name_to_model' do
    it 'returns the model for the given integration name' do
      expect(described_class.integration_name_to_model('asana')).to eq(Integrations::Asana)
    end

    it 'raises an error if integration name is invalid' do
      expect { described_class.integration_name_to_model('foo') }.to raise_exception(NameError, /uninitialized constant FooService/)
    end
  end

  describe "{property}_changed?" do
    let(:integration) do
      Integrations::Bamboo.create!(
        project: project,
        properties: {
          bamboo_url: 'http://gitlab.com',
          username: 'mic',
          password: "password"
        }
      )
    end

    it "returns false when the property has not been assigned a new value" do
      integration.username = "key_changed"
      expect(integration.bamboo_url_changed?).to be_falsy
    end

    it "returns true when the property has been assigned a different value" do
      integration.bamboo_url = "http://example.com"
      expect(integration.bamboo_url_changed?).to be_truthy
    end

    it "returns true when the property has been assigned a different value twice" do
      integration.bamboo_url = "http://example.com"
      integration.bamboo_url = "http://example.com"
      expect(integration.bamboo_url_changed?).to be_truthy
    end

    it "returns false when the property has been re-assigned the same value" do
      integration.bamboo_url = 'http://gitlab.com'
      expect(integration.bamboo_url_changed?).to be_falsy
    end

    it "returns false when the property has been assigned a new value then saved" do
      integration.bamboo_url = 'http://example.com'
      integration.save!
      expect(integration.bamboo_url_changed?).to be_falsy
    end
  end

  describe "{property}_touched?" do
    let(:integration) do
      Integrations::Bamboo.create!(
        project: project,
        properties: {
          bamboo_url: 'http://gitlab.com',
          username: 'mic',
          password: "password"
        }
      )
    end

    it "returns false when the property has not been assigned a new value" do
      integration.username = "key_changed"
      expect(integration.bamboo_url_touched?).to be_falsy
    end

    it "returns true when the property has been assigned a different value" do
      integration.bamboo_url = "http://example.com"
      expect(integration.bamboo_url_touched?).to be_truthy
    end

    it "returns true when the property has been assigned a different value twice" do
      integration.bamboo_url = "http://example.com"
      integration.bamboo_url = "http://example.com"
      expect(integration.bamboo_url_touched?).to be_truthy
    end

    it "returns true when the property has been re-assigned the same value" do
      integration.bamboo_url = 'http://gitlab.com'
      expect(integration.bamboo_url_touched?).to be_truthy
    end

    it "returns false when the property has been assigned a new value then saved" do
      integration.bamboo_url = 'http://example.com'
      integration.save!
      expect(integration.bamboo_url_changed?).to be_falsy
    end
  end

  describe "{property}_was" do
    let(:integration) do
      Integrations::Bamboo.create!(
        project: project,
        properties: {
          bamboo_url: 'http://gitlab.com',
          username: 'mic',
          password: "password"
        }
      )
    end

    it "returns nil when the property has not been assigned a new value" do
      integration.username = "key_changed"
      expect(integration.bamboo_url_was).to be_nil
    end

    it "returns the previous value when the property has been assigned a different value" do
      integration.bamboo_url = "http://example.com"
      expect(integration.bamboo_url_was).to eq('http://gitlab.com')
    end

    it "returns initial value when the property has been re-assigned the same value" do
      integration.bamboo_url = 'http://gitlab.com'
      expect(integration.bamboo_url_was).to eq('http://gitlab.com')
    end

    it "returns initial value when the property has been assigned multiple values" do
      integration.bamboo_url = "http://example.com"
      integration.bamboo_url = "http://example.org"
      expect(integration.bamboo_url_was).to eq('http://gitlab.com')
    end

    it "returns nil when the property has been assigned a new value then saved" do
      integration.bamboo_url = 'http://example.com'
      integration.save!
      expect(integration.bamboo_url_was).to be_nil
    end
  end

  describe 'initialize integration with no properties' do
    let(:integration) do
      Integrations::Bugzilla.create!(
        project: project,
        project_url: 'http://gitlab.example.com'
      )
    end

    it 'does not raise error' do
      expect { integration }.not_to raise_error
    end

    it 'sets data correctly' do
      expect(integration.data_fields.project_url).to eq('http://gitlab.example.com')
    end
  end

  describe '#api_field_names' do
    let(:fake_integration) do
      Class.new(Integration) do
        def fields
          [
            { name: 'token' },
            { name: 'api_token' },
            { name: 'token_api' },
            { name: 'safe_token' },
            { name: 'key' },
            { name: 'api_key' },
            { name: 'password' },
            { name: 'password_field' },
            { name: 'some_safe_field' },
            { name: 'safe_field' }
          ].shuffle
        end
      end
    end

    it 'filters out sensitive fields' do
      expect(fake_integration.new).to have_attributes(api_field_names: match_array(%w[some_safe_field safe_field]))
    end
  end

  context 'logging' do
    let(:integration) { build(:integration, project: project) }
    let(:test_message) { "test message" }
    let(:arguments) do
      {
        service_class: integration.class.name,
        project_path: project.full_path,
        project_id: project.id,
        message: test_message,
        additional_argument: 'some argument'
      }
    end

    it 'logs info messages using json logger' do
      expect(Gitlab::JsonLogger).to receive(:info).with(arguments)

      integration.log_info(test_message, additional_argument: 'some argument')
    end

    it 'logs error messages using json logger' do
      expect(Gitlab::JsonLogger).to receive(:error).with(arguments)

      integration.log_error(test_message, additional_argument: 'some argument')
    end

    context 'when project is nil' do
      let(:project) { nil }
      let(:arguments) do
        {
          service_class: integration.class.name,
          project_path: nil,
          project_id: nil,
          message: test_message,
          additional_argument: 'some argument'
        }
      end

      it 'logs info messages using json logger' do
        expect(Gitlab::JsonLogger).to receive(:info).with(arguments)

        integration.log_info(test_message, additional_argument: 'some argument')
      end
    end
  end

  describe '.available_integration_names' do
    it 'calls the right methods' do
      expect(described_class).to receive(:integration_names).and_call_original
      expect(described_class).to receive(:dev_integration_names).and_call_original
      expect(described_class).to receive(:project_specific_integration_names).and_call_original

      described_class.available_integration_names
    end

    it 'does not call project_specific_integration_names with include_project_specific false' do
      expect(described_class).to receive(:integration_names).and_call_original
      expect(described_class).to receive(:dev_integration_names).and_call_original
      expect(described_class).not_to receive(:project_specific_integration_names)

      described_class.available_integration_names(include_project_specific: false)
    end

    it 'does not call dev_integration_names with include_dev false' do
      expect(described_class).to receive(:integration_names).and_call_original
      expect(described_class).not_to receive(:dev_integration_names)
      expect(described_class).to receive(:project_specific_integration_names).and_call_original

      described_class.available_integration_names(include_dev: false)
    end

    it { expect(described_class.available_integration_names).to include('jenkins') }
  end

  describe '.project_specific_integration_names' do
    it do
      expect(described_class.project_specific_integration_names)
        .to include(*described_class::PROJECT_SPECIFIC_INTEGRATION_NAMES)
    end
  end

  describe '#password_fields' do
    it 'returns all fields with type `password`' do
      allow(subject).to receive(:fields).and_return([
        { name: 'password', type: 'password' },
        { name: 'secret', type: 'password' },
        { name: 'public', type: 'text' }
      ])

      expect(subject.password_fields).to match_array(%w[password secret])
    end

    it 'returns an empty array if no password fields exist' do
      expect(subject.password_fields).to eq([])
    end
  end
end
