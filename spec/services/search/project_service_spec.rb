# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ProjectService, :with_current_organization, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    it 'passes organization_id to ProjectSearchResults' do
      expect(Gitlab::ProjectSearchResults).to receive(:new).with(
        anything,
        anything,
        hash_including(organization_id: current_organization.id)
      ).and_call_original

      described_class.new(user, project, search: 'test', organization_id: current_organization.id).execute
    end
  end

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
  end
end
