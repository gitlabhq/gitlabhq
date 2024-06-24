# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::CommitsCheck, feature_category: :source_code_management do
  include_context 'change access checks context'

  describe '#validate!' do
    context 'when commits is not empty' do
      let(:new_commit) { project.commit }

      before do
        allow(project.repository).to receive(:new_commits).and_return([new_commit])
      end

      context 'when deletion is true' do
        let(:newrev) { Gitlab::Git::SHA1_BLANK_SHA }

        it 'does not call check_signed_commit_authorship!' do
          expect(change_check).not_to receive(:check_signed_commit_authorship!)

          expect { change_check.validate! }.not_to raise_error
        end
      end

      context 'when commits are not signed by GitLab' do
        it 'does not call check_signed_commit_authorship!' do
          expect { change_check.validate! }.not_to raise_error
        end
      end

      context 'when a commit is signed by GitLab' do
        before do
          allow(change_check).to receive(:signed_by_gitlab?).with(new_commit).and_return(true)
          allow(new_commit).to receive(:author).and_return(author)
        end

        context 'when author is equal to the committer' do
          let(:author) { user }

          it 'does not call check_signed_commit_authorship!' do
            expect { change_check.validate! }.not_to raise_error
          end
        end

        context 'when author is not equal to the committer' do
          let(:author) { create(:user) }

          context 'when protocol is web' do
            let(:protocol) { 'web' }

            it 'raises an error' do
              expect(change_check).to receive(:check_signed_commit_authorship!).and_call_original
              expect { change_check.validate! }.to raise_error(
                Gitlab::GitAccess::ForbiddenError, 'For signed Web commits, the commit must be equal to the author'
              )
            end
          end

          context 'when protocol is ssh' do
            let(:protocol) { 'ssh' }

            it 'does not raise an error nor call check_signed_commit_authorship!' do
              expect(change_check).not_to receive(:check_signed_commit_authorship!)
              expect(change_check.validate!).to be_nil
            end
          end

          context 'when protocol is http' do
            let(:protocol) { 'http' }

            it 'does not raise an error nor call check_signed_commit_authorship!' do
              expect(change_check).not_to receive(:check_signed_commit_authorship!)
              expect(change_check.validate!).to be_nil
            end
          end
        end
      end
    end
  end
end
