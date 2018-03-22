require 'spec_helper'

describe Gitlab::Diff::FileCollection::MergeRequestDiff do
  let(:merge_request) { create(:merge_request) }
  let(:diff_files) { described_class.new(merge_request.merge_request_diff, diff_options: nil).diff_files }

  it 'does not highlight binary files' do
    allow_any_instance_of(Gitlab::Diff::File).to receive(:text?).and_return(false)

    expect_any_instance_of(Gitlab::Diff::File).not_to receive(:highlighted_diff_lines)

    diff_files
  end

  it 'does not highlight files marked as undiffable in .gitattributes' do
    allow_any_instance_of(Gitlab::Diff::File).to receive(:diffable?).and_return(false)

    expect_any_instance_of(Gitlab::Diff::File).not_to receive(:highlighted_diff_lines)

    diff_files
  end

  shared_examples 'initializes a DiffCollection' do
    it 'returns a valid instance of a DiffCollection' do
      expect(diff_files).to be_a(Gitlab::Git::DiffCollection)
    end
  end

  context 'with Gitaly disabled', :disable_gitaly do
    it_behaves_like 'initializes a DiffCollection'
  end

  context 'with Gitaly enabled' do
    it_behaves_like 'initializes a DiffCollection'
  end
end
