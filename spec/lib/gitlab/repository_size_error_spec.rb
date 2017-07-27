require 'spec_helper'

describe Gitlab::RepositorySizeError do
  let(:project) do
    create(:empty_project, statistics: build(:project_statistics, repository_size: 15.megabytes))
  end

  let(:message) { described_class.new(project) }
  let(:base_message) { 'because this repository has exceeded its size limit of 10 MB by 5 MB' }

  before do
    allow(project).to receive(:actual_size_limit).and_return(10.megabytes)
  end

  describe 'error messages' do
    describe '#to_s' do
      it 'returns the correct message' do
        expect(message.to_s).to eq('The size of this repository (15 MB) exceeds the limit of 10 MB by 5 MB.')
      end
    end

    describe '#commit_error' do
      it 'returns the correct message' do
        expect(message.commit_error).to eq("Your changes could not be committed, #{base_message}")
      end
    end

    describe '#merge_error' do
      it 'returns the correct message' do
        expect(message.merge_error).to eq("This merge request cannot be merged, #{base_message}")
      end
    end

    describe '#push_error' do
      context 'with exceeded_limit value' do
        let(:rejection_message) do
          'because this repository has exceeded its size limit of 10 MB by 15 MB'
        end

        it 'returns the correct message' do
          expect(message.push_error(15.megabytes))
            .to eq("Your push has been rejected, #{rejection_message}. #{message.more_info_message}")
        end
      end

      context 'without exceeded_limit value' do
        it 'returns the correct message' do
          expect(message.push_error)
            .to eq("Your push has been rejected, #{base_message}. #{message.more_info_message}")
        end
      end
    end

    describe '#new_changes_error' do
      it 'returns the correct message' do
        expect(message.new_changes_error).to eq("Your push to this repository would cause it to exceed the size limit of 10 MB so it has been rejected. #{message.more_info_message}")
      end
    end
  end
end
