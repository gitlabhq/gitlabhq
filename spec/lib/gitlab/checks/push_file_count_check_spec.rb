# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::PushFileCountCheck, feature_category: :source_code_management do
  let(:snippet) { create(:personal_snippet, :repository) }
  let(:changes) { { oldrev: oldrev, newrev: newrev, ref: ref } }
  let(:timeout) { Gitlab::GitAccess::INTERNAL_TIMEOUT }
  let(:logger) { Gitlab::Checks::TimedLogger.new(timeout: timeout) }

  subject { described_class.new(changes, repository: snippet.repository, limit: 2, logger: logger) }

  describe '#validate!' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(snippet.repository).to receive(:new_commits).and_return(
        snippet.repository.commits_between(oldrev, newrev)
      )
    end

    context 'initial creation' do
      let(:oldrev) { Gitlab::Git::SHA1_EMPTY_TREE_ID }
      let(:newrev) { TestEnv::BRANCH_SHA["snippet/single-file"] }
      let(:ref) { "refs/heads/snippet/single-file" }

      it 'allows creation' do
        expect { subject.validate! }.not_to raise_error
      end
    end

    where(:old, :new, :valid, :message) do
      'single-file' | 'edit-file'            | true  | nil
      'single-file' | 'multiple-files'       | false | 'The repository can contain at most 2 file(s).'
      'single-file' | 'no-files'             | false | 'The repository must contain at least 1 file.'
      'edit-file'   | 'rename-and-edit-file' | true  | nil
    end

    with_them do
      let(:oldrev) { TestEnv::BRANCH_SHA["snippet/#{old}"] }
      let(:newrev) { TestEnv::BRANCH_SHA["snippet/#{new}"] }
      let(:ref) { "refs/heads/snippet/#{new}" }

      it "verifies" do
        if valid
          expect { subject.validate! }.not_to raise_error
        else
          expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, message)
        end
      end
    end
  end
end
