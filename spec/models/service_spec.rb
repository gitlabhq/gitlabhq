# frozen_string_literal: true

require 'spec_helper'

describe Service do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
    it { is_expected.to have_one :jira_tracker_data }
    it { is_expected.to have_one :issue_tracker_data }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:type) }
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
      let(:service) { create(:service, project: project) }

      context 'when repository is not empty' do
        let(:project) { create(:project, :repository) }

        it 'returns true' do
          expect(service.can_test?).to be true
        end
      end

      context 'when repository is empty' do
        let(:project) { create(:project) }

        it 'returns true' do
          expect(service.can_test?).to be true
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

  describe "Template" do
    let(:project) { create(:project) }

    describe '.build_from_template' do
      context 'when template is invalid' do
        it 'sets service template to inactive when template is invalid' do
          template = build(:prometheus_service, template: true, active: true, properties: {})
          template.save(validate: false)

          service = described_class.build_from_template(project.id, template)

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
            service = described_class.build_from_template(project.id, template)

            expect(service).to be_active
            expect(service.title).to eq(title)
            expect(service.description).to eq(description)
            expect(service.url).to eq(url)
            expect(service.api_url).to eq(api_url)
            expect(service.username).to eq(username)
            expect(service.password).to eq(password)
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
            create(:jira_service, data_params.merge(properties: {}, title: title, description: description, template: true))
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

  describe "#deprecated?" do
    let(:project) { create(:project, :repository) }

    it 'returns false by default' do
      service = create(:service, project: project)
      expect(service.deprecated?).to be_falsy
    end
  end

  describe "#deprecation_message" do
    let(:project) { create(:project, :repository) }

    it 'is empty by default' do
      service = create(:service, project: project)
      expect(service.deprecation_message).to be_nil
    end
  end

  describe '.find_by_template' do
    let!(:service) { create(:service, template: true) }

    it 'returns service template' do
      expect(described_class.find_by_template).to eq(service)
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
