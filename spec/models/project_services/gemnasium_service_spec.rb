require 'spec_helper'

describe GemnasiumService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:api_key) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:api_key) }
    end
  end

  describe "deprecated?" do
    let(:project) { create(:project, :repository) }
    let(:gemnasium_service) { described_class.new }

    before do
      allow(gemnasium_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret',
        api_key: 'GemnasiumUserApiKey'
      )
    end

    it "is true" do
      expect(gemnasium_service.deprecated?).to be true
    end

    it "can't create a new service" do
      expect(gemnasium_service.save).to be false
      expect(gemnasium_service.errors[:base].first)
        .to eq('Gemnasium has been acquired by GitLab in January 2018. Since May 15, 2018, the service provided by Gemnasium is no longer available.')
    end
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:gemnasium_service) { described_class.new }
    let(:sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }

    before do
      allow(gemnasium_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret',
        api_key: 'GemnasiumUserApiKey'
      )
    end
    it "calls Gemnasium service" do
      expect(Gemnasium::GitlabService).to receive(:execute).with(an_instance_of(Hash)).once
      gemnasium_service.execute(sample_data)
    end
  end
end
