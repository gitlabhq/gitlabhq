# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Campfire, feature_category: :integrations do
  include StubRequests

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { described_class.new }
  end

  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    it { is_expected.to validate_numericality_of(:room).is_greater_than(0).only_integer }
    it { is_expected.to validate_length_of(:subdomain).is_at_least(1).is_at_most(63).allow_blank }
    it { is_expected.to allow_value("foo").for(:subdomain) }
    it { is_expected.not_to allow_value("foo.bar").for(:subdomain) }
    it { is_expected.not_to allow_value("foo.bar/#").for(:subdomain) }

    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe "#execute" do
    let(:user)    { build_stubbed(:user) }
    let(:project) { build_stubbed(:project, :repository) }

    before do
      @campfire_integration = described_class.new
      allow(@campfire_integration).to receive_messages(
        project_id: project.id,
        project: project,
        token: 'verySecret',
        subdomain: 'project-name',
        room: 'test-room'
      )
      @sample_data = Gitlab::DataBuilder::Push.build_sample(project, user)
      @rooms_url = 'https://project-name.campfirenow.com/rooms.json'
      @auth = %w[verySecret X]
      @headers = { 'Content-Type' => 'application/json; charset=utf-8' }
    end

    it "calls Campfire API to get a list of rooms and speak in a room" do
      # make sure a valid list of rooms is returned
      body = File.read(Rails.root + 'spec/fixtures/integrations/campfire/rooms.json')

      stub_full_request(@rooms_url).with(basic_auth: @auth).to_return(
        body: body,
        status: 200,
        headers: @headers
      )

      # stub the speak request with the room id found in the previous request's response
      speak_url = 'https://project-name.campfirenow.com/room/123/speak.json'
      stub_full_request(speak_url, method: :post).with(basic_auth: @auth)

      @campfire_integration.execute(@sample_data)

      expect(WebMock).to have_requested(:get, stubbed_hostname(@rooms_url)).once
      expect(WebMock).to have_requested(:post, stubbed_hostname(speak_url))
                           .with(body: /#{project.path}.*#{@sample_data[:before]}.*#{@sample_data[:after]}/).once
    end

    it "calls Campfire API to get a list of rooms but shouldn't speak in a room" do
      # return a list of rooms that do not contain a room named 'test-room'
      body = File.read(Rails.root + 'spec/fixtures/integrations/campfire/rooms2.json')
      stub_full_request(@rooms_url).with(basic_auth: @auth).to_return(
        body: body,
        status: 200,
        headers: @headers
      )

      @campfire_integration.execute(@sample_data)

      expect(WebMock).to have_requested(:get, 'https://8.8.8.9/rooms.json').once
      expect(WebMock).not_to have_requested(:post, '*/room/.*/speak.json')
    end
  end

  describe '#log_error' do
    subject { described_class.new.log_error('error') }

    it 'logs an error' do
      expect(Gitlab::IntegrationsLogger).to receive(:error).with(
        hash_including(integration_class: 'Integrations::Campfire', message: 'error')
      ).and_call_original

      is_expected.to be_truthy
    end
  end
end
