# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Conflict::FileCollection do
  let(:merge_request) { create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start') }
  let(:allow_tree_conflicts) { false }
  let(:skip_content) { false }

  let(:file_collection) do
    described_class.new(
      merge_request,
      allow_tree_conflicts: allow_tree_conflicts,
      skip_content: skip_content
    )
  end

  describe '#files' do
    let(:conflict_files) { [instance_double(Gitlab::Conflict::File, path: 'file.md')] }
    let(:git_conflict_files) { [instance_double(Gitlab::Git::Conflict::File, path: 'file.md')] }
    let(:resolver) { instance_double(Gitlab::Git::Conflict::Resolver, conflicts: git_conflict_files) }

    it 'returns an array of Conflict::Files' do
      expect(file_collection.files).to all(be_an_instance_of(Gitlab::Conflict::File))
    end

    it 'returns conflict files' do
      expect(Gitlab::Git::Conflict::Resolver)
        .to receive(:new)
        .with(
          merge_request.source_project.repository.raw,
          merge_request.source_branch_head.raw.id,
          merge_request.target_branch_head.raw.id,
          allow_tree_conflicts: false,
          skip_content: false
        )
        .and_return(resolver)

      expect(file_collection.files.map(&:path)).to eq(conflict_files.map(&:path))
    end

    context 'when allow_tree_conflicts is set to true' do
      let(:allow_tree_conflicts) { true }

      it 'returns conflict files with allow_tree_conflicts as true' do
        expect(Gitlab::Git::Conflict::Resolver)
          .to receive(:new)
          .with(
            merge_request.source_project.repository.raw,
            merge_request.source_branch_head.raw.id,
            merge_request.target_branch_head.raw.id,
            allow_tree_conflicts: true,
            skip_content: false
          )
          .and_return(resolver)

        expect(file_collection.files.map(&:path)).to eq(conflict_files.map(&:path))
      end
    end

    context 'when skip_content is set to true' do
      let(:skip_content) { true }

      it 'returns conflict files with skip_content as true' do
        expect(Gitlab::Git::Conflict::Resolver)
          .to receive(:new)
          .with(
            merge_request.source_project.repository.raw,
            merge_request.source_branch_head.raw.id,
            merge_request.target_branch_head.raw.id,
            allow_tree_conflicts: false,
            skip_content: true
          )
          .and_return(resolver)

        expect(file_collection.files.map(&:path)).to eq(conflict_files.map(&:path))
      end
    end
  end

  describe '#cache' do
    it 'specifies a custom namespace with the merge request commit ids' do
      our_commit = merge_request.source_branch_head.raw
      their_commit = merge_request.target_branch_head.raw
      custom_namespace = "#{our_commit.id}:#{their_commit.id}"

      expect(file_collection.send(:cache).namespace).to include(custom_namespace)
    end
  end

  describe '#can_be_resolved_in_ui?' do
    it 'returns true if conflicts for this collection can be resolved in the UI' do
      expect(file_collection.can_be_resolved_in_ui?).to be true
    end

    it "returns false if conflicts for this collection can't be resolved in the UI" do
      expect(file_collection).to receive(:files).and_raise(Gitlab::Git::Conflict::Resolver::ConflictSideMissing)

      expect(file_collection.can_be_resolved_in_ui?).to be false
    end

    it 'caches the result' do
      expect(file_collection).to receive(:files).twice.and_call_original

      expect(file_collection.can_be_resolved_in_ui?).to be true

      expect(file_collection).not_to receive(:files)

      expect(file_collection.can_be_resolved_in_ui?).to be true
    end
  end

  describe '#default_commit_message' do
    it 'matches the format of the git CLI commit message' do
      expect(file_collection.default_commit_message).to eq(<<EOM.chomp)
Merge branch 'conflict-start' into 'conflict-resolvable'

# Conflicts:
#   files/ruby/popen.rb
#   files/ruby/regex.rb
EOM
    end
  end
end
