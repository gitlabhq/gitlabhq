# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Scopes, feature_category: :global_search do
  describe '.all_scope_names' do
    it 'returns all defined scope names as strings' do
      scope_names = described_class.all_scope_names

      expect(scope_names).to include('blobs', 'issues', 'merge_requests', 'projects', 'users')
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
      expect(scopes).to include('projects', 'issues')
    end

    it 'receives nil container from GlobalService.searched_container' do
      service = Search::GlobalService.new(user, search: 'test')

      # This will internally call searched_container which returns nil
      scopes = service.allowed_scopes

      # Verify the scopes are correct for global search (no container)
      expect(scopes).to include('projects', 'issues', 'merge_requests')
      expect(scopes).not_to include('blobs') # blobs require advanced search at global level
    end
  end

  describe '.available_for_context' do
    context 'for global context' do
      it 'returns scopes available for global search' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :basic)

        expect(scopes).to include('issues', 'merge_requests', 'milestones', 'projects', 'users')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'for project context' do
      it 'returns scopes available for project search' do
        scopes = described_class.available_for_context(context: :project, requested_search_type: :basic)

        expect(scopes).to include('blobs', 'issues', 'merge_requests', 'wiki_blobs', 'commits', 'notes', 'milestones',
          'users')
        expect(scopes).not_to include('projects', 'snippet_titles') # not available in project context
      end
    end

    context 'for group context' do
      it 'returns scopes available for group search with basic' do
        scopes = described_class.available_for_context(context: :group, requested_search_type: :basic)

        expect(scopes).to include('issues', 'merge_requests', 'milestones', 'projects', 'users')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'when global search is disabled for scope' do
      before do
        stub_application_setting(global_search_issues_enabled: false)
      end

      it 'excludes the scope from available scopes' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :basic)

        expect(scopes).to include('merge_requests', 'milestones', 'projects', 'users')
        expect(scopes).not_to include('issues')
      end
    end

    context 'when requested_search_type is not basic or blank' do
      it 'excludes scopes for advanced search type in CE' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :advanced)
        # In CE without advanced search, no scopes should be available for advanced type
        expect(scopes).to be_empty
      end

      it 'excludes scopes for zoekt search type in CE' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: :zoekt)
        # In CE without zoekt, no scopes should be available for zoekt type
        expect(scopes).to be_empty
      end
    end

    context 'when requested_search_type is basic as string' do
      it 'includes scopes when explicitly requesting basic as string' do
        scopes = described_class.available_for_context(context: :global, requested_search_type: 'basic')
        expect(scopes).to include('issues', 'merge_requests', 'milestones', 'projects', 'users')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end

    context 'when requested_search_type is blank' do
      it 'includes scopes that support basic search by default' do
        scopes = described_class.available_for_context(context: :global)
        expect(scopes).to include('issues', 'merge_requests', 'milestones', 'projects', 'users')
        expect(scopes).not_to include('blobs', 'commits', 'notes', 'wiki_blobs')
      end
    end
  end

  describe '.hidden_by_work_item_scope?' do
    let(:user) { build(:user) }

    context 'when user is nil' do
      it 'returns false' do
        expect(described_class.hidden_by_work_item_scope?(:issues, nil)).to be false
      end
    end

    context 'when work_item_scope_frontend feature flag is disabled' do
      before do
        stub_feature_flags(work_item_scope_frontend: false)
      end

      it 'returns false for issues scope' do
        expect(described_class.hidden_by_work_item_scope?(:issues, user)).to be false
      end

      it 'returns false for epics scope' do
        expect(described_class.hidden_by_work_item_scope?(:epics, user)).to be false
      end

      it 'returns false for other scopes' do
        expect(described_class.hidden_by_work_item_scope?(:projects, user)).to be false
      end
    end

    it 'returns true for issues scope' do
      expect(described_class.hidden_by_work_item_scope?(:issues, user)).to be true
    end

    it 'returns true for epics scope' do
      expect(described_class.hidden_by_work_item_scope?(:epics, user)).to be true
    end

    it 'returns false for other scopes' do
      expect(described_class.hidden_by_work_item_scope?(:projects, user)).to be false
      expect(described_class.hidden_by_work_item_scope?(:merge_requests, user)).to be false
      expect(described_class.hidden_by_work_item_scope?(:blobs, user)).to be false
    end
  end
end
