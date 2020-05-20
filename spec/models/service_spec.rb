# frozen_string_literal: true

require 'spec_helper'

describe Service do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
    it { is_expected.to have_one :jira_tracker_data }
    it { is_expected.to have_one :issue_tracker_data }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:type) }

    it 'validates presence of project_id if not template', :aggregate_failures do
      expect(build(:service, project_id: nil, template: true)).to be_valid
      expect(build(:service, project_id: nil, template: false)).to be_invalid
    end

    it 'validates presence of project_id if not instance', :aggregate_failures do
      expect(build(:service, project_id: nil, instance: true)).to be_valid
      expect(build(:service, project_id: nil, instance: false)).to be_invalid
    end

    it 'validates absence of project_id if instance', :aggregate_failures do
      expect(build(:service, project_id: nil, instance: true)).to be_valid
      expect(build(:service, instance: true)).to be_invalid
    end

    it 'validates absence of project_id if template', :aggregate_failures do
      expect(build(:service, template: true)).to validate_absence_of(:project_id)
      expect(build(:service, template: false)).not_to validate_absence_of(:project_id)
    end

    it 'validates service is template or instance' do
      expect(build(:service, project_id: nil, template: true, instance: true)).to be_invalid
    end

    context 'with an existing service template' do
      before do
        create(:service, :template)
      end

      it 'validates only one service template per type' do
        expect(build(:service, :template)).to be_invalid
      end
    end

    context 'with an existing instance service' do
      before do
        create(:service, :instance)
      end

      it 'validates only one service instance per type' do
        expect(build(:service, :instance)).to be_invalid
      end
    end

    it 'validates uniqueness of type and project_id on create' do
      project = create(:project)

      expect(create(:service, project: project, type: 'Service')).to be_valid
      expect(build(:service, project: project, type: 'Service').valid?(:create)).to eq(false)
      expect(build(:service, project: project, type: 'Service').valid?(:update)).to eq(true)
    end
  end

  describe 'Scopes' do
    describe '.by_type' do
      let!(:service1) { create(:jira_service) }
      let!(:service2) { create(:jira_service) }
      let!(:service3) { create(:redmine_service) }

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
  end

  describe "Test Button" do
    describe '#can_test?' do
      subject { service.can_test? }

      let(:service) { create(:service, project: project) }

      context 'when repository is not empty' do
        let(:project) { create(:project, :repository) }

        it { is_expected.to be true }
      end

      context 'when repository is empty' do
        let(:project) { create(:project) }

        it { is_expected.to be true }
      end

      context 'when instance-level service' do
        Service.available_services_types.each do |service_type|
          let(:service) do
            service_type.constantize.new(instance: true)
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#test' do
      let(:data) { 'test' }
      let(:service) { create(:service, project: project) }

      context 'when repository is not empty' do
        let(:project) { create(:project, :repository) }

        it 'test runs execute' do
          expect(service).to receive(:execute).with(data)

          service.test(data)
        end
      end

      context 'when repository is empty' do
        let(:project) { create(:project) }

        it 'test runs execute' do
          expect(service).to receive(:execute).with(data)

          service.test(data)
        end
      end
    end
  end

  describe '.find_or_initialize_instances' do
    shared_examples 'service instances' do
      it 'returns the available service instances' do
        expect(Service.find_or_initialize_instances.pluck(:type)).to match_array(Service.available_services_types)
      end

      it 'does not create service instances' do
        expect { Service.find_or_initialize_instances }.not_to change { Service.count }
      end
    end

    it_behaves_like 'service instances'

    context 'with all existing instances' do
      before do
        Service.insert_all(
          Service.available_services_types.map { |type| { instance: true, type: type } }
        )
      end

      it_behaves_like 'service instances'

      context 'with a previous existing service (Previous) and a new service (Asana)' do
        before do
          Service.insert(type: 'PreviousService', instance: true)
          Service.delete_by(type: 'AsanaService', instance: true)
        end

        it_behaves_like 'service instances'
      end
    end

    context 'with a few existing instances' do
      before do
        create(:jira_service, :instance)
      end

      it_behaves_like 'service instances'
    end
  end

  describe 'template' do
    let(:project) { create(:project) }

    shared_examples 'retrieves service templates' do
      it 'returns the available service templates' do
        expect(Service.find_or_create_templates.pluck(:type)).to match_array(Service.available_services_types)
      end
    end

    describe '.find_or_create_templates' do
      it 'creates service templates' do
        expect { Service.find_or_create_templates }.to change { Service.count }.from(0).to(Service.available_services_names.size)
      end

      it_behaves_like 'retrieves service templates'

      context 'with all existing templates' do
        before do
          Service.insert_all(
            Service.available_services_types.map { |type| { template: true, type: type } }
          )
        end

        it 'does not create service templates' do
          expect { Service.find_or_create_templates }.not_to change { Service.count }
        end

        it_behaves_like 'retrieves service templates'

        context 'with a previous existing service (Previous) and a new service (Asana)' do
          before do
            Service.insert(type: 'PreviousService', template: true)
            Service.delete_by(type: 'AsanaService', template: true)
          end

          it_behaves_like 'retrieves service templates'
        end
      end

      context 'with a few existing templates' do
        before do
          create(:jira_service, :template)
        end

        it 'creates the rest of the service templates' do
          expect { Service.find_or_create_templates }.to change { Service.count }.from(1).to(Service.available_services_names.size)
        end

        it_behaves_like 'retrieves service templates'
      end
    end

    describe '.build_from_integration' do
      context 'when template is invalid' do
        it 'sets service template to inactive when template is invalid' do
          template = build(:prometheus_service, template: true, active: true, properties: {})
          template.save(validate: false)

          service = described_class.build_from_integration(project.id, template)

          expect(service).to be_valid
          expect(service.active).to be false
        end
      end

      describe 'build issue tracker from a template' do
        let(:title) { 'custom title' }
        let(:description) { 'custom description' }
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

        shared_examples 'service creation from a template' do
          it 'creates a correct service' do
            service = described_class.build_from_integration(project.id, template)

            expect(service).to be_active
            expect(service.title).to eq(title)
            expect(service.description).to eq(description)
            expect(service.url).to eq(url)
            expect(service.api_url).to eq(api_url)
            expect(service.username).to eq(username)
            expect(service.password).to eq(password)
            expect(service.template).to eq(false)
            expect(service.instance).to eq(false)
          end
        end

        # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
        context 'when data are stored in properties' do
          let(:properties) { data_params.merge(title: title, description: description) }
          let!(:template) do
            create(:jira_service, :without_properties_callback, template: true, properties: properties.merge(additional: 'something'))
          end

          it_behaves_like 'service creation from a template'
        end

        context 'when data are stored in separated fields' do
          let(:template) do
            create(:jira_service, :template, data_params.merge(properties: {}, title: title, description: description))
          end

          it_behaves_like 'service creation from a template'
        end

        context 'when data are stored in both properties and separated fields' do
          let(:properties) { data_params.merge(title: title, description: description) }
          let(:template) do
            create(:jira_service, :without_properties_callback, active: true, template: true, properties: properties).tap do |service|
              create(:jira_tracker_data, data_params.merge(service: service))
            end
          end

          it_behaves_like 'service creation from a template'
        end
      end
    end

    describe "for pushover service" do
      let!(:service_template) do
        PushoverService.create(
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
          service = project.find_or_initialize_service('pushover')

          expect(service.template).to eq(false)
          expect(service.device).to eq('MyDevice')
          expect(service.sound).to eq('mic')
          expect(service.priority).to eq(4)
          expect(service.api_key).to eq('123456789')
        end
      end
    end
  end

  describe "{property}_changed?" do
    let(:service) do
      BambooService.create(
        project: create(:project),
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
      service.save
      expect(service.bamboo_url_changed?).to be_falsy
    end
  end

  describe "{property}_touched?" do
    let(:service) do
      BambooService.create(
        project: create(:project),
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
      service.save
      expect(service.bamboo_url_changed?).to be_falsy
    end
  end

  describe "{property}_was" do
    let(:service) do
      BambooService.create(
        project: create(:project),
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
      service.save
      expect(service.bamboo_url_was).to be_nil
    end
  end

  describe 'initialize service with no properties' do
    let(:service) do
      GitlabIssueTrackerService.create(
        project: create(:project),
        title: 'random title',
        project_url: 'http://gitlab.example.com'
      )
    end

    it 'does not raise error' do
      expect { service }.not_to raise_error
    end

    it 'sets title correctly' do
      expect(service.title).to eq('random title')
    end

    it 'sets data correctly' do
      expect(service.data_fields.project_url).to eq('http://gitlab.example.com')
    end
  end

  describe "callbacks" do
    let(:project) { create(:project) }
    let!(:service) do
      RedmineService.new(
        project: project,
        active: true,
        properties: {
          project_url: 'http://redmine/projects/project_name_in_redmine',
          issues_url: "http://redmine/#{project.id}/project_name_in_redmine/:id",
          new_issue_url: 'http://redmine/projects/project_name_in_redmine/issues/new'
        }
      )
    end

    describe "on create" do
      it "updates the has_external_issue_tracker boolean" do
        expect do
          service.save!
        end.to change { service.project.has_external_issue_tracker }.from(false).to(true)
      end
    end

    describe "on update" do
      it "updates the has_external_issue_tracker boolean" do
        service.save!

        expect do
          service.update(active: false)
        end.to change { service.project.has_external_issue_tracker }.from(true).to(false)
      end
    end
  end

  describe '#api_field_names' do
    let(:fake_service) do
      Class.new(Service) do
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
    let(:project) { create(:project) }
    let(:service) { create(:service, project: project) }
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
  end
end
