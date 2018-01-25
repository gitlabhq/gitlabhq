require 'spec_helper'

describe Lfs::LocksFinderService do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:params)  { {} }

  subject { described_class.new(project, user, params) }

  shared_examples 'no results' do
    it 'returns an empty list' do
      result = subject.execute

      expect(result[:status]).to eq(:success)
      expect(result[:locks]).to be_blank
    end
  end

  describe '#execute' do
    let!(:lock_1) { create(:lfs_file_lock, project: project) }
    let!(:lock_2) { create(:lfs_file_lock, project: project, path: 'README') }

    context 'find by id' do
      context 'with results' do
        let(:params) do
          { id: lock_1.id }
        end

        it 'returns the record' do
          result = subject.execute

          expect(result[:status]).to eq(:success)
          expect(result[:locks].size).to eq(1)
          expect(result[:locks].first).to eq(lock_1)
        end
      end

      context 'without results' do
        let(:params) do
          { id: 123 }
        end

        include_examples 'no results'
      end
    end

    context 'find by path' do
      context 'with results' do
        let(:params) do
          { path: lock_1.path }
        end

        it 'returns the record' do
          result = subject.execute

          expect(result[:status]).to eq(:success)
          expect(result[:locks].size).to eq(1)
          expect(result[:locks].first).to eq(lock_1)
        end
      end

      context 'without results' do
        let(:params) do
          { path: 'not-found' }
        end

        include_examples 'no results'
      end
    end

    context 'find all' do
      context 'with results' do
        it 'returns all the records' do
          result = subject.execute

          expect(result[:status]).to eq(:success)
          expect(result[:locks].size).to eq(2)
        end
      end

      context 'without results' do
        before do
          LfsFileLock.delete_all
        end

        include_examples 'no results'
      end
    end

    context 'when an error is raised' do
      it "doesn't succeed" do
        allow_any_instance_of(described_class).to receive(:find_locks).and_raise(StandardError)

        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:locks]).to be_blank
      end
    end
  end
end
