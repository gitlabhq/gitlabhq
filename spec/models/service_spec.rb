require 'spec_helper'

describe Service, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Mass assignment" do
  end

  describe "Test Button" do
    before do
      @service = Service.new
    end

    describe "Testable" do
      let(:project) { create :project }

      before do
        allow(@service).to receive(:project).and_return(project)
        @testable = @service.can_test?
      end

      describe '#can_test?' do
        it { expect(@testable).to eq(true) }
      end

      describe '#test' do
        let(:data) { 'test' }

        it 'test runs execute' do
          expect(@service).to receive(:execute).with(data)

          @service.test(data)
        end
      end
    end

    describe "With commits" do
      let(:project) { create :project }

      before do
        allow(@service).to receive(:project).and_return(project)
        @testable = @service.can_test?
      end

      describe '#can_test?' do
        it { expect(@testable).to eq(true) }
      end
    end
  end

  describe "Available services" do
    it { expect(Service.available_services_names).to  include("jenkins", "jira")}
  end

  describe "Template" do
    describe "for pushover service" do
      let(:service_template) do
        PushoverService.create(
          template: true,
          properties: {
            device: 'MyDevice',
            sound: 'mic',
            priority: 4,
            api_key: '123456789'
          })
      end
      let(:project) { create(:project) }

      describe 'should be prefilled for projects pushover service' do
        before do
          service_template
          project.build_missing_services
        end

        it "should have all fields prefilled" do
          service = project.pushover_service
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
        end.to change { service.project.has_external_issue_tracker }.from(nil).to(true)
      end
    end

    describe "on update" do
      it "updates the has_external_issue_tracker boolean" do
        service.save!

        expect do
          service.update_attributes(active: false)
        end.to change { service.project.has_external_issue_tracker }.from(true).to(false)
      end
    end
  end
end
