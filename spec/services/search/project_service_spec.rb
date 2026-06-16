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

  describe '#scope' do
    let_it_be(:private_project) { create(:project, :private) }

    subject(:resolved_scope) { described_class.new(member, private_project, params).scope }

    context 'when the user can access the requested scope' do
      let_it_be(:member) { create(:user, developer_of: private_project) }

      let(:params) { { search: 'test', scope: 'blobs' } }

      it 'returns the requested scope' do
        expect(resolved_scope).to eq('blobs')
      end
    end

    context 'when the user cannot access the requested scope' do
      let_it_be(:member) { create(:user, guest_of: private_project) }

      let(:params) { { search: 'test', scope: 'blobs' } }

      it 'falls back to the first scope the user can access' do
        expect(resolved_scope).to eq('work_items')
      end
    end

    context 'when a custom default search scope is configured and accessible' do
      let_it_be(:member) { create(:user, developer_of: private_project) }

      let(:params) { { search: 'test', scope: 'projects' } }

      before do
        stub_application_setting(default_search_scope: 'merge_requests')
      end

      it 'returns the configured default scope' do
        expect(resolved_scope).to eq('merge_requests')
      end
    end
  end
end
