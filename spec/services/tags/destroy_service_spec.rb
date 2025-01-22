# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tags::DestroyService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }
  let(:skip_find) { false }
  let(:tag_name) { 'v1.1.0' }

  describe '#execute(tag_name, skip_find: false)' do
    subject(:execute) { service.execute(tag_name, skip_find: skip_find) }

    before do
      allow(Ci::RefDeleteUnlockArtifactsWorker).to receive(:perform_async)
    end

    context 'when user does not have permissions to delete tag' do
      before do
        project.add_reporter(user)
      end

      it 'returns an error' do
        expect(execute).to include(status: :error, message: "You don't have access to delete the tag")
      end
    end

    context 'when user has permissions to delete the tag' do
      before do
        project.add_developer(user)
      end

      context 'when tag exists' do
        it 'removes the tag' do
          allow(repository).to receive(:before_remove_tag)

          expect(execute).to include(status: :success)

          expect(repository).to have_received(:before_remove_tag)
        end

        it 'calls the RefDeleteUnlockArtifactsWorker' do
          expect(Ci::RefDeleteUnlockArtifactsWorker).to receive(:perform_async).with(project.id, user.id, "refs/tags/#{tag_name}")

          execute
        end

        context 'when there is an associated release on the tag' do
          before do
            create(:release, tag: tag_name, project: project)
          end

          it 'destroys the release' do
            expect { subject }.to change { project.releases.count }.by(-1)
          end
        end
      end

      context 'when tag is missing' do
        let(:tag_name) { 'missing-tag' }

        it 'returns an error' do
          expect(execute).to include(status: :error, message: 'No such tag')
        end
      end

      context 'when tag was deleted after find_tag check' do
        before do
          allow(repository).to receive(:find_tag).with(tag_name).and_return(repository.tags.first)
        end

        let(:tag_name) { 'deleted_tag' }

        it 'returns an error message' do
          expect(execute).to include(status: :error, message: 'Failed to remove tag')
        end
      end
    end

    context 'when skip_find is true' do
      let(:skip_find) { true }

      before do
        allow(repository).to receive(:find_tag)
      end

      it 'does not verify the tag exists in the repository' do
        execute
        expect(repository).not_to have_received(:find_tag)
      end

      it 'does not verify if user has permissions to delete tag' do
        project.add_reporter(user)

        expect(execute).to include(status: :success)
      end
    end
  end
end
