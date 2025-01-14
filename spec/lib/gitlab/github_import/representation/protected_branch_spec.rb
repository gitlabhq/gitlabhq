# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::ProtectedBranch, feature_category: :importers do
  shared_examples 'a ProtectedBranch rule' do
    it 'returns an instance of ProtectedBranch' do
      expect(protected_branch).to be_an_instance_of(described_class)
    end

    context 'with ProtectedBranch' do
      it 'includes the protected branch ID (name) attribute' do
        expect(protected_branch.id).to eq 'main'
      end

      it 'includes the protected branch allow_force_pushes attribute' do
        expect(protected_branch.allow_force_pushes).to eq true
      end

      it 'includes the protected branch required_conversation_resolution attribute' do
        expect(protected_branch.required_conversation_resolution).to eq true
      end

      it 'includes the protected branch required_pull_request_reviews' do
        expect(protected_branch.required_pull_request_reviews).to eq true
      end

      it 'includes the protected branch require_code_owner_reviews' do
        expect(protected_branch.require_code_owner_reviews).to eq true
      end

      it 'includes the protected branch allowed_to_push_users' do
        expect(protected_branch.allowed_to_push_users[0])
          .to be_an_instance_of(Gitlab::GithubImport::Representation::User)

        expect(protected_branch.allowed_to_push_users[0].id).to eq(4)
        expect(protected_branch.allowed_to_push_users[0].login).to eq('alice')
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      response = Struct.new(
        :url, :allow_force_pushes, :required_conversation_resolution, :required_signatures,
        :required_pull_request_reviews,
        keyword_init: true
      )
      enabled_setting = Struct.new(:enabled, keyword_init: true)
      required_pull_request_reviews = Struct.new(
        :url, :dismissal_restrictions, :require_code_owner_reviews, :bypass_pull_request_allowances,
        keyword_init: true
      )
      response.new(
        url: 'https://example.com/branches/main/protection',
        allow_force_pushes: enabled_setting.new(
          enabled: true
        ),
        required_conversation_resolution: enabled_setting.new(
          enabled: true
        ),
        required_signatures: enabled_setting.new(
          enabled: true
        ),
        required_pull_request_reviews: required_pull_request_reviews.new(
          url: 'https://example.com/branches/main/protection/required_pull_request_reviews',
          dismissal_restrictions: {},
          require_code_owner_reviews: true,
          bypass_pull_request_allowances: {
            users: [
              {
                login: 'alice',
                id: 4,
                url: 'https://api.github.com/users/cervols',
                type: 'User'
              }
            ]
          }
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
          'allow_force_pushes' => true,
          'required_conversation_resolution' => true,
          'required_signatures' => true,
          'required_pull_request_reviews' => true,
          'require_code_owner_reviews' => true,
          'allowed_to_push_users' => [{ 'id' => 4, 'login' => 'alice' }]
        }
      end

      let(:protected_branch) { described_class.from_json_hash(hash) }
    end
  end
end
