# frozen_string_literal: true

shared_examples 'file finder' do
  let(:query) { 'files' }
  let(:search_results) { subject.find(query) }

  it 'finds by name' do
    blob = search_results.find { |blob| blob.filename == expected_file_by_name }

    expect(blob.filename).to eq(expected_file_by_name)
    expect(blob).to be_a(Gitlab::Search::FoundBlob)
    expect(blob.ref).to eq(subject.ref)
    expect(blob.data).not_to be_empty
  end

  it 'finds by content' do
    blob = search_results.find { |blob| blob.filename == expected_file_by_content }

    expect(blob.filename).to eq(expected_file_by_content)
    expect(blob).to be_a(Gitlab::Search::FoundBlob)
    expect(blob.ref).to eq(subject.ref)
    expect(blob.data).not_to be_empty
  end
end
