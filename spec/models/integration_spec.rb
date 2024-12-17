# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integration, feature_category: :integrations do
  using RSpec::Parameterized::TableSyntax

  subject(:integration) { build(:integration) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe "associations" do
    it { is_expected.to belong_to(:project).inverse_of(:integrations) }
    it { is_expected.to belong_to(:group).inverse_of(:integrations) }

    it do
      is_expected.to have_one(:issue_tracker_data)
        .autosave(true)
        .inverse_of(:integration)
        .with_foreign_key(:integration_id)
        .class_name('Integrations::IssueTrackerData')
    end

    it do
      is_expected.to have_one(:jira_tracker_data)
        .autosave(true)
        .inverse_of(:integration)
        .with_foreign_key(:integration_id)
        .class_name('Integrations::JiraTrackerData')
    end
  end

  describe 'default values' do
    it { is_expected.to be_alert_events }
    it { is_expected.to be_commit_events }
    it { is_expected.to be_confidential_issues_events }
    it { is_expected.to be_confidential_note_events }
    it { is_expected.to be_issues_events }
    it { is_expected.to be_job_events }
    it { is_expected.to be_merge_requests_events }
    it { is_expected.to be_note_events }
    it { is_expected.to be_pipeline_events }
    it { is_expected.to be_push_events }
    it { is_expected.to be_tag_push_events }
    it { is_expected.to be_wiki_page_events }
    it { is_expected.not_to be_active }
    it { is_expected.not_to be_incident_events }
    it { expect(integration.category).to eq(:common) }
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
        expect(build(:integration, :instance)).not_to be_valid
      end

      it 'allows only one project integration per type' do
        expect(build(:integration, project: project)).not_to be_valid
      end

      it 'allows only one group integration per type' do
        expect(build(:integration, group: group, project: nil)).not_to be_valid
      end
    end
  end

  describe 'scopes' do
    describe '.third_party_wikis' do
      before do
        create(:jira_integration, project: project)
        create(:redmine_integration, project: project)
      end

      let_it_be(:confluence) { create(:confluence_integration, project: project) }

      it 'returns the right group integration' do
        expect(described_class.third_party_wikis).to contain_exactly(confluence)
      end
    end

    describe '.with_default_settings' do
      it 'returns the correct integrations' do
        instance_integration = create(:integration, :instance)
        inheriting_integration = create(:integration, inherit_from_id: instance_integration.id)

        expect(described_class.with_default_settings).to contain_exactly(inheriting_integration)
      end
    end

    describe '.with_custom_settings' do
      it 'returns the correct integrations' do
        instance_integration = create(:integration, :instance)
        create(:integration, inherit_from_id: instance_integration.id)

        expect(described_class.with_custom_settings).to contain_exactly(instance_integration)
      end
    end

    describe '.by_type' do
      let_it_be(:jira_project_integration) { create(:jira_integration, project: project) }
      let_it_be(:jira_integration) { create(:jira_integration) }
      let_it_be(:redmine_integration) { create(:redmine_integration) }

      subject { described_class.by_type(type) }

      context 'when type is "Integrations::JiraService"' do
        let(:type) { 'Integrations::Jira' }

        it { is_expected.to contain_exactly(jira_project_integration, jira_integration) }
      end

      context 'when type is "Integrations::Redmine"' do
        let(:type) { 'Integrations::Redmine' }

        it { is_expected.to contain_exactly(redmine_integration) }
      end
    end

    describe '.for_group' do
      let!(:jira_group_integration) { create(:jira_integration, project_id: nil, group_id: group.id) }
      let!(:jira_project_integration) { create(:jira_integration, project: project) }

      it 'returns the right group integration' do
        expect(described_class.for_group(group)).to contain_exactly(jira_group_integration)
      end

      context 'when there is an instance specific integration' do
        let!(:beyond_identity_integration) { create(:beyond_identity_integration, instance: false, group: group) }

        it 'includes the instance specific integration' do
          expect(described_class.for_group(group)).to include(jira_group_integration, beyond_identity_integration)
        end
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
    include_examples 'hook scope', 'incident'
  end

  describe '.title' do
    it 'raises an error' do
      expect { described_class.title }.to raise_error(NotImplementedError)
    end
  end

  describe '.description' do
    it 'raises an error' do
      expect { described_class.description }.to raise_error(NotImplementedError)
    end
  end

  describe '.attribution_notice' do
    it { expect(described_class.attribution_notice).to be_nil }
  end

  describe '#operating?' do
    it 'is false when the integration is not active' do
      expect(build(:integration).operating?).to be(false)
    end

    it 'is false when the integration is not persisted' do
      expect(build(:integration, active: true).operating?).to be(false)
    end

    it 'is true when the integration is active and persisted' do
      expect(create(:integration, active: true).operating?).to be(true)
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

  describe '#chat?' do
    it 'is true when integration is chat integration' do
      expect(build(:mattermost_integration).chat?).to be(true)
    end

    it 'is false when integration is not chat integration' do
      expect(build(:integration).chat?).to be(false)
    end
  end

  describe '#ci?' do
    it 'is true when integration is a CI integration' do
      expect(build(:jenkins_integration).ci?).to be(true)
    end

    it 'is false when integration is not a ci integration' do
      expect(build(:integration).ci?).to be(false)
    end
  end

  describe '#deactivate!' do
    it 'sets active to false' do
      integration = build(:integration, active: true)

      integration.deactivate!

      expect(integration.active).to eq(false)
    end
  end

  describe '#activate!' do
    it 'sets active to true' do
      integration = build(:integration, active: false)

      integration.activate!

      expect(integration.active).to eq(true)
    end
  end

  describe '#toggle!' do
    context 'when active' do
      it 'deactivates the integration' do
        integration = build(:integration, active: true)

        integration.toggle!

        expect(integration).not_to be_active
      end
    end

    context 'when not active' do
      it 'activates the integration' do
        integration = build(:integration, active: false)

        integration.toggle!

        expect(integration).to be_active
      end
    end
  end

  describe '.find_or_initialize_non_project_specific_integration' do
    let_it_be(:jira_group_integration) { create(:jira_integration, project_id: nil, group_id: group.id) }
    let_it_be(:jira_project_integration) { create(:jira_integration, project: project) }

    it 'returns the right integration' do
      expect(described_class.find_or_initialize_non_project_specific_integration('jira', group_id: group))
        .to eq(jira_group_integration)
    end

    it 'does not create a new integration' do
      expect { described_class.find_or_initialize_non_project_specific_integration('redmine', group_id: group) }
        .not_to change { described_class.count }
    end
  end

  describe '.find_or_initialize_all_non_project_specific' do
    shared_examples 'integration instances' do
      [false, true].each do |include_instance_specific|
        context "with include_instance_specific value equal to #{include_instance_specific}" do
          it 'returns the available integration instances' do
            integrations = described_class.find_or_initialize_all_non_project_specific(
              described_class.for_instance, include_instance_specific: include_instance_specific
            ).map(&:to_param)

            expect(integrations).to match_array(
              described_class.available_integration_names(
                include_project_specific: false,
                include_instance_specific: include_instance_specific)
            )
          end

          it 'does not create integration instances' do
            expect do
              described_class.find_or_initialize_all_non_project_specific(
                described_class.for_instance,
                include_instance_specific: include_instance_specific
              )
            end.not_to change { described_class.count }
          end
        end
      end
    end

    it_behaves_like 'integration instances'

    context 'with all existing instances' do
      def integration_hash(type)
        Integration.new(instance: true, type: type).to_database_hash
      end

      before do
        attrs = described_class.available_integration_types(include_project_specific: false).map do |integration_type|
          integration_hash(integration_type)
        end

        described_class.insert_all(attrs)
      end

      it_behaves_like 'integration instances'

      context 'with a previous existing integration (:mock_ci) and a new integration (:asana)' do
        before do
          described_class.insert(integration_hash(:mock_ci))
          described_class.delete_by(**integration_hash(:asana))
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

  describe '#inheritable?' do
    it 'is true for an instance integration' do
      expect(create(:integration, :instance)).to be_inheritable
    end

    it 'is true for a group integration' do
      expect(create(:integration, :group)).to be_inheritable
    end

    it 'is false for a project integration' do
      expect(create(:integration)).not_to be_inheritable
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
          expect(new_integration.instance).to be(false)
          expect(new_integration.project).to eq(project)
          expect(new_integration.group).to be_nil
        end

        it 'creates a correct integration for a group integration' do
          new_integration = described_class.build_from_integration(integration, group_id: group.id)

          expect(new_integration).to be_active
          expect(new_integration.url).to eq(url)
          expect(new_integration.api_url).to eq(api_url)
          expect(new_integration.username).to eq(username)
          expect(new_integration.password).to eq(password)
          expect(new_integration.instance).to be(false)
          expect(new_integration.project).to be_nil
          expect(new_integration.group).to eq(group)
        end
      end

      # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
      context 'when data is stored in properties' do
        let(:properties) { data_params }
        let!(:integration) do
          create(:jira_integration, :without_properties_callback, project: project,
            properties: properties.merge(additional: 'something'))
        end

        it_behaves_like 'integration creation from an integration'
      end

      context 'when data are stored in separated fields' do
        let(:integration) do
          create(:jira_integration, data_params.merge(properties: {}, project: project))
        end

        it_behaves_like 'integration creation from an integration'
      end

      context 'when data are stored in both properties and separated fields' do
        let(:properties) { data_params }
        let(:integration) do
          create(:jira_integration, :without_properties_callback, project: project, active: true,
            properties: properties).tap do |integration|
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
        expect(described_class.default_integration('Integrations::Jira', project)).to eq(instance_integration)
      end

      it 'returns nil for nonexistent integration type' do
        expect(described_class.default_integration('Integrations::Hipchat', project)).to be_nil
      end

      context 'with a group integration' do
        let(:integration_name) { 'Integrations::Jira' }

        let_it_be(:group_integration) { create(:jira_integration, group_id: group.id, project_id: nil) }

        it 'returns the group integration for a project' do
          expect(described_class.default_integration(integration_name, project)).to eq(group_integration)
        end

        it 'returns the instance integration for a group' do
          expect(described_class.default_integration(integration_name, group)).to eq(instance_integration)
        end

        context 'with a subgroup' do
          let_it_be(:subgroup) { create(:group, parent: group) }

          let!(:project) { create(:project, group: subgroup) }

          it 'returns the closest group integration for a project' do
            expect(described_class.default_integration(integration_name, project)).to eq(group_integration)
          end

          it 'returns the closest group integration for a subgroup' do
            expect(described_class.default_integration(integration_name, subgroup)).to eq(group_integration)
          end

          context 'when having an integration with custom settings' do
            let!(:subgroup_integration) { create(:jira_integration, group_id: subgroup.id, project_id: nil) }

            it 'returns the closest group integration for a project' do
              expect(described_class.default_integration(integration_name, project)).to eq(subgroup_integration)
            end
          end

          context 'when having an integration inheriting settings' do
            let!(:subgroup_integration) do
              create(:jira_integration, group_id: subgroup.id, project_id: nil, inherit_from_id: group_integration.id)
            end

            it 'returns the closest group integration which does not inherit from its parent for a project' do
              expect(described_class.default_integration(integration_name, project)).to eq(group_integration)
            end
          end
        end
      end
    end
  end

  describe '.create_from_default_integrations' do
    let!(:instance_integration) { create(:prometheus_integration, :instance, api_url: 'https://prometheus.instance.com/') }
    let!(:instance_level_instance_specific_integration) { create(:beyond_identity_integration) }

    it 'creates integrations from default integrations' do
      expect(described_class).to receive(:create_from_active_default_integrations)
        .with(project, :project_id).and_call_original
      expect(described_class).to receive(:create_from_default_instance_specific_integrations)
        .with(project, :project_id).and_call_original

      expect(described_class.create_from_default_integrations(project, :project_id)).to eq(2)
    end

    context 'when called with a group' do
      it 'creates integrations from default integrations' do
        expect(described_class).to receive(:create_from_active_default_integrations)
          .with(group, :group_id).and_call_original
        expect(described_class).to receive(:create_from_default_instance_specific_integrations)
          .with(group, :group_id).and_call_original

        expect(described_class.create_from_default_integrations(group, :group_id)).to eq(2)
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

      context 'when passing a group' do
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

        context 'when there are multiple inheritable integrations, and a duplicate' do
          let!(:jenkins_integration) { create(:jenkins_integration, :group, group: group) }
          let!(:datadog_integration) { create(:datadog_integration, :instance) }
          let!(:duplicate_jenkins_integration) { create(:jenkins_integration, project: project) }

          it 'returns the number of successfully created integrations' do
            expect(described_class.create_from_active_default_integrations(project, :project_id)).to eq 2

            expect(project.reload.integrations.size).to eq(3)
          end
        end

        context 'when passing a group' do
          let!(:subgroup) { create(:group, parent: group) }

          it 'creates an integration from the group-level integration' do
            described_class.create_from_active_default_integrations(subgroup, :group_id)

            expect(subgroup.reload.integrations.size).to eq(1)
            expect(subgroup.reload.integrations.first.api_url).to eq(group_integration.api_url)
            expect(subgroup.reload.integrations.first.inherit_from_id).to eq(group_integration.id)
          end
        end

        context 'with an active subgroup' do
          let_it_be(:subgroup) { create(:group, parent: group) }
          let_it_be(:project) { create(:project, group: subgroup) }

          let!(:subgroup_integration) { create(:prometheus_integration, :group, group: subgroup, api_url: 'https://prometheus.subgroup.com/') }

          it 'creates an integration from the subgroup-level integration' do
            described_class.create_from_active_default_integrations(project, :project_id)

            expect(project.reload.integrations.size).to eq(1)
            expect(project.reload.integrations.first.api_url).to eq(subgroup_integration.api_url)
            expect(project.reload.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
          end

          context 'when passing a group' do
            let!(:sub_subgroup) { create(:group, parent: subgroup) }

            context 'with traversal queries' do
              shared_examples 'correct ancestor order' do
                it 'creates an integration from the subgroup-level integration' do
                  described_class.create_from_active_default_integrations(sub_subgroup, :group_id)

                  sub_subgroup.reload

                  expect(sub_subgroup.integrations.size).to eq(1)
                  expect(sub_subgroup.integrations.first.api_url).to eq(subgroup_integration.api_url)
                  expect(sub_subgroup.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
                end

                context 'when having an integration inheriting settings' do
                  let!(:subgroup_integration) do
                    create(:prometheus_integration, :group, group: subgroup, inherit_from_id: group_integration.id,
                      api_url: 'https://prometheus.subgroup.com/')
                  end

                  it 'creates an integration from the group-level integration' do
                    described_class.create_from_active_default_integrations(sub_subgroup, :group_id)

                    sub_subgroup.reload

                    expect(sub_subgroup.integrations.size).to eq(1)
                    expect(sub_subgroup.integrations.first.api_url).to eq(group_integration.api_url)
                    expect(sub_subgroup.integrations.first.inherit_from_id).to eq(group_integration.id)
                  end
                end
              end

              include_examples 'correct ancestor order'
            end
          end
        end
      end

      context 'when the integration is instance specific' do
        let!(:instance_integration) { create(:beyond_identity_integration) }

        it 'does not create an integration from the instance level instance specific integration' do
          described_class.create_from_active_default_integrations(project, :project_id)

          expect(project.reload.integrations).to be_blank
        end
      end
    end
  end

  describe '.create_from_default_instance_specific_integrations' do
    context 'with an active instance-level integration' do
      let!(:instance_integration) { create(:beyond_identity_integration) }

      it 'creates an integration from the instance-level integration' do
        described_class.create_from_default_instance_specific_integrations(project, :project_id)
        expect(project.reload.integrations.size).to eq(1)
        expect(project.reload.integrations.first.inherit_from_id).to eq(instance_integration.id)
      end

      context 'when passing a group' do
        it 'creates an integration from the instance-level integration' do
          described_class.create_from_default_instance_specific_integrations(group, :group_id)

          expect(group.reload.integrations.size).to eq(1)
          expect(group.reload.integrations.first.inherit_from_id).to eq(instance_integration.id)
        end
      end

      context 'with active group-level integration' do
        let!(:group_integration) { create(:beyond_identity_integration, group: group, instance: false) }

        it 'creates an integration from the group-level integration' do
          described_class.create_from_default_instance_specific_integrations(project, :project_id)

          expect(project.reload.integrations.size).to eq(1)
          expect(project.reload.integrations.first.inherit_from_id).to eq(group_integration.id)
        end

        context 'when group level integration is not active' do
          let!(:group_integration) do
            create(:beyond_identity_integration, group: group, instance: false, active: false)
          end

          it 'creates an integration from the group-level integration' do
            described_class.create_from_default_instance_specific_integrations(project, :project_id)

            expect(project.reload.integrations.size).to eq(1)
            expect(project.reload.integrations.first.inherit_from_id).to eq(group_integration.id)
            expect(project.reload.integrations.first).not_to be_active
          end
        end

        context 'when passing a group' do
          let!(:subgroup) { create(:group, parent: group) }

          it 'creates an integration from the group-level integration' do
            described_class.create_from_default_instance_specific_integrations(subgroup, :group_id)

            expect(subgroup.reload.integrations.size).to eq(1)
            expect(subgroup.reload.integrations.first.inherit_from_id).to eq(group_integration.id)
          end
        end

        context 'with an active subgroup' do
          let_it_be(:subgroup) { create(:group, parent: group) }
          let_it_be(:project) { create(:project, group: subgroup) }
          let!(:subgroup_integration) { create(:beyond_identity_integration, group: subgroup, instance: false) }

          it 'creates an integration from the subgroup-level integration' do
            described_class.create_from_default_instance_specific_integrations(project, :project_id)

            expect(project.reload.integrations.size).to eq(1)
            expect(project.reload.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
          end

          context 'when passing a group' do
            let!(:sub_subgroup) { create(:group, parent: subgroup) }

            context 'with traversal queries' do
              shared_examples 'correct ancestor order' do
                it 'creates an integration from the subgroup-level integration' do
                  described_class.create_from_default_instance_specific_integrations(sub_subgroup, :group_id)

                  sub_subgroup.reload

                  expect(sub_subgroup.integrations.size).to eq(1)
                  expect(sub_subgroup.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
                end

                context 'when having an integration inheriting settings' do
                  let!(:subgroup_integration) do
                    create(:beyond_identity_integration, group: subgroup, inherit_from_id: group_integration.id,
                      instance: false)
                  end

                  it 'creates an integration from the group-level integration' do
                    described_class.create_from_default_instance_specific_integrations(sub_subgroup, :group_id)

                    sub_subgroup.reload

                    expect(sub_subgroup.integrations.size).to eq(1)
                    expect(sub_subgroup.integrations.first.inherit_from_id).to eq(group_integration.id)
                  end
                end
              end

              include_examples 'correct ancestor order'
            end
          end
        end
      end

      context 'when the integration is not instance specific' do
        let!(:instance_integration) { create(:prometheus_integration, :instance) }

        it 'does not create an integration from the instance level instance specific integration' do
          described_class.create_from_default_instance_specific_integrations(project, :project_id)

          expect(project.reload.integrations).to be_blank
        end
      end
    end
  end

  describe '.inherited_descendants_from_self_or_ancestors_from' do
    let_it_be(:subgroup_1) { create(:group, parent: group) }
    let_it_be(:subgroup_2) { create(:group, parent: group) }
    let_it_be(:project_1) { create(:project, group: subgroup_1) }
    let_it_be(:project_2) { create(:project, group: subgroup_2) }
    let_it_be(:group_integration) { create(:prometheus_integration, :group, group: group) }
    let_it_be(:subgroup_integration_1) do
      create(:prometheus_integration, :group, group: subgroup_1, inherit_from_id: group_integration.id)
    end

    let_it_be(:subgroup_integration_2) { create(:prometheus_integration, :group, group: subgroup_2) }
    let_it_be(:project_integration_1) do
      create(:prometheus_integration, project: project_1, inherit_from_id: group_integration.id)
    end

    let_it_be(:project_integration_2) do
      create(:prometheus_integration, project: project_2, inherit_from_id: subgroup_integration_2.id)
    end

    it 'returns the groups and projects inheriting from integration ancestors', :aggregate_failures do
      expect(described_class.inherited_descendants_from_self_or_ancestors_from(group_integration))
        .to eq([subgroup_integration_1, project_integration_1])
      expect(described_class.inherited_descendants_from_self_or_ancestors_from(subgroup_integration_2))
        .to eq([project_integration_2])
    end
  end

  describe '.descendants_from_self_or_ancestors_from' do
    let_it_be(:project) { create(:project, :in_subgroup) }
    let(:group) { project.root_namespace }
    let(:subgroup) { project.group }
    let!(:group_integration) { create(:prometheus_integration, :group, group: group) }
    let!(:subgroup_integration) do
      create(:prometheus_integration, :group, group: subgroup, inherit_from_id: group_integration.id)
    end

    let!(:project_custom_settings_integration) do
      create(:prometheus_integration, project: project, inherit_from_id: nil)
    end

    it 'returns integrations for descendants of the group of the integration' do
      expect(described_class.descendants_from_self_or_ancestors_from(group_integration))
        .to contain_exactly(subgroup_integration, project_custom_settings_integration)
    end
  end

  describe '.integration_name_to_type' do
    it 'handles a simple case' do
      expect(described_class.integration_name_to_type(:asana)).to eq 'Integrations::Asana'
    end

    it 'raises an error if the name is unknown' do
      expect { described_class.integration_name_to_type('foo') }
        .to raise_exception(described_class::UnknownType, /foo/)
    end

    it 'does not raise an error if the name is a disabled integration' do
      allow(described_class).to receive(:disabled_integration_names).and_return(['asana'])

      expect { described_class.integration_name_to_type('asana') }.not_to raise_exception
    end

    it 'handles all available_integration_names' do
      types = described_class.available_integration_names.map do |integration_name|
        described_class.integration_name_to_type(integration_name)
      end

      expect(types).to all(start_with('Integrations::'))
    end
  end

  describe '.integration_name_to_model' do
    it 'raises an error if integration name is invalid' do
      expect do
        described_class.integration_name_to_model('foo')
      end.to raise_exception(described_class::UnknownType, /foo/)
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

  describe '#properties=' do
    let(:integration_type) do
      Class.new(described_class) do
        field :foo
        field :bar
      end
    end

    it 'supports indifferent access' do
      integration = integration_type.new

      integration.properties = { foo: 1, 'bar' => 2 }

      expect(integration).to have_attributes(foo: 1, bar: 2)
    end
  end

  describe '#properties' do
    it 'is not mutable' do
      integration = described_class.new

      integration.properties = { foo: 1, bar: 2 }

      expect { integration.properties[:foo] = 3 }.to raise_error(FrozenError)
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

  describe 'field definitions' do
    shared_examples '#fields' do
      it 'does not return the same array' do
        integration = fake_integration.new

        expect(integration.fields).not_to be(integration.fields)
      end
    end

    shared_examples '#api_field_names' do
      it 'filters out secret fields and conditional fields' do
        safe_fields = %w[some_safe_field safe_field url trojan_gift api_only_field enabled_field]

        expect(fake_integration.new).to have_attributes(
          api_field_names: match_array(safe_fields)
        )
      end
    end

    shared_examples '#form_fields' do
      it 'filters out API only fields' do
        expect(fake_integration.new.form_fields.pluck(:name)).not_to include('api_only_field')
      end

      it 'filters conditionals fields' do
        expect(fake_integration.new.form_fields.pluck(:name)).to include('enabled_field')
        expect(fake_integration.new.form_fields.pluck(:name)).not_to include('disabled_field', 'disabled_field_2')
      end
    end

    context 'when the class overrides #fields' do
      let(:fake_integration) do
        Class.new(Integration) do
          def fields
            [
              { name: 'token', type: :password },
              { name: 'api_token', type: :password },
              { name: 'token_api', type: :password },
              { name: 'safe_token', type: :password },
              { name: 'key', type: :password },
              { name: 'api_key', type: :password },
              { name: 'password', type: :password },
              { name: 'password_field', type: :password },
              { name: 'webhook' },
              { name: 'some_safe_field' },
              { name: 'safe_field' },
              { name: 'url' },
              { name: 'trojan_horse', type: :password },
              { name: 'trojan_gift', type: :text },
              { name: 'api_only_field', api_only: true },
              { name: 'enabled_field', if: true },
              { name: 'disabled_field', if: false },
              { name: 'disabled_field_2', if: nil }
            ].shuffle
          end
        end
      end

      it_behaves_like '#fields'
      it_behaves_like '#api_field_names'
      it_behaves_like '#form_fields'
    end

    context 'when the class uses the field DSL' do
      let(:fake_integration) do
        Class.new(described_class) do
          field :token, type: :password
          field :api_token, type: :password
          field :token_api, type: :password
          field :safe_token, type: :password
          field :key, type: :password
          field :api_key, type: :password
          field :password, type: :password
          field :password_field, type: :password
          field :webhook
          field :some_safe_field
          field :safe_field
          field :url
          field :trojan_horse, type: :password
          field :trojan_gift, type: :text
          field :api_only_field, api_only: true
          field :enabled_field, if: -> { true }
          field :disabled_field, if: -> { false }
          field :disabled_field_2, if: -> {}
        end
      end

      it_behaves_like '#fields'
      it_behaves_like '#api_field_names'
      it_behaves_like '#form_fields'
    end
  end

  context 'with logging' do
    let(:integration) { build(:integration, project: project) }
    let(:test_message) { "test message" }
    let(:arguments) do
      {
        integration_class: integration.class.name,
        integration_id: integration.id,
        project_path: project.full_path,
        project_id: project.id,
        message: test_message,
        additional_argument: 'some argument'
      }
    end

    it 'logs info messages using json logger' do
      expect(Gitlab::IntegrationsLogger).to receive(:info).with(arguments)

      integration.log_info(test_message, additional_argument: 'some argument')
    end

    it 'logs error messages using json logger' do
      expect(Gitlab::IntegrationsLogger).to receive(:error).with(arguments)

      integration.log_error(test_message, additional_argument: 'some argument')
    end

    context 'when project is nil' do
      let(:project) { nil }
      let(:arguments) do
        {
          integration_class: integration.class.name,
          integration_id: integration.id,
          project_path: nil,
          project_id: nil,
          message: test_message,
          additional_argument: 'some argument'
        }
      end

      it 'logs info messages using json logger' do
        expect(Gitlab::IntegrationsLogger).to receive(:info).with(arguments)

        integration.log_info(test_message, additional_argument: 'some argument')
      end
    end

    context 'with logging exceptions' do
      let(:error) { RuntimeError.new('exception message') }
      let(:arguments) do
        super().merge(
          'exception.class' => 'RuntimeError',
          'exception.message' => 'exception message'
        )
      end

      it 'logs exceptions using json logger' do
        expect(Gitlab::IntegrationsLogger).to receive(:error).with(arguments.merge(message: 'exception message'))

        integration.log_exception(error, additional_argument: 'some argument')
      end

      it 'logs exceptions using json logger with a custom message' do
        expect(Gitlab::IntegrationsLogger).to receive(:error).with(arguments.merge(message: 'custom message'))

        integration.log_exception(error, message: 'custom message', additional_argument: 'some argument')
      end
    end
  end

  describe '.available_integration_names' do
    subject { described_class.available_integration_names }

    it { is_expected.not_to include('jira_cloud_app') }

    context 'when instance is configured for Jira Cloud app' do
      before do
        stub_application_setting(jira_connect_application_key: 'mock_app_oauth_key')
      end

      it { is_expected.to include('jira_cloud_app') }
    end
  end

  describe '.available_integration_names (stubbed)' do
    subject { described_class.available_integration_names }

    before do
      allow(described_class).to receive_messages(
        integration_names: %w[foo disabled],
        project_specific_integration_names: ['project'],
        project_and_group_specific_integration_names: ['project-and-group'],
        dev_integration_names: ['dev'],
        instance_specific_integration_names: ['instance'],
        disabled_integration_names: ['disabled']
      )
    end

    it { is_expected.to include('foo', 'project', 'project-and-group', 'instance', 'dev') }
    it { is_expected.not_to include('disabled') }

    context 'when `include_project_specific` is false' do
      subject { described_class.available_integration_names(include_project_specific: false) }

      it { is_expected.to include('foo', 'dev', 'project-and-group', 'instance') }
      it { is_expected.not_to include('project', 'disabled') }
    end

    context 'when `include_dev` is false' do
      subject { described_class.available_integration_names(include_dev: false) }

      it { is_expected.to include('foo', 'project', 'project-and-group', 'instance') }
      it { is_expected.not_to include('dev', 'disabled') }
    end

    context 'when `include_instance_specific` is false' do
      subject { described_class.available_integration_names(include_instance_specific: false) }

      it { is_expected.to include('foo', 'dev', 'project', 'project-and-group') }
      it { is_expected.not_to include('instance', 'disabled') }
    end

    context 'when `include_project_specific` and `include_group_specific` are false' do
      subject do
        described_class.available_integration_names(
          include_project_specific: false,
          include_group_specific: false
        )
      end

      it { is_expected.to include('foo', 'dev', 'instance') }
      it { is_expected.not_to include('project', 'project-and-group', 'disabled') }
    end

    context 'when `include_disabled` is true' do
      subject { described_class.available_integration_names(include_disabled: true) }

      it { is_expected.to include('disabled') }
    end
  end

  describe '.integration_names' do
    subject { described_class.integration_names }

    it { is_expected.to include(*described_class::INTEGRATION_NAMES - ['jira_cloud_app']) }
    it { is_expected.to include('gitlab_slack_application') }

    context 'when Rails.env is not test' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it { is_expected.not_to include('gitlab_slack_application') }

      context 'when `slack_app_enabled` setting is enabled' do
        before do
          stub_application_setting(slack_app_enabled: true)
        end

        it { is_expected.to include('gitlab_slack_application') }
      end
    end
  end

  describe '.project_specific_integration_names' do
    subject { described_class.project_specific_integration_names }

    it { is_expected.to include(*described_class::PROJECT_LEVEL_ONLY_INTEGRATION_NAMES) }
  end

  describe '.all_integration_names' do
    subject(:names) { described_class.all_integration_names }

    it 'includes project-specific integrations' do
      expect(names).to include(*described_class::PROJECT_LEVEL_ONLY_INTEGRATION_NAMES)
    end

    it 'includes group-specific integrations' do
      expect(names).to include(*described_class::PROJECT_AND_GROUP_LEVEL_ONLY_INTEGRATION_NAMES)
    end

    it 'includes instance-specific integrations' do
      expect(names).to include(*described_class::INSTANCE_LEVEL_ONLY_INTEGRATION_NAMES)
    end

    it 'includes development-specific integrations' do
      expect(names).to include(*described_class::DEV_INTEGRATION_NAMES)
    end

    it 'includes disabled integrations' do
      allow(described_class).to receive(:disabled_integration_names).and_return(Integrations::Asana.to_param)

      expect(names).to include(Integrations::Asana.to_param)
    end
  end

  describe '#secret_fields' do
    it 'returns all fields with type `password`' do
      allow(integration).to receive(:fields).and_return(
        [
          Integrations::Field.new(name: 'password', integration_class: integration.class, type: :password),
          Integrations::Field.new(name: 'secret', integration_class: integration.class, type: :password),
          Integrations::Field.new(name: 'public', integration_class: integration.class, type: :text)
        ])

      expect(integration.secret_fields).to match_array(%w[password secret])
    end

    it 'returns an empty array if no secret fields exist' do
      expect(integration.secret_fields).to eq([])
    end
  end

  describe '#to_database_hash' do
    let(:properties) { { foo: 1, bar: true } }
    let(:db_props) { properties.stringify_keys }
    let(:record) { create(:integration, :instance, properties: properties) }

    it 'does not include the properties key' do
      hash = record.to_database_hash

      expect(hash).not_to have_key('properties')
    end

    it 'does not include certain attributes' do
      hash = record.to_database_hash

      expect(hash.keys).not_to include('id', 'instance', 'project_id', 'group_id', 'created_at', 'updated_at')
    end

    it 'saves correctly using insert_all' do
      hash = record.to_database_hash
      hash[:project_id] = project.id

      expect do
        described_class.insert_all([hash])
      end.to change { described_class.count }.by(1)

      expect(described_class.last).to have_attributes(properties: db_props)
    end

    it 'decrypts encrypted properties correctly' do
      hash = record.to_database_hash

      expect(hash).to include('encrypted_properties' => be_present, 'encrypted_properties_iv' => be_present)
      expect(hash['encrypted_properties']).not_to eq(record.encrypted_properties)
      expect(hash['encrypted_properties_iv']).not_to eq(record.encrypted_properties_iv)

      decrypted = described_class.attr_decrypt(
        :properties,
        hash['encrypted_properties'],
        { iv: hash['encrypted_properties_iv'] }
      )

      expect(decrypted).to eq db_props
    end

    context 'when the properties are empty' do
      let(:properties) { {} }

      it 'is part of the to_database_hash' do
        hash = record.to_database_hash

        expect(hash).to include('encrypted_properties' => be_nil, 'encrypted_properties_iv' => be_nil)
      end

      it 'saves correctly using insert_all' do
        hash = record.to_database_hash
        hash[:project_id] = project

        expect do
          described_class.insert_all([hash])
        end.to change { described_class.count }.by(1)

        expect(described_class.last).not_to eq record
        expect(described_class.last).to have_attributes(properties: db_props)
      end
    end
  end

  describe 'field DSL' do
    let(:integration_type) do
      Class.new(described_class) do
        field :foo
        field :foo_p, storage: :properties
        field :foo_dt, storage: :data_fields

        field :bar, type: :password
        field :password, is_secret: true

        field :webhook

        field :with_help, help: -> { 'help' }
        field :select, type: :select
        field :boolean, type: :checkbox
      end
    end

    let(:integration) { integration_type.new }
    let(:data_fields) { Struct.new(:foo_dt).new }

    before do
      allow(integration).to receive(:data_fields).and_return(data_fields)
    end

    it 'checks the value of storage' do
      expect do
        Class.new(described_class) { field(:foo, storage: 'bar') }
      end.to raise_error(ArgumentError, /Unknown field storage/)
    end

    it 'provides prop_accessors' do
      integration.foo = 1
      expect(integration.foo).to eq 1
      expect(integration.properties['foo']).to eq 1
      expect(integration).to be_foo_changed

      integration.foo_p = 2
      expect(integration.foo_p).to eq 2
      expect(integration.properties['foo_p']).to eq 2
      expect(integration).to be_foo_p_changed
    end

    it 'provides boolean accessors for checkbox fields' do
      expect(integration).to respond_to(:boolean)
      expect(integration).to respond_to(:boolean?)

      expect(integration).not_to respond_to(:foo?)
      expect(integration).not_to respond_to(:bar?)
      expect(integration).not_to respond_to(:password?)
      expect(integration).not_to respond_to(:select?)
    end

    it 'provides data fields' do
      integration.foo_dt = 3
      expect(integration.foo_dt).to eq 3
      expect(data_fields.foo_dt).to eq 3
      expect(integration).to be_foo_dt_changed
    end

    it 'registers fields in the fields list' do
      expect(integration.fields.pluck(:name)).to match_array %w[
        foo foo_p foo_dt bar password with_help select boolean webhook
      ]

      expect(integration.api_field_names).to match_array %w[
        foo foo_p foo_dt with_help select boolean
      ]
    end

    specify 'fields have expected attributes' do
      expect(integration.fields).to include(
        have_attributes(name: 'foo', type: :text),
        have_attributes(name: 'foo_p', type: :text),
        have_attributes(name: 'foo_dt', type: :text),
        have_attributes(name: 'bar', type: :password),
        have_attributes(name: 'password', type: :password),
        have_attributes(name: 'webhook', type: :text),
        have_attributes(name: 'with_help', help: 'help'),
        have_attributes(name: 'select', type: :select),
        have_attributes(name: 'boolean', type: :checkbox)
      )
    end
  end

  describe 'Checkbox field booleans' do
    let(:klass) do
      Class.new(Integration) do
        field :test_value, type: :checkbox
      end
    end

    let(:integration) { klass.new(test_value: input) }

    where(:input, :method_result, :predicate_method_result) do
      true     | true  | true
      false    | false | false
      1        | true  | true
      0        | false | false
      '1'      | true  | true
      '0'      | false | false
      'true'   | true  | true
      'false'  | false | false
      'foobar' | nil   | false
      ''       | nil   | false
      nil      | nil   | false
      'on'     | true  | true
      'off'    | false | false
      'yes'    | true  | true
      'no'     | false | false
      'n'      | false | false
      'y'      | true  | true
      't'      | true  | true
      'f'      | false | false
    end

    with_them do
      it 'has the correct value' do
        expect(integration).to have_attributes(
          test_value: be(method_result),
          test_value?: be(predicate_method_result)
        )

        # Make sure the original value is stored correctly
        expect(integration.send(:test_value_before_type_cast)).to eq(input)
        expect(integration.properties).to include('test_value' => input)
      end

      context 'when using data fields' do
        let(:klass) do
          Class.new(Integration) do
            field :project_url, storage: :data_fields, type: :checkbox

            def data_fields
              issue_tracker_data || build_issue_tracker_data
            end
          end
        end

        let(:integration) { klass.new(project_url: input) }

        it 'has the correct value' do
          expect(integration).to have_attributes(
            project_url: be(method_result),
            project_url?: be(predicate_method_result)
          )

          # Make sure the original value is stored correctly
          expect(integration.send(:project_url_before_type_cast)).to eq(input == false ? 'false' : input)
          expect(integration.properties).not_to include('project_url')
        end
      end
    end

    it 'returns values when initialized without input' do
      integration = klass.new

      expect(integration).to have_attributes(
        test_value: be_nil,
        test_value?: be(false)
      )
    end
  end

  describe '#attributes' do
    it 'does not include properties' do
      expect(build(:integration, project: project).attributes).not_to have_key('properties')
    end

    it 'can be used in assign_attributes without nullifying properties' do
      record = build(:integration, :instance, properties: { url: generate(:url) })

      attrs = record.attributes

      expect { record.assign_attributes(attrs) }.not_to change { record.properties }
    end
  end

  describe '#dup' do
    let(:original) { build(:integration, project: project, properties: { one: 1, two: 2, three: 3 }) }

    it 'results in distinct ciphertexts, but identical properties' do
      copy = original.dup

      expect(copy).to have_attributes(properties: eq(original.properties))

      expect(copy).not_to have_attributes(
        encrypted_properties: eq(original.encrypted_properties)
      )
    end

    context 'when the model supports data-fields' do
      let(:original) { build(:jira_integration, project: project, username: generate(:username), url: generate(:url)) }

      it 'creates distinct but identical data-fields' do
        copy = original.dup

        expect(copy).to have_attributes(
          username: original.username,
          url: original.url
        )

        expect(copy.data_fields).not_to eq(original.data_fields)
      end
    end
  end

  describe '#async_execute' do
    let(:integration) { build(:jenkins_integration, id: 123) }
    let(:data) { { object_kind: 'build' } }
    let(:serialized_data) { data.deep_stringify_keys }
    let(:supported_events) { %w[push build] }

    subject(:async_execute) { integration.async_execute(data) }

    before do
      allow(integration).to receive(:supported_events).and_return(supported_events)
    end

    it 'queues a Integrations::ExecuteWorker' do
      expect(Integrations::ExecuteWorker).to receive(:perform_async).with(integration.id, serialized_data)

      async_execute
    end

    context 'when the event is not supported' do
      let(:supported_events) { %w[issue] }

      it 'does not queue a worker' do
        expect(Integrations::ExecuteWorker).not_to receive(:perform_async)

        async_execute
      end

      it 'writes a log' do
        expect(Gitlab::IntegrationsLogger).to receive(:info).with(
          hash_including(
            message: 'async_execute did nothing due to event not being supported',
            integration_class: 'Integrations::Jenkins',
            event: 'build'
          )
        ).and_call_original

        async_execute
      end
    end

    context 'when the Gitlab::SilentMode is enabled' do
      before do
        allow(Gitlab::SilentMode).to receive(:enabled?).and_return(true)
      end

      it 'does not queue a worker' do
        expect(Integrations::ExecuteWorker).not_to receive(:perform_async)

        async_execute
      end
    end

    context 'when integration is not active' do
      before do
        integration.active = false
      end

      it 'does not queue a worker' do
        expect(Integrations::ExecuteWorker).not_to receive(:perform_async)

        async_execute
      end
    end
  end

  describe '.instance_specific_integration_types' do
    subject { described_class.instance_specific_integration_types }

    it { is_expected.to eq(['Integrations::BeyondIdentity']) }
  end
end
