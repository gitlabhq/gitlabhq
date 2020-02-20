# frozen_string_literal: true

RSpec.shared_examples 'file finder' do
  let(:query) { 'files' }
  let(:search_results) { subject.find(query) }

  it 'finds by path' do
    blob = search_results.find { |blob| blob.path == expected_file_by_path }

    expect(blob.path).to eq(expected_file_by_path)
    expect(blob).to be_a(Gitlab::Search::FoundBlob)
    expect(blob.ref).to eq(subject.ref)
    expect(blob.data).not_to be_empty
  end

  it 'finds by content' do
    blob = search_results.find { |blob| blob.path == expected_file_by_content }

    expect(blob.path).to eq(expected_file_by_content)
    expect(blob).to be_a(Gitlab::Search::FoundBlob)
    expect(blob.ref).to eq(subject.ref)
    expect(blob.data).not_to be_empty
  end
end
