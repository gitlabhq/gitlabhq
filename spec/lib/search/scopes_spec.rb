# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Scopes, feature_category: :global_search do
  describe '.all_scope_names' do
    it 'returns all defined scope names as strings' do
      scope_names = described_class.all_scope_names

      expect(scope_names).to include('blobs', 'merge_requests', 'projects', 'users', 'work_items')
      expect(scope_names).to all(be_a(String))
    end
  end

  describe 'integration with Search::GlobalService' do
    let(:user) { build(:user) }

    it 'is used by GlobalService to determine available scopes' do
      service = Search::GlobalService.new(user, search: 'test')

      # GlobalService calls available_for_context with container: nil (from searched_container)
      expect(described_class).to receive(:available_for_context).with(
        context: :global,
        container: nil,
        requested_search_type: nil
      ).and_call_original

      scopes = service.allowed_scopes
      expect(scopes).to be_an(Array)
      expect(scopes).to include('projects', 'work_items')
    end

    it 'receives nil container from GlobalService.searched_container' do
      service = Search::GlobalService.new(user, search: 'test')

      # This will internally call searched_container which returns nil
      scopes = service.allowed_scopes

      # Verify the scopes are correct for global search (no container)
      expect(scopes).to include('projects', 'merge_requests', 'work_items')
      expect(scopes).not_to include('blobs') # blobs require advanced search at global level
    end
  end

  describe '.available_for_context' do
    context 'for global context' do
      it 'returns scopes available for global search' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :basic)

        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'users', 'work_items')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'for project context' do
      it 'returns scopes available for project search' do
        scopes = described_class.available_for_context(context: :project, requested_search_type: :basic)

        expect(scopes).to include(
          'blobs', 'commits', 'merge_requests', 'milestones', 'notes', 'users', 'wiki_blobs', 'work_items'
        )
        expect(scopes).not_to include('projects', 'snippet_titles') # not available in project context
      end
    end

    context 'for group context' do
      it 'returns scopes available for group search with basic' do
        scopes = described_class.available_for_context(context: :group, requested_search_type: :basic)

        expect(scopes).to include('work_items', 'merge_requests', 'milestones', 'projects', 'users')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'when global search is disabled for scope' do
      before do
        stub_application_setting(global_search_work_items_enabled: false)
      end

      it 'excludes the scope from available scopes' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :basic)

        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'users')
        expect(scopes).not_to include('work_items')
      end
    end

    context 'when requested_search_type is not basic or blank', unless: Gitlab.ee? do
      it 'includes scopes available for basic search when advanced search type is requested in CE' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :advanced)
        # In CE, when advanced is requested, fall back to basic search scopes
        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'snippet_titles', 'users', 'work_items')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end

      it 'includes scopes available for basic search when zoekt search type is requested in CE' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :zoekt)
        # In CE, when zoekt is requested, fall back to basic search scopes
        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'snippet_titles', 'users', 'work_items')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'when requested_search_type is basic as string' do
      it 'includes scopes when explicitly requesting basic as string' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: 'basic')
        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'users', 'work_items')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end

      it 'includes scopes when requesting basic as symbol' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :basic)
        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'users', 'work_items')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'when requested_search_type is blank' do
      it 'includes scopes that support basic search by default' do
        scopes = described_class.available_for_context(context: :global)
        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'users', 'work_items')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end

      it 'includes scopes when explicitly passing nil' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: nil)
        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'users', 'work_items')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'when requested_search_type is invalid' do
      it 'treats invalid search_type as if no search_type was specified to allow scope determination' do
        result = described_class.available_for_context(context: :project, requested_search_type: 'invalid_xyz')

        # Should not be empty - allows scope determination to work
        # The actual validation error will be shown by search_type_errors
        expect(result).to include('blobs', 'merge_requests', 'work_items')
      end

      it 'allows scope determination for global context with invalid search_type' do
        result = described_class.available_for_context(context: :global, requested_search_type: 'xyz')

        expect(result).to include('merge_requests', 'projects', 'work_items')
      end
    end
  end

  describe '.scope_definitions' do
    it 'returns all scope definitions with required keys' do
      scope_definitions = described_class.scope_definitions

      described_class::API_ONLY_SCOPES.each_key do |key|
        definition = scope_definitions[key]
        expect(definition).to have_key(:availability)
        expect(definition[:availability]).to be_a(Hash)
      end

      described_class::SCOPE_DEFINITIONS.each_key do |key|
        definition = scope_definitions[key]
        expect(definition).to have_key(:availability)
        expect(definition[:label]).to be_a(Proc)
        expect(definition[:label].call).to be_a(String)
        expect(definition[:sort]).to be_a(Integer)
        expect(definition[:availability]).to be_a(Hash)
      end
    end

    it 'excludes API-only scopes when requested' do
      definitions = described_class.scope_definitions(include_api_only: false)

      expect(definitions).not_to have_key(:issues)
      expect(definitions).to have_key(:work_items)
    end

    it 'includes API-only scopes by default' do
      definitions = described_class.scope_definitions

      expect(definitions).to have_key(:issues)
    end
  end
end
