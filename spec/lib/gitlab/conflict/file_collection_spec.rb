require 'spec_helper'

describe Gitlab::Conflict::FileCollection do
  let(:merge_request) { create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start') }
  let(:file_collection) { described_class.new(merge_request) }

  describe '#files' do
    it 'returns an array of Conflict::Files' do
      expect(file_collection.files).to all(be_an_instance_of(Gitlab::Conflict::File))
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
