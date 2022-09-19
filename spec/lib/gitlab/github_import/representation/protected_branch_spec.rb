# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::ProtectedBranch do
  shared_examples 'a ProtectedBranch rule' do
    it 'returns an instance of ProtectedBranch' do
      expect(protected_branch).to be_an_instance_of(described_class)
    end

    context 'with ProtectedBranch' do
      it 'includes the protected branch ID (name)' do
        expect(protected_branch.id).to eq 'main'
      end

      it 'includes the protected branch allow_force_pushes' do
        expect(protected_branch.allow_force_pushes).to eq true
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      response = Struct.new(:url, :allow_force_pushes, keyword_init: true)
      allow_force_pushes = Struct.new(:enabled, keyword_init: true)
      response.new(
        url: 'https://example.com/branches/main/protection',
        allow_force_pushes: allow_force_pushes.new(
          enabled: true
        )
      )
    end

    it_behaves_like 'a ProtectedBranch rule' do
      let(:protected_branch) { described_class.from_api_response(response) }
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a ProtectedBranch rule' do
      let(:hash) do
        {
          'id' => 'main',
          'allow_force_pushes' => true
        }
      end

      let(:protected_branch) { described_class.from_json_hash(hash) }
    end
  end
end
