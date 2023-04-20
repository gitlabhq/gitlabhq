# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::Collaborator, feature_category: :importers do
  shared_examples 'a Collaborator' do
    it 'returns an instance of Collaborator' do
      expect(collaborator).to be_an_instance_of(described_class)
    end

    context 'with Collaborator' do
      it 'includes the user ID' do
        expect(collaborator.id).to eq(42)
      end

      it 'includes the username' do
        expect(collaborator.login).to eq('alice')
      end

      it 'includes the role' do
        expect(collaborator.role_name).to eq('maintainer')
      end

      describe '#github_identifiers' do
        it 'returns a hash with needed identifiers' do
          expect(collaborator.github_identifiers).to eq(
            {
              id: 42,
              login: 'alice'
            }
          )
        end
      end
    end
  end

  describe '.from_api_response' do
    it_behaves_like 'a Collaborator' do
      let(:response) { { id: 42, login: 'alice', role_name: 'maintainer' } }
      let(:collaborator) { described_class.from_api_response(response) }
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a Collaborator' do
      let(:hash) { { 'id' => 42, 'login' => 'alice', role_name: 'maintainer' } }
      let(:collaborator) { described_class.from_json_hash(hash) }
    end
  end
end
