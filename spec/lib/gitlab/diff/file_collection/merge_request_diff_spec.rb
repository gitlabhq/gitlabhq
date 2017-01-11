require 'spec_helper'

describe Gitlab::Diff::FileCollection::MergeRequestDiff do
  let(:merge_request) { create(:merge_request) }
  let(:diff_files) { described_class.new(merge_request.merge_request_diff, diff_options: nil).diff_files }

  it 'does not highlight binary files' do
    allow_any_instance_of(Gitlab::Diff::File).to receive(:blob).and_return(double("text?" => false))

    expect_any_instance_of(Gitlab::Diff::File).not_to receive(:highlighted_diff_lines)

    diff_files
  end

  it 'does not highlight file if blob is not accessable' do
    allow_any_instance_of(Gitlab::Diff::File).to receive(:blob).and_return(nil)

    expect_any_instance_of(Gitlab::Diff::File).not_to receive(:highlighted_diff_lines)

    diff_files
  end

  it 'does not files marked as undiffable in .gitattributes' do
    allow_any_instance_of(Repository).to receive(:diffable?).and_return(false)

    expect_any_instance_of(Gitlab::Diff::File).not_to receive(:highlighted_diff_lines)

    diff_files
  end
end
