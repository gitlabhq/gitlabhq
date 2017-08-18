require 'spec_helper'

describe Gitlab::Conflict::FileCollection do
  let(:merge_request) { create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start') }
  let(:file_collection) { described_class.read_only(merge_request) }

  describe '#files' do
    it 'returns an array of Conflict::Files' do
      expect(file_collection.files).to all(be_an_instance_of(Gitlab::Conflict::File))
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
