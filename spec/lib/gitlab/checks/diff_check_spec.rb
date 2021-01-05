# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::DiffCheck do
  include_context 'change access checks context'

  describe '#validate!' do
    context 'when commits is empty' do
      it 'does not call find_changed_paths' do
        expect(project.repository).not_to receive(:find_changed_paths)

        subject.validate!
      end
    end

    context 'when commits is not empty' do
      before do
        allow(project.repository).to receive(:new_commits).and_return(
          project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
        )
      end

      context 'when deletion is true' do
        let(:newrev) { Gitlab::Git::BLANK_SHA }

        it 'does not call find_changed_paths' do
          expect(project.repository).not_to receive(:find_changed_paths)

          subject.validate!
        end
      end

      context 'with LFS not enabled' do
        before do
          allow(project).to receive(:lfs_enabled?).and_return(false)
        end

        it 'does not invoke :lfs_file_locks_validation' do
          expect(subject).not_to receive(:lfs_file_locks_validation)

          subject.validate!
        end
      end

      context 'with LFS enabled' do
        let(:owner) { create(:user) }
        let!(:lock) { create(:lfs_file_lock, user: owner, project: project, path: 'README') }

        before do
          allow(project).to receive(:lfs_enabled?).and_return(true)
        end

        context 'when change is sent by a different user' do
          it 'raises an error if the user is not allowed to update the file' do
            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "The path 'README' is locked in Git LFS by #{lock.user.name}")
          end
        end

        context 'when change is sent by the author of the lock' do
          let(:user) { owner }

          it "doesn't raise any error" do
            expect { subject.validate! }.not_to raise_error
          end
        end
      end
    end
  end
end
