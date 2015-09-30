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

describe Ci::HipChatService do

  describe "Validations" do

    context "active" do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :hipchat_room }
      it { is_expected.to validate_presence_of :hipchat_token }

    end
  end

  describe "Execute" do

    let(:service) { Ci::HipChatService.new }
    let(:commit)  { FactoryGirl.create :ci_commit }
    let(:build)   { FactoryGirl.create :ci_build, commit: commit, status: 'failed' }
    let(:api_url) { 'https://api.hipchat.com/v2/room/123/notification?auth_token=a1b2c3d4e5f6' }

    before do
      allow(service).to receive_messages(
        project: commit.project,
        project_id: commit.project_id,
        notify_only_broken_builds: false,
        hipchat_room: 123,
        hipchat_token: 'a1b2c3d4e5f6'
      )

      WebMock.stub_request(:post, api_url)
    end


    it "should call the HipChat API" do
      service.execute(build)
      Ci::HipChatNotifierWorker.drain

      expect( WebMock ).to have_requested(:post, api_url).once
    end

    it "calls the worker with expected arguments" do
      expect( Ci::HipChatNotifierWorker ).to receive(:perform_async) \
        .with(an_instance_of(String), hash_including(
          token: 'a1b2c3d4e5f6',
          room: 123,
          server: 'https://api.hipchat.com',
          color: 'red',
          notify: true
        ))

      service.execute(build)
    end
  end
end
