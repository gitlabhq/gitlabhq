require 'spec_helper'

describe Mattermost::DeployService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user, params) }

  shared_examples 'a 404 response' do
    it 'responds with a 404 message' do
      expect(subject[:response_type]).to be :ephemeral
      expect(subject[:text]).to start_with '404 not found!'
    end
  end

  describe '#execute' do
    let(:params) { { text: 'envname to action' } }
    subject { service.execute }

    context 'when the environment can not be found' do
      it_behaves_like 'a 404 response'
    end

    context 'the environment exists' do
    end
  end
end
