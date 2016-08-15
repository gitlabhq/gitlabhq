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

describe CampfireService, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:token) }
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe "#execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    before do
      @campfire_service = CampfireService.new
      allow(@campfire_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret',
        subdomain: 'project-name',
        room: 'test-room'
      )
      @sample_data = Gitlab::PushDataBuilder.build_sample(project, user)
      @rooms_url = 'https://verySecret:X@project-name.campfirenow.com/rooms.json'
      @headers = { 'Content-Type' => 'application/json; charset=utf-8' }
    end

    it "calls Campfire API to get a list of rooms and speak in a room" do
      # make sure a valid list of rooms is returned
      body = File.read(Rails.root + 'spec/fixtures/project_services/campfire/rooms.json')
      WebMock.stub_request(:get, @rooms_url).to_return(
        body: body,
        status: 200,
        headers: @headers
      )
      # stub the speak request with the room id found in the previous request's response
      speak_url = 'https://verySecret:X@project-name.campfirenow.com/room/123/speak.json'
      WebMock.stub_request(:post, speak_url)

      @campfire_service.execute(@sample_data)

      expect(WebMock).to have_requested(:get, @rooms_url).once
      expect(WebMock).to have_requested(:post, speak_url).with(
        body: /#{project.path}.*#{@sample_data[:before]}.*#{@sample_data[:after]}/
      ).once
    end

    it "calls Campfire API to get a list of rooms but shouldn't speak in a room" do
      # return a list of rooms that do not contain a room named 'test-room'
      body = File.read(Rails.root + 'spec/fixtures/project_services/campfire/rooms2.json')
      WebMock.stub_request(:get, @rooms_url).to_return(
        body: body,
        status: 200,
        headers: @headers
      )
      # we want to make sure no request is sent to the /speak endpoint, here is a basic
      # regexp that matches this endpoint
      speak_url = 'https://verySecret:X@project-name.campfirenow.com/room/.*/speak.json'

      @campfire_service.execute(@sample_data)

      expect(WebMock).to have_requested(:get, @rooms_url).once
      expect(WebMock).not_to have_requested(:post, /#{speak_url}/)
    end
  end
end
