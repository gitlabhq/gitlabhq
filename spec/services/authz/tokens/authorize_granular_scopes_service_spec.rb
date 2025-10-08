# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::Tokens::AuthorizeGranularScopesService, feature_category: :permissions do
  let_it_be(:boundary) { Authz::Boundary.for(nil) }
  let_it_be(:granular_pat) { create(:granular_pat, namespace: boundary.namespace, permissions: :create_issue) }
  let_it_be(:token) { granular_pat }
  let_it_be(:permissions) { :create_issue }

  subject(:service) { described_class.new(boundary:, permissions:, token:) }

  before do
    allow(Authz::Permission).to receive(:all).and_return(create_issue: nil, create_epic: nil, create_project: nil)
  end

  shared_examples 'successful response' do
    it 'returns ServiceResponse.success' do
      result = service.execute

      expect(result).to be_a(ServiceResponse)
      expect(result.success?).to be(true)
    end
  end

  shared_examples 'error response' do |message|
    it 'returns ServiceResponse.error' do
      result = service.execute

      expect(result).to be_a(ServiceResponse)
      expect(result.error?).to be(true)
      expect(result.message).to eq(message)
    end
  end

  describe '#initialize' do
    context 'when the passed boundary is not an Authz::Boundary' do
      let(:boundary) { build(:project) }

      it 'raises an InvalidInputError error' do
        expect { service }.to raise_error(Authz::Tokens::AuthorizeGranularScopesService::InvalidInputError,
          'Boundary must be an instance of Authz::Boundary::Base, got Project')
      end
    end

    context 'when the passed permissions are not valid' do
      let(:permissions) { [:a, :b, :create_issue] }

      it 'raises an InvalidInputError error' do
        expect { service }.to raise_error(Authz::Tokens::AuthorizeGranularScopesService::InvalidInputError,
          'Invalid permissions: a, b')
      end
    end
  end

  describe '#execute' do
    it_behaves_like 'successful response'

    context 'when the `authorize_granular_pats` feature flag is disabled' do
      before do
        stub_feature_flags(authorize_granular_pats: false)
      end

      it_behaves_like 'error response', 'Granular tokens are not yet supported'
    end

    context 'when the token is missing' do
      let(:token) { nil }

      it_behaves_like 'successful response'
    end

    context 'when the boundary is missing' do
      let(:boundary) { nil }

      it_behaves_like 'error response', 'Unable to determine boundary for authorization'
    end

    context 'when permissions are missing' do
      let(:permissions) { nil }

      it_behaves_like 'error response', 'Unable to determine permissions for authorization'
    end

    context 'when the token does not support fine-grained permissions' do
      let(:token) { build(:oauth_access_token) }

      it_behaves_like 'successful response'
    end

    context 'when the token is supported, but is not granular' do
      let(:token) { build(:personal_access_token) }

      it_behaves_like 'successful response'

      context 'when the namespace requires granular tokens' do
        before do
          allow(service).to receive(:granular_token_required?).and_return(true)
        end

        it_behaves_like 'error response', 'Access denied: Your Personal Access Token lacks the required permissions: ' \
          '[create_issue].'
      end
    end

    context 'when the token does not have the required permissions' do
      let_it_be(:permissions) { [:create_issue, :create_epic, :create_project] }

      it_behaves_like 'error response', 'Access denied: Your Personal Access Token lacks the required permissions: ' \
        '[create_epic, create_project].'
    end
  end
end
