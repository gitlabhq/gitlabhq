# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositorySizeErrorMessage do
  let_it_be(:namespace) { build(:namespace) }

  let(:checker) do
    Gitlab::RepositorySizeChecker.new(
      current_size_proc: -> { 15.megabytes },
      namespace: namespace,
      limit: 10.megabytes
    )
  end

  let(:message) { checker.error_message }
  let(:base_message) { 'because this repository has exceeded the allocated storage for your project' }

  before do
    allow(namespace).to receive(:total_repository_size_excess).and_return(0)
  end

  describe 'error messages' do
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
          'because this repository has exceeded the allocated storage for your project'
        end

        it 'returns the correct message' do
          expect(message.push_error)
            .to eq("Your push to this repository cannot be completed #{rejection_message}. #{message.more_info_message}")
        end
      end

      context 'without exceeded_limit value' do
        it 'returns the correct message' do
          expect(message.push_error)
            .to eq("Your push to this repository cannot be completed #{base_message}. #{message.more_info_message}")
        end
      end
    end

    describe '#new_changes_error' do
      context 'when additional repo storage is available' do
        it 'returns the correct message' do
          allow(checker).to receive(:additional_repo_storage_available?).and_return(true)

          expect(message.new_changes_error).to eq('Your push to this repository cannot be completed as it would exceed the allocated storage for your project. Contact your GitLab administrator for more information.')
        end
      end
    end
  end
end
