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
    it { is_expected.to have_one(:open_project_tracker_data).autosave(true).inverse_of(:integration).with_foreign_key(:service_id).class_name('Integrations::OpenProjectTrackerData') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to validate_exclusion_of(:type).in_array(described_class::BASE_CLASSES) }

    where(:project_id, :group_id, :template, :instance, :valid) do
      1    | nil  | false  | false  | true
      nil  | 1    | false  | false  | true
      nil  | nil  | true   | false  | true
      nil  | nil  | false  | true   | true
      nil  | nil  | false  | false  | false
      nil  | nil  | true   | true   | false
      1    | 1    | false  | false  | false
      1    | nil  | true   | false  | false
      1    | nil  | false  | true   | false
      nil  | 1    | true   | false  | false
      nil  | 1    | false  | true   | false
    end

    with_them do
      it 'validates the service' do
        expect(build(:service, project_id: project_id, group_id: group_id, template: template, instance: instance).valid?).to eq(valid)
      end
    end

    context 'with existing services' do
      before_all do
        create(:service, :template)
        create(:service, :instance)
        create(:service, project: project)
        create(:service, group: group, project: nil)
      end

      it 'allows only one service template per type' do
        expect(build(:service, :template)).to be_invalid
      end

      it 'allows only one instance service per type' do
        expect(build(:service, :instance)).to be_invalid
      end

      it 'allows only one project service per type' do
        expect(build(:service, project: project)).to be_invalid
      end

      it 'allows only one group service per type' do
        expect(build(:service, group: group, project: nil)).to be_invalid
      end
    end
  end

  describe 'Scopes' do
    describe '.by_type' do
      let!(:service1) { create(:jira_integration) }
      let!(:service2) { create(:jira_integration) }
      let!(:service3) { create(:redmine_integration) }

      subject { described_class.by_type(type) }

      context 'when type is "JiraService"' do
        let(:type) { 'JiraService' }

        it { is_expected.to match_array([service1, service2]) }
      end

      context 'when type is "RedmineService"' do
        let(:type) { 'RedmineService' }

        it { is_expected.to match_array([service3]) }
      end
    end

    describe '.for_group' do
      let!(:service1) { create(:jira_integration, project_id: nil, group_id: group.id) }
      let!(:service2) { create(:jira_integration) }

      it 'returns the right group service' do
        expect(described_class.for_group(group)).to match_array([service1])
      end
    end

    describe '.confidential_note_hooks' do
      it 'includes services where confidential_note_events is true' do
        create(:service, active: true, confidential_note_events: true)

        expect(described_class.confidential_note_hooks.count).to eq 1
      end

      it 'excludes services where confidential_note_events is false' do
        create(:service, active: true, confidential_note_events: false)

        expect(described_class.confidential_note_hooks.count).to eq 0
      end
    end

    describe '.alert_hooks' do
      it 'includes services where alert_events is true' do
        create(:service, active: true, alert_events: true)

        expect(described_class.alert_hooks.count).to eq 1
      end

      it 'excludes services where alert_events is false' do
        create(:service, active: true, alert_events: false)

        expect(described_class.alert_hooks.count).to eq 0
      end
    end
  end

  describe '#operating?' do
    it 'is false when the service is not active' do
      expect(build(:service).operating?).to eq(false)
    end

    it 'is false when the service is not persisted' do
      expect(build(:service, active: true).operating?).to eq(false)
    end

    it 'is true when the service is active and persisted' do
      expect(create(:service, active: true).operating?).to eq(true)
    end
  end

  describe '#testable?' do
    context 'when integration is project-level' do
      subject { build(:service, project: project) }

      it { is_expected.to be_testable }
    end

    context 'when integration is not project-level' do
      subject { build(:service, project: nil) }

      it { is_expected.not_to be_testable }
    end
  end

  describe '#test' do
    let(:integration) { build(:service, project: project) }
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
    it 'is true when service has a project' do
      expect(build(:service, project: project)).to be_project_level
    end

    it 'is false when service has no project' do
      expect(build(:service, project: nil)).not_to be_project_level
    end
  end

  describe '#group_level?' do
    it 'is true when service has a group' do
      expect(build(:service, group: group)).to be_group_level
    end

    it 'is false when service has no group' do
      expect(build(:service, group: nil)).not_to be_group_level
    end
  end

  describe '#instance_level?' do
    it 'is true when service has instance-level integration' do
      expect(build(:service, :instance)).to be_instance_level
    end

    it 'is false when service does not have instance-level integration' do
      expect(build(:service, instance: false)).not_to be_instance_level
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
    shared_examples 'service instances' do
      it 'returns the available service instances' do
        expect(Integration.find_or_initialize_all_non_project_specific(Integration.for_instance).map(&:to_param))
          .to match_array(Integration.available_integration_names(include_project_specific: false))
      end

      it 'does not create service instances' do
        expect { Integration.find_or_initialize_all_non_project_specific(Integration.for_instance) }
          .not_to change(Integration, :count)
      end
    end

    it_behaves_like 'service instances'

    context 'with all existing instances' do
      before do
        Integration.insert_all(
          Integration.available_integration_types(include_project_specific: false).map { |type| { instance: true, type: type } }
        )
      end

      it_behaves_like 'service instances'

      context 'with a previous existing service (MockCiService) and a new service (Asana)' do
        before do
          Integration.insert({ type: 'MockCiService', instance: true })
          Integration.delete_by(type: 'AsanaService', instance: true)
        end

        it_behaves_like 'service instances'
      end
    end

    context 'with a few existing instances' do
      before do
        create(:jira_integration, :instance)
      end

      it_behaves_like 'service instances'
    end
  end

  describe 'template' do
    shared_examples 'retrieves service templates' do
      it 'returns the available service templates' do
        expect(Integration.find_or_create_templates.pluck(:type)).to match_array(Integration.available_integration_types(include_project_specific: false))
      end
    end

    describe '.find_or_create_templates' do
      it 'creates service templates' do
        total = Integration.available_integration_names(include_project_specific: false).size

        expect { Integration.find_or_create_templates }.to change(Integration, :count).from(0).to(total)
      end

      it_behaves_like 'retrieves service templates'

      context 'with all existing templates' do
        before do
          Integration.insert_all(
            Integration.available_integration_types(include_project_specific: false).map { |type| { template: true, type: type } }
          )
        end

        it 'does not create service templates' do
          expect { Integration.find_or_create_templates }.not_to change { Integration.count }
        end

        it_behaves_like 'retrieves service templates'

        context 'with a previous existing service (Previous) and a new service (Asana)' do
          before do
            Integration.insert({ type: 'PreviousService', template: true })
            Integration.delete_by(type: 'AsanaService', template: true)
          end

          it_behaves_like 'retrieves service templates'
        end
      end

      context 'with a few existing templates' do
        before do
          create(:jira_integration, :template)
        end

        it 'creates the rest of the service templates' do
          total = Integration.available_integration_names(include_project_specific: false).size

          expect { Integration.find_or_create_templates }.to change(Integration, :count).from(1).to(total)
        end

        it_behaves_like 'retrieves service templates'
      end
    end

    describe '.build_from_integration' do
      context 'when integration is invalid' do
        let(:template_integration) do
          build(:prometheus_integration, :template, active: true, properties: {})
            .tap { |integration| integration.save!(validate: false) }
        end

        it 'sets integration to inactive' do
          integration = described_class.build_from_integration(template_integration, project_id: project.id)

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
        let(:group_integration) { create(:jira_integration, group: group, project: nil) }

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

        shared_examples 'service creation from an integration' do
          it 'creates a correct service for a project integration' do
            service = described_class.build_from_integration(integration, project_id: project.id)

            expect(service).to be_active
            expect(service.url).to eq(url)
            expect(service.api_url).to eq(api_url)
            expect(service.username).to eq(username)
            expect(service.password).to eq(password)
            expect(service.template).to eq(false)
            expect(service.instance).to eq(false)
            expect(service.project).to eq(project)
            expect(service.group).to eq(nil)
          end

          it 'creates a correct service for a group integration' do
            service = described_class.build_from_integration(integration, group_id: group.id)

            expect(service).to be_active
            expect(service.url).to eq(url)
            expect(service.api_url).to eq(api_url)
            expect(service.username).to eq(username)
            expect(service.password).to eq(password)
            expect(service.template).to eq(false)
            expect(service.instance).to eq(false)
            expect(service.project).to eq(nil)
            expect(service.group).to eq(group)
          end
        end

        # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
        context 'when data are stored in properties' do
          let(:properties) { data_params }
          let!(:integration) do
            create(:jira_integration, :without_properties_callback, template: true, properties: properties.merge(additional: 'something'))
          end

          it_behaves_like 'service creation from an integration'
        end

        context 'when data are stored in separated fields' do
          let(:integration) do
            create(:jira_integration, :template, data_params.merge(properties: {}))
          end

          it_behaves_like 'service creation from an integration'
        end

        context 'when data are stored in both properties and separated fields' do
          let(:properties) { data_params }
          let(:integration) do
            create(:jira_integration, :without_properties_callback, active: true, template: true, properties: properties).tap do |integration|
              create(:jira_tracker_data, data_params.merge(integration: integration))
            end
          end

          it_behaves_like 'service creation from an integration'
        end
      end
    end

    describe "for pushover service" do
      let!(:service_template) do
        Integrations::Pushover.create!(
          template: true,
          properties: {
            device: 'MyDevice',
            sound: 'mic',
            priority: 4,
            api_key: '123456789'
          })
      end

      describe 'is prefilled for projects pushover service' do
        it "has all fields prefilled" do
          integration = project.find_or_initialize_integration('pushover')

          expect(integration).to have_attributes(
            template: eq(false),
            device: eq('MyDevice'),
            sound: eq('mic'),
            priority: eq(4),
            api_key: eq('123456789')
          )
        end
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
    context 'with an active integration template' do
      let_it_be(:template_integration) { create(:prometheus_integration, :template, api_url: 'https://prometheus.template.com/') }

      it 'creates an integration from the template' do
        described_class.create_from_active_default_integrations(project, :project_id, with_templates: true)

        expect(project.reload.integrations.size).to eq(1)
        expect(project.reload.integrations.first.api_url).to eq(template_integration.api_url)
        expect(project.reload.integrations.first.inherit_from_id).to be_nil
      end

      context 'with an active instance-level integration' do
        let!(:instance_integration) { create(:prometheus_integration, :instance, api_url: 'https://prometheus.instance.com/') }

        it 'creates an integration from the instance-level integration' do
          described_class.create_from_active_default_integrations(project, :project_id, with_templates: true)

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
          let!(:group_integration) { create(:prometheus_integration, group: group, project: nil, api_url: 'https://prometheus.group.com/') }

          it 'creates an integration from the group-level integration' do
            described_class.create_from_active_default_integrations(project, :project_id, with_templates: true)

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
            let!(:subgroup_integration) { create(:prometheus_integration, group: subgroup, project: nil, api_url: 'https://prometheus.subgroup.com/') }
            let!(:subgroup) { create(:group, parent: group) }
            let(:project) { create(:project, group: subgroup) }

            it 'creates an integration from the subgroup-level integration' do
              described_class.create_from_active_default_integrations(project, :project_id, with_templates: true)

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
                    let!(:subgroup_integration) { create(:prometheus_integration, group: subgroup, project: nil, inherit_from_id: group_integration.id, api_url: 'https://prometheus.subgroup.com/') }

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
  end

  describe '.inherited_descendants_from_self_or_ancestors_from' do
    let_it_be(:subgroup1) { create(:group, parent: group) }
    let_it_be(:subgroup2) { create(:group, parent: group) }
    let_it_be(:project1) { create(:project, group: subgroup1) }
    let_it_be(:project2) { create(:project, group: subgroup2) }
    let_it_be(:group_integration) { create(:prometheus_integration, group: group, project: nil) }
    let_it_be(:subgroup_integration1) { create(:prometheus_integration, group: subgroup1, project: nil, inherit_from_id: group_integration.id) }
    let_it_be(:subgroup_integration2) { create(:prometheus_integration, group: subgroup2, project: nil) }
    let_it_be(:project_integration1) { create(:prometheus_integration, group: nil, project: project1, inherit_from_id: group_integration.id) }
    let_it_be(:project_integration2) { create(:prometheus_integration, group: nil, project: project2, inherit_from_id: subgroup_integration2.id) }

    it 'returns the groups and projects inheriting from integration ancestors', :aggregate_failures do
      expect(described_class.inherited_descendants_from_self_or_ancestors_from(group_integration)).to eq([subgroup_integration1, project_integration1])
      expect(described_class.inherited_descendants_from_self_or_ancestors_from(subgroup_integration2)).to eq([project_integration2])
    end
  end

  describe '.integration_name_to_model' do
    it 'returns the model for the given service name' do
      expect(described_class.integration_name_to_model('asana')).to eq(Integrations::Asana)
    end

    it 'raises an error if service name is invalid' do
      expect { described_class.integration_name_to_model('foo') }.to raise_exception(NameError, /uninitialized constant FooService/)
    end
  end

  describe "{property}_changed?" do
    let(:service) do
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
      service.username = "key_changed"
      expect(service.bamboo_url_changed?).to be_falsy
    end

    it "returns true when the property has been assigned a different value" do
      service.bamboo_url = "http://example.com"
      expect(service.bamboo_url_changed?).to be_truthy
    end

    it "returns true when the property has been assigned a different value twice" do
      service.bamboo_url = "http://example.com"
      service.bamboo_url = "http://example.com"
      expect(service.bamboo_url_changed?).to be_truthy
    end

    it "returns false when the property has been re-assigned the same value" do
      service.bamboo_url = 'http://gitlab.com'
      expect(service.bamboo_url_changed?).to be_falsy
    end

    it "returns false when the property has been assigned a new value then saved" do
      service.bamboo_url = 'http://example.com'
      service.save!
      expect(service.bamboo_url_changed?).to be_falsy
    end
  end

  describe "{property}_touched?" do
    let(:service) do
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
      service.username = "key_changed"
      expect(service.bamboo_url_touched?).to be_falsy
    end

    it "returns true when the property has been assigned a different value" do
      service.bamboo_url = "http://example.com"
      expect(service.bamboo_url_touched?).to be_truthy
    end

    it "returns true when the property has been assigned a different value twice" do
      service.bamboo_url = "http://example.com"
      service.bamboo_url = "http://example.com"
      expect(service.bamboo_url_touched?).to be_truthy
    end

    it "returns true when the property has been re-assigned the same value" do
      service.bamboo_url = 'http://gitlab.com'
      expect(service.bamboo_url_touched?).to be_truthy
    end

    it "returns false when the property has been assigned a new value then saved" do
      service.bamboo_url = 'http://example.com'
      service.save!
      expect(service.bamboo_url_changed?).to be_falsy
    end
  end

  describe "{property}_was" do
    let(:service) do
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
      service.username = "key_changed"
      expect(service.bamboo_url_was).to be_nil
    end

    it "returns the previous value when the property has been assigned a different value" do
      service.bamboo_url = "http://example.com"
      expect(service.bamboo_url_was).to eq('http://gitlab.com')
    end

    it "returns initial value when the property has been re-assigned the same value" do
      service.bamboo_url = 'http://gitlab.com'
      expect(service.bamboo_url_was).to eq('http://gitlab.com')
    end

    it "returns initial value when the property has been assigned multiple values" do
      service.bamboo_url = "http://example.com"
      service.bamboo_url = "http://example2.com"
      expect(service.bamboo_url_was).to eq('http://gitlab.com')
    end

    it "returns nil when the property has been assigned a new value then saved" do
      service.bamboo_url = 'http://example.com'
      service.save!
      expect(service.bamboo_url_was).to be_nil
    end
  end

  describe 'initialize service with no properties' do
    let(:service) do
      Integrations::Bugzilla.create!(
        project: project,
        project_url: 'http://gitlab.example.com'
      )
    end

    it 'does not raise error' do
      expect { service }.not_to raise_error
    end

    it 'sets data correctly' do
      expect(service.data_fields.project_url).to eq('http://gitlab.example.com')
    end
  end

  describe '#api_field_names' do
    let(:fake_service) do
      Class.new(Integration) do
        def fields
          [
            { name: 'token' },
            { name: 'api_token' },
            { name: 'key' },
            { name: 'api_key' },
            { name: 'password' },
            { name: 'password_field' },
            { name: 'safe_field' }
          ]
        end
      end
    end

    let(:service) do
      fake_service.new(properties: [
        { token: 'token-value' },
        { api_token: 'api_token-value' },
        { key: 'key-value' },
        { api_key: 'api_key-value' },
        { password: 'password-value' },
        { password_field: 'password_field-value' },
        { safe_field: 'safe_field-value' }
      ])
    end

    it 'filters out sensitive fields' do
      expect(service.api_field_names).to eq(['safe_field'])
    end
  end

  context 'logging' do
    let(:service) { build(:service, project: project) }
    let(:test_message) { "test message" }
    let(:arguments) do
      {
        service_class: service.class.name,
        project_path: project.full_path,
        project_id: project.id,
        message: test_message,
        additional_argument: 'some argument'
      }
    end

    it 'logs info messages using json logger' do
      expect(Gitlab::JsonLogger).to receive(:info).with(arguments)

      service.log_info(test_message, additional_argument: 'some argument')
    end

    it 'logs error messages using json logger' do
      expect(Gitlab::JsonLogger).to receive(:error).with(arguments)

      service.log_error(test_message, additional_argument: 'some argument')
    end

    context 'when project is nil' do
      let(:project) { nil }
      let(:arguments) do
        {
          service_class: service.class.name,
          project_path: nil,
          project_id: nil,
          message: test_message,
          additional_argument: 'some argument'
        }
      end

      it 'logs info messages using json logger' do
        expect(Gitlab::JsonLogger).to receive(:info).with(arguments)

        service.log_info(test_message, additional_argument: 'some argument')
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
end
