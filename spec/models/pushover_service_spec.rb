# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'spec_helper'

describe PushoverService do
  describe 'Associations' do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe 'Validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { should validate_presence_of :api_key }
      it { should validate_presence_of :user_key }
      it { should validate_presence_of :priority }
    end
  end

  describe 'Execute' do
    let(:pushover) { PushoverService.new }
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:sample_data) { GitPushService.new.sample_data(project, user) }

    let(:api_key) { 'verySecret' }
    let(:user_key) { 'verySecret' }
    let(:device) { 'myDevice' }
    let(:priority) { 0 }
    let(:sound) { 'bike' }
    let(:api_url) { 'https://api.pushover.net/1/messages.json' }

    before do
      pushover.stub(
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

      WebMock.should have_requested(:post, api_url).once
    end
  end
end
