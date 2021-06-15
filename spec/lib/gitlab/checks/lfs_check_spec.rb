# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::LfsCheck do
  include_context 'changes access checks context'

  let(:blob_object) { project.repository.blob_at_branch('lfs', 'files/lfs/lfs_object.iso') }

  before do
    allow_any_instance_of(Gitlab::Git::LfsChanges).to receive(:new_pointers) do
      [blob_object]
    end
  end

  describe '#validate!' do
    context 'with LFS not enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(false)
      end

      it 'skips integrity check' do
        expect_any_instance_of(Gitlab::Git::LfsChanges).not_to receive(:new_pointers)

        subject.validate!
      end
    end

    context 'with LFS enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'with lfs_check feature disabled' do
        before do
          stub_feature_flags(lfs_check: false)
        end

        it 'skips integrity check' do
          expect_any_instance_of(Gitlab::Git::LfsChanges).not_to receive(:new_pointers)

          subject.validate!
        end
      end

      context 'with deletion' do
        shared_examples 'a skipped integrity check' do
          it 'skips integrity check' do
            expect(project.repository).not_to receive(:new_objects)
            expect_any_instance_of(Gitlab::Git::LfsChanges).not_to receive(:new_pointers)

            subject.validate!
          end
        end

        context 'with missing newrev' do
          it_behaves_like 'a skipped integrity check' do
            let(:changes) { [{ oldrev: oldrev, ref: ref }] }
          end
        end

        context 'with blank newrev' do
          it_behaves_like 'a skipped integrity check' do
            let(:changes) { [{ oldrev: oldrev, newrev: Gitlab::Git::BLANK_SHA, ref: ref }] }
          end
        end
      end

      it 'fails if any LFS blobs are missing' do
        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, /LFS objects are missing/)
      end

      it 'succeeds if LFS objects have already been uploaded' do
        lfs_object = create(:lfs_object, oid: blob_object.lfs_oid)
        create(:lfs_objects_project, project: project, lfs_object: lfs_object)

        expect { subject.validate! }.not_to raise_error
      end
    end
  end
end
