# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::DiffCheck, feature_category: :source_code_management do
  include_context 'change access checks context'

  describe '#validate!' do
    context 'when ref is not tag or branch ref' do
      let(:ref) { 'refs/notes/commit' }

      it 'does not call find_changed_paths' do
        expect(project.repository).not_to receive(:find_changed_paths)

        subject.validate!
      end
    end

    context 'when commits is empty' do
      it 'does not call find_changed_paths' do
        expect(project.repository).not_to receive(:find_changed_paths)

        subject.validate!
      end
    end

    context 'when commits include merge commit' do
      before do
        allow(project.repository).to receive(:new_commits).and_return([project.repository.commit(merge_commit)])
        allow(subject).to receive(:should_run_validations?).and_return(true)
        allow(subject).to receive(:validate_path)
        allow(subject).to receive(:validate_file_paths)
        subject.validate!
      end

      context 'when merge commit does not include additional changes' do
        let(:merge_commit) { '2b298117a741cdb06eb48df2c33f1390cf89f7e8' }

        it 'checks the additional changes' do
          expect(subject).to have_received(:validate_file_paths).with([])
        end
      end

      context 'when merge commit includes additional changes' do
        let(:merge_commit) { '1ada92f78a19f27cb442a0a205f1c451a3a15432' }
        let(:file_paths) { ['files/locked/baz.lfs'] }

        it 'checks the additional changes' do
          expect(subject).to have_received(:validate_file_paths).with(file_paths)
        end
      end
    end

    context 'when commits is not empty' do
      let(:new_commits) do
        from = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
        to = '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51'
        project.repository.commits_between(from, to)
      end

      before do
        allow(project.repository).to receive(:new_commits).and_return(new_commits)
      end

      context 'when deletion is true' do
        let(:newrev) { Gitlab::Git::SHA1_BLANK_SHA }

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
            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "'README' is locked in Git LFS by @#{lock.user.username}")
          end
        end

        context 'when change is sent by the author of the lock' do
          let(:user) { owner }

          it "doesn't raise any error" do
            expect { subject.validate! }.not_to raise_error
          end
        end

        context 'when a merge commit merged a file locked by another user' do
          let(:new_commits) do
            project.repository.commits_by(oids: %w[
              760c58db5a6f3b64ad7e3ff6b3c4a009da7d9b33
              2b298117a741cdb06eb48df2c33f1390cf89f7e8
            ])
          end

          before do
            create(:lfs_file_lock, user: owner, project: project, path: 'files/locked/foo.lfs')
            create(:lfs_file_lock, user: user, project: project, path: 'files/locked/bar.lfs')
          end

          it "doesn't raise any error" do
            expect { subject.validate! }.not_to raise_error
          end
        end

        context 'when a merge commit includes additional file locked by another user' do
          # e.g. when merging the user added an additional change.
          # This merge commit: https://gitlab.com/gitlab-org/gitlab-test/-/commit/1ada92f
          # merges `files/locked/bar.lfs` and also adds a new file
          # `files/locked/baz.lfs`. In this case we ignore `files/locked/bar.lfs`
          # as it is already detected in the commit c41e12c, however, we do
          # detect the new `files/locked/baz.lfs` file.
          #
          let(:new_commits) do
            project.repository.commits_by(oids: %w[
              760c58db5a6f3b64ad7e3ff6b3c4a009da7d9b33
              2b298117a741cdb06eb48df2c33f1390cf89f7e8
              c41e12c387b4e0e41bfc17208252d6a6430f2fcd
              1ada92f78a19f27cb442a0a205f1c451a3a15432
            ])
          end

          before do
            create(:lfs_file_lock, user: owner, project: project, path: 'files/locked/foo.lfs')
            create(:lfs_file_lock, user: user, project: project, path: 'files/locked/bar.lfs')
            create(:lfs_file_lock, user: owner, project: project, path: 'files/locked/baz.lfs')
          end

          it "does raise an error" do
            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "'files/locked/baz.lfs' is locked in Git LFS by @#{owner.username}")
          end
        end
      end
    end
  end
end
