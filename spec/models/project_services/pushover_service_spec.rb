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

describe PushoverService, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :api_key }
      it { is_expected.to validate_presence_of :user_key }
      it { is_expected.to validate_presence_of :priority }
    end
  end

  describe 'Execute' do
    let(:pushover) { PushoverService.new }
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

    let(:api_key) { 'verySecret' }
    let(:user_key) { 'verySecret' }
    let(:device) { 'myDevice' }
    let(:priority) { 0 }
    let(:sound) { 'bike' }
    let(:api_url) { 'https://api.pushover.net/1/messages.json' }

    before do
      allow(pushover).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        api_key: api_key,
        user_key: user_key,
        device: device,
        priority: priority,
        sound: sound
      )

      WebMock.stub_request(:post, api_url)
    end

    it 'should call Pushover API' do
      pushover.execute(sample_data)

      expect(WebMock).to have_requested(:post, api_url).once
    end
  end
end
