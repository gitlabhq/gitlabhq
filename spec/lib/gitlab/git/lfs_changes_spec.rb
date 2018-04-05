require 'spec_helper'

describe Gitlab::Git::LfsChanges do
  let(:project) { create(:project, :repository) }
  let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
  let(:blob_object_id) { '0c304a93cb8430108629bbbcaa27db3343299bc0' }

  subject { described_class.new(project.repository, newrev) }

  describe '#new_pointers' do
    shared_examples 'new pointers' do
      it 'filters new objects to find lfs pointers' do
        expect(subject.new_pointers(not_in: []).first.id).to eq(blob_object_id)
      end

      it 'limits new_objects using object_limit' do
        expect(subject.new_pointers(object_limit: 1)).to eq([])
      end
    end

    context 'with gitaly enabled' do
      it_behaves_like 'new pointers'
    end

    context 'with gitaly disabled', :skip_gitaly_mock do
      it_behaves_like 'new pointers'

      it 'uses rev-list to find new objects' do
        rev_list = double
        allow(Gitlab::Git::RevList).to receive(:new).and_return(rev_list)

        expect(rev_list).to receive(:new_objects).and_return([])

        subject.new_pointers
      end
    end
  end

  describe '#all_pointers', :skip_gitaly_mock do
    it 'uses rev-list to find all objects' do
      rev_list = double
      allow(Gitlab::Git::RevList).to receive(:new).and_return(rev_list)
      allow(rev_list).to receive(:all_objects).and_yield([blob_object_id])

      expect(Gitlab::Git::Blob).to receive(:batch_lfs_pointers).with(project.repository, [blob_object_id])

      subject.all_pointers
    end
  end
end
