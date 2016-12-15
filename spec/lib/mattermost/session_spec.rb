require 'spec_helper'

describe Mattermost::Session do
  let(:user) { create(:user) }

  subject { described_class.new('http://localhost:8065', user) }

  # Needed for doorkeeper to function
  it { is_expected.to respond_to(:current_resource_owner) }
  it { is_expected.to respond_to(:request) }
  it { is_expected.to respond_to(:authorization) }
  it { is_expected.to respond_to(:strategy) }

  describe '#with session' do
    let(:location) { 'http://location.tld' }
    let!(:stub) do
      WebMock.stub_request(:get, 'http://localhost:8065/api/v3/oauth/gitlab/login').
        to_return(headers: { 'location' => location }, status: 307)
    end

    context 'without oauth uri' do
      it 'makes a request to the oauth uri' do
        expect { subject.with_session }.to raise_error(Mattermost::NoSessionError)
      end
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

      context 'with token_uri' do
        let(:state) { "eyJhY3Rpb24iOiJsb2dpbiIsImhhc2giOiIkMmEkMTAkVC9wYVlEaTdIUS8vcWdKRmdOOUllZUptaUNJWUlvNVNtNEcwU2NBMXFqelNOVmVPZ1cxWUsifQ%3D%3D" }
        let(:location) { "http://locahost:8065/oauth/authorize?response_type=code&client_id=#{doorkeeper.uid}&redirect_uri=http%3A%2F%2Flocalhost:8065%2Fsignup%2Fgitlab%2Fcomplete&state=#{state}" }

        before do
          WebMock.stub_request(:get, /http:\/\/localhost:8065\/signup\/gitlab\/complete*/).
            to_return(headers: { 'token' => 'thisworksnow' }, status: 202)
        end

        it 'can setup a session' do
          expect(subject).to receive(:destroy)

          subject.with_session { 1 + 1 }
        end

        it 'returns the value of the block' do
          WebMock.stub_request(:post, "http://localhost:8065/api/v3/users/logout").
            to_return(headers: { 'token' => 'thisworksnow' }, status: 200)

          value = subject.with_session { 1 + 1 }

          expect(value).to be(2)
        end
      end
    end
  end
end
