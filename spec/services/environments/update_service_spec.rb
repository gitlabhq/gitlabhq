# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::UpdateService, feature_category: :environment_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:service) { described_class.new(project, current_user, params) }
  let(:current_user) { developer }
  let(:params) { {} }

  describe '#execute' do
    subject { service.execute(environment) }

    let(:params) { { external_url: 'https://gitlab.com/' } }

    it 'updates the external URL' do
      expect { subject }.to change { environment.reload.external_url }.to('https://gitlab.com/')
    end

    it 'returns successful response' do
      response = subject

      expect(response).to be_success
      expect(response.payload[:environment]).to eq(environment)
    end

    context 'when params contain invalid value' do
      let(:params) { { external_url: 'http://${URL}' } }

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array("External url URI is invalid")
        expect(response.payload[:environment]).to eq(environment)
      end
    end

    context 'when user is reporter' do
      let(:current_user) { reporter }

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to eq('Unauthorized to update the environment')
        expect(response.payload[:environment]).to eq(environment)
      end
    end
  end
end
