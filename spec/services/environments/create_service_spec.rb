# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::CreateService, feature_category: :environment_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }

  let(:service) { described_class.new(project, current_user, params) }
  let(:current_user) { developer }
  let(:params) { {} }

  describe '#execute' do
    subject { service.execute }

    let(:params) { { name: 'production', external_url: 'https://gitlab.com', tier: :production } }

    it 'creates an environment' do
      expect { subject }.to change { ::Environment.count }.by(1)
    end

    it 'returns successful response' do
      response = subject

      expect(response).to be_success
      expect(response.payload[:environment].name).to eq('production')
      expect(response.payload[:environment].external_url).to eq('https://gitlab.com')
      expect(response.payload[:environment].tier).to eq('production')
    end

    context 'when params contain invalid value' do
      let(:params) { { name: 'production', external_url: 'http://${URL}' } }

      it 'does not create an environment' do
        expect { subject }.not_to change { ::Environment.count }
      end

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array("External url URI is invalid")
        expect(response.payload[:environment]).to be_nil
      end
    end

    context 'when user is reporter' do
      let(:current_user) { reporter }

      it 'does not create an environment' do
        expect { subject }.not_to change { ::Environment.count }
      end

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to eq('Unauthorized to create an environment')
        expect(response.payload[:environment]).to be_nil
      end
    end
  end
end
