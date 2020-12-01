# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::SnippetCheck do
  include_context 'change access checks context'

  let_it_be(:snippet) { create(:personal_snippet, :repository) }

  let(:user_access) { Gitlab::UserAccessSnippet.new(user, snippet: snippet) }
  let(:default_branch) { snippet.default_branch }
  let(:branch_name) { default_branch }
  let(:creation) { false }
  let(:deletion) { false }

  subject { Gitlab::Checks::SnippetCheck.new(changes, default_branch: default_branch, logger: logger) }

  describe '#validate!' do
    it 'does not raise any error' do
      expect { subject.validate! }.not_to raise_error
    end

    shared_examples 'raises and logs error' do
      specify do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(Gitlab::GitAccess::ForbiddenError), default_branch: default_branch, branch_name: branch_name, creation: creation, deletion: deletion)

        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, 'You can not create or delete branches.')
      end
    end

    context 'trying to delete the branch' do
      let(:newrev) { '0000000000000000000000000000000000000000' }

      it_behaves_like 'raises and logs error' do
        let(:deletion) { true }
      end
    end

    context 'trying to create the branch' do
      let(:oldrev) { '0000000000000000000000000000000000000000' }
      let(:ref) { 'refs/heads/feature' }

      it_behaves_like 'raises and logs error' do
        let(:creation) { true }
        let(:branch_name) { 'feature' }
      end

      context "when branch is 'master'" do
        let(:ref) { 'refs/heads/master' }

        it "allows the operation" do
          expect { subject.validate! }.not_to raise_error
        end
      end
    end

    context 'when default_branch is nil' do
      let(:default_branch) { nil }

      it_behaves_like 'raises and logs error' do
        let(:branch_name) { 'master' }
      end
    end
  end
end
