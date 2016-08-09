# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'

describe GemnasiumService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:api_key) }
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:api_key) }
    end
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    before do
      @gemnasium_service = GemnasiumService.new
      allow(@gemnasium_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret',
        api_key: 'GemnasiumUserApiKey'
      )
      @sample_data = Gitlab::PushDataBuilder.build_sample(project, user)
    end
    it "calls Gemnasium service" do
      expect(Gemnasium::GitlabService).to receive(:execute).with(an_instance_of(Hash)).once
      @gemnasium_service.execute(@sample_data)
    end
  end
end
