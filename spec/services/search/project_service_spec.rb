# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ProjectService, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#allowed_scopes' do
    subject(:service) { described_class.new(user, project, search: 'test') }

    it 'returns scopes from Search::Scopes registry' do
      expect(Search::Scopes).to receive(:available_for_context)
        .with(hash_including(context: :project, container: project, requested_search_type: nil))

      service.allowed_scopes
    end

    it 'passes search_type parameter to Search::Scopes' do
      service_with_type = described_class.new(user, project, search: 'test', search_type: 'advanced')

      expect(Search::Scopes).to receive(:available_for_context)
        .with(hash_including(context: :project, container: project, requested_search_type: 'advanced'))

      service_with_type.allowed_scopes
    end

    context 'when search_scope_registry feature flag is disabled' do
      before do
        stub_feature_flags(search_scope_registry: false)
      end

      it 'returns legacy allowed scopes' do
        result = service.allowed_scopes
        expect(result).to eq(described_class::LEGACY_ALLOWED_SCOPES)
        expect(result).to include('blobs', 'commits', 'issues', 'merge_requests', 'wiki_blobs')
      end
    end
  end
end
