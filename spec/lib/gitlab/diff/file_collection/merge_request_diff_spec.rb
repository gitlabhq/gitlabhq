require 'spec_helper'

describe Gitlab::Diff::FileCollection::MergeRequestDiff do
  let(:merge_request) { create :merge_request }

  it 'does not hightlight binary files' do
    allow_any_instance_of(Gitlab::Diff::File).to receive(:blob).and_return(double("text?" => false))

    expect_any_instance_of(Gitlab::Diff::File).not_to receive(:highlighted_diff_lines)

    described_class.new(merge_request.merge_request_diff, diff_options: nil).diff_files
  end
end
