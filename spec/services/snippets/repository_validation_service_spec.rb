# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::RepositoryValidationService, feature_category: :source_code_management do
  describe '#execute' do
    let_it_be(:user)    { create(:user) }
    let_it_be(:snippet) { create(:personal_snippet, :empty_repo, author: user) }

    let(:repository)    { snippet.repository }
    let(:service)       { described_class.new(user, snippet) }

    subject { service.execute }

    before do
      allow(repository).to receive(:branch_count).and_return(1)
      allow(repository).to receive(:ls_files).and_return(['foo'])
      allow(repository).to receive(:branch_names).and_return(['master'])
    end

    it 'returns error when the repository has more than one branch' do
      allow(repository).to receive(:branch_count).and_return(2)

      expect(subject).to be_error
      expect(subject.message).to match(/Repository has more than one branch/)
    end

    it 'returns error when existing branch name is not the default one' do
      allow(repository).to receive(:branch_names).and_return(['foo'])

      expect(subject).to be_error
      expect(subject.message).to match(/Repository has an invalid default branch name/)
    end

    it 'returns error when the repository has tags' do
      allow(repository).to receive(:tag_count).and_return(1)

      expect(subject).to be_error
      expect(subject.message).to match(/Repository has tags/)
    end

    it 'returns error when the repository has more file than the limit' do
      limit = Snippet.max_file_limit + 1
      files = Array.new(limit) { FFaker::Filesystem.file_name }
      allow(repository).to receive(:ls_files).and_return(files)

      expect(subject).to be_error
      expect(subject.message).to match(/Repository files count over the limit/)
    end

    it 'returns error when the repository has no files' do
      allow(repository).to receive(:ls_files).and_return([])

      expect(subject).to be_error
      expect(subject.message).to match(/Repository must contain at least 1 file/)
    end

    it 'returns error when the repository size is over the limit' do
      expect_next_instance_of(Gitlab::RepositorySizeChecker) do |checker|
        expect(checker).to receive(:above_size_limit?).and_return(true)
      end

      expect(subject).to be_error
      expect(subject.message).to match(/Repository size is above the limit/)
    end

    it 'returns success when no validation errors are raised' do
      expect(subject).to be_success
    end
  end
end
