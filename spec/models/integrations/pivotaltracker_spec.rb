# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Pivotaltracker, feature_category: :integrations do
  include StubRequests

  describe 'Validations' do
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

  describe 'Execute' do
    let(:integration) do
      described_class.new.tap do |integration|
        integration.token = 'secret_api_token'
      end
    end

    let(:url) { described_class::API_ENDPOINT }

    def push_data(branch: 'master')
      {
        object_kind: 'push',
        ref: "refs/heads/#{branch}",
        commits: [
          {
            id: '21c12ea',
            author: {
              name: 'Some User'
            },
            url: 'https://example.com/commit',
            message: 'commit message'
          }
        ]
      }
    end

    before do
      stub_full_request(url, method: :post)
    end

    it 'posts correct message' do
      integration.execute(push_data)
      expect(WebMock).to have_requested(:post, stubbed_hostname(url)).with(
        body: {
          'source_commit' => {
            'commit_id' => '21c12ea',
            'author' => 'Some User',
            'url' => 'https://example.com/commit',
            'message' => 'commit message'
          }
        },
        headers: {
          'Content-Type' => 'application/json',
          'X-TrackerToken' => 'secret_api_token'
        }
      ).once
    end

    context 'when allowed branches is specified' do
      let(:integration) do
        super().tap do |integration|
          integration.restrict_to_branch = 'master,v10'
        end
      end

      it 'posts message if branch is in the list' do
        integration.execute(push_data(branch: 'master'))
        integration.execute(push_data(branch: 'v10'))

        expect(WebMock).to have_requested(:post, stubbed_hostname(url)).twice
      end

      it 'does not post message if branch is not in the list' do
        integration.execute(push_data(branch: 'mas'))
        integration.execute(push_data(branch: 'v11'))

        expect(WebMock).not_to have_requested(:post, stubbed_hostname(url))
      end
    end
  end

  describe '#avatar_url' do
    it 'returns the avatar image path' do
      expect(subject.avatar_url).to eq(
        ActionController::Base.helpers.image_path(
          'illustrations/third-party-logos/integrations-logos/pivotal-tracker.svg'
        )
      )
    end
  end
end
