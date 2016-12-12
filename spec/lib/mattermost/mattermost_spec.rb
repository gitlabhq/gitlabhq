require 'spec_helper'

describe Mattermost::Mattermost do
  let(:user) { create(:user) }

  subject { described_class.new('http://localhost:8065', user) }

  # Needed for doorman to function
  it { is_expected.to respond_to(:current_resource_owner) }
  it { is_expected.to respond_to(:request) }
  it { is_expected.to respond_to(:authorization) }
  it { is_expected.to respond_to(:strategy) }

  describe '#with session' do
    let!(:stub) do
      WebMock.stub_request(:get, 'http://localhost:8065/api/v3/oauth/gitlab/login').
        to_return(headers: { 'location' => 'http://mylocation.com' }, status: 307)
    end

    context 'without oauth uri' do
      it 'makes a request to the oauth uri' do
        expect { subject.with_session }.to raise_error(Mattermost::NoSessionError)
      end

      context 'with oauth_uri' do
        let!(:doorkeeper) do
          Doorkeeper::Application.create(name: "GitLab Mattermost",
                                         redirect_uri: "http://localhost:8065/signup/gitlab/complete\nhttp://localhost:8065/login/gitlab/complete",
                                         scopes: "")
        end

        context 'without token_uri' do
          it 'can not create a session' do
            expect do
              subject.with_session
            end.to raise_error(Mattermost::NoSessionError)
          end
        end
      end
    end
  end
end
