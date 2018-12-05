# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Checks::DiffCheck do
  include_context 'change access checks context'

  describe '#validate!' do
    let(:owner) { create(:user) }
    let!(:lock) { create(:lfs_file_lock, user: owner, project: project, path: 'README') }

    before do
      allow(project.repository).to receive(:new_commits).and_return(
        project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
      )
    end

    context 'with LFS not enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(false)
      end

      it 'skips the validation' do
        expect(subject).not_to receive(:validate_diff)
        expect(subject).not_to receive(:validate_file_paths)

        subject.validate!
      end
    end

    context 'with LFS enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'when change is sent by a different user' do
        it 'raises an error if the user is not allowed to update the file' do
          expect { subject.validate! }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "The path 'README' is locked in Git LFS by #{lock.user.name}")
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
