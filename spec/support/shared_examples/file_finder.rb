shared_examples 'file finder' do
  let(:query) { 'files' }
  let(:search_results) { subject.find(query) }

  it 'finds by name' do
    filename,  blob = search_results.find { |_, blob| blob.filename == expected_file_by_name }
    expect(filename).to eq(expected_file_by_name)
    expect(blob).to be_a(Gitlab::SearchResults::FoundBlob)
    expect(blob.ref).to eq(subject.ref)
    expect(blob.data).not_to be_empty
  end

  it 'finds by content' do
    filename, blob = search_results.find { |_, blob| blob.filename == expected_file_by_content }

    expect(filename).to eq(expected_file_by_content)
    expect(blob).to be_a(Gitlab::SearchResults::FoundBlob)
    expect(blob.ref).to eq(subject.ref)
    expect(blob.data).not_to be_empty
  end
end
