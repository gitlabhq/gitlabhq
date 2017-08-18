require 'spec_helper'

describe PivotaltrackerService do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe 'Execute' do
    let(:service) do
      described_class.new.tap do |service|
        service.token = 'secret_api_token'
      end
    end

    let(:url) { PivotaltrackerService::API_ENDPOINT }

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
      WebMock.stub_request(:post, url)
    end

    it 'should post correct message' do
      service.execute(push_data)
      expect(WebMock).to have_requested(:post, url).with(
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
      let(:service) do
        super().tap do |service|
          service.restrict_to_branch = 'master,v10'
        end
      end

      it 'should post message if branch is in the list' do
        service.execute(push_data(branch: 'master'))
        service.execute(push_data(branch: 'v10'))

        expect(WebMock).to have_requested(:post, url).twice
      end

      it 'should not post message if branch is not in the list' do
        service.execute(push_data(branch: 'mas'))
        service.execute(push_data(branch: 'v11'))

        expect(WebMock).not_to have_requested(:post, url)
      end
    end
  end
end
