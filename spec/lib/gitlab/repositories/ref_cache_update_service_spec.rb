# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::RefCacheUpdateService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  let(:changes) do
    instance_double(
      Gitlab::Git::Changes,
      includes_branches?: true,
      includes_tags?: true,
      branch_changes: [
        { ref: 'refs/heads/new-branch', newrev: 'abc123', oldrev: Gitlab::Git::SHA1_BLANK_SHA },
        { ref: 'refs/heads/deleted-branch', newrev: Gitlab::Git::SHA1_BLANK_SHA, oldrev: 'def456' }
      ],
      tag_changes: [
        { ref: 'refs/tags/v1.0', newrev: 'ghi789', oldrev: Gitlab::Git::SHA1_BLANK_SHA }
      ]
    )
  end

  subject(:service) { described_class.new(repository, changes) }

  describe '#execute' do
    it 'triggers an update to the repository cache' do
      expect(repository).to receive(:incremental_ref_cache_update)
        .with('refs/heads/new-branch', false)
      expect(repository).to receive(:incremental_ref_cache_update)
        .with('refs/heads/deleted-branch', true)
      expect(repository).to receive(:incremental_ref_cache_update)
        .with('refs/tags/v1.0', false)

      service.execute
    end

    context 'when ref_cache_with_rebuild_queue is disabled' do
      before do
        stub_feature_flags(ref_cache_with_rebuild_queue: false)
      end

      it 'does not call incremental_ref_cache_update' do
        expect(repository).not_to receive(:incremental_ref_cache_update)

        service.execute
      end
    end

    context 'when repository does not belong to a project' do
      let(:repository) { create(:personal_snippet, :repository).repository }

      it 'does not call incremental_ref_cache_update' do
        expect(Feature).not_to receive(:enabled?).with(:ref_cache_with_rebuild_queue, anything)
        expect(repository).not_to receive(:incremental_ref_cache_update)

        service.execute
      end
    end

    context 'when no refs changed' do
      let(:changes) do
        instance_double(Gitlab::Git::Changes, includes_branches?: false, includes_tags?: false)
      end

      it 'does not call incremental_ref_cache_update' do
        expect(repository).not_to receive(:incremental_ref_cache_update)

        service.execute
      end
    end

    context 'when only branches changed' do
      let(:changes) do
        instance_double(
          Gitlab::Git::Changes,
          includes_branches?: true,
          includes_tags?: false,
          branch_changes: [
            { ref: 'refs/heads/new-branch', newrev: 'abc123', oldrev: Gitlab::Git::SHA1_BLANK_SHA }
          ]
        )
      end

      it 'only processes branch changes' do
        expect(repository).to receive(:incremental_ref_cache_update)
          .with('refs/heads/new-branch', false).once

        service.execute
      end
    end
  end
end
