# frozen_string_literal: true

RSpec.shared_examples 'mounted file in local store' do
  it 'is stored locally' do
    expect(subject.file_store).to be(ObjectStorage::Store::LOCAL)
    expect(subject.file).to be_file_storage
    expect(subject.file.object_store).to eq(ObjectStorage::Store::LOCAL)
  end
end

RSpec.shared_examples 'mounted file in object store' do
  it 'is stored remotely' do
    expect(subject.file_store).to eq(ObjectStorage::Store::REMOTE)
    expect(subject.file).not_to be_file_storage
    expect(subject.file.object_store).to eq(ObjectStorage::Store::REMOTE)
  end
end
