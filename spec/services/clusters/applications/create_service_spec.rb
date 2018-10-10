# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::CreateService do
  let(:cluster) { create(:cluster) }
  let(:user) { create(:user) }
  let(:params) { { application: 'helm' } }
  let(:service) { described_class.new(cluster, user, params) }

  let(:request) do
    if Gitlab.rails5?
      ActionController::TestRequest.new({ remote_ip: "127.0.0.1" }, ActionController::TestSession.new)
    else
      ActionController::TestRequest.new(remote_ip: "127.0.0.1")
    end
  end

  describe '#execute' do
    subject { service.execute(request) }

    it 'creates an application' do
      expect do
        subject

        cluster.reload
      end.to change(cluster, :application_helm)
    end

    context 'jupyter application' do
      let(:params) do
        {
          application: 'jupyter',
          hostname: 'example.com'
        }
      end

      it 'creates the application' do
        expect do
          subject

          cluster.reload
        end.to change(cluster, :application_jupyter)
      end

      it 'sets the hostname' do
        expect(subject.hostname).to eq('example.com')
      end

      it 'sets the oauth_application' do
        expect(subject.oauth_application).to be_present
      end
    end

    context 'invalid application' do
      let(:params) { { application: 'non-existent' } }

      it 'raises an error' do
        expect { subject }.to raise_error(Clusters::Applications::CreateService::InvalidApplicationError)
      end
    end
  end
end
