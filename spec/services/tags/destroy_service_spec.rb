# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tags::DestroyService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }
  let(:skip_find) { false }

  describe '#execute(tag_name, skip_find: false)' do
    subject(:execute) { service.execute(tag_name, skip_find: skip_find) }

    before do
      allow(Ci::RefDeleteUnlockArtifactsWorker).to receive(:perform_async)
    end

    context 'with tag named v1.1.0' do
      let(:tag_name) { 'v1.1.0' }

      it 'removes the tag' do
        allow(repository).to receive(:before_remove_tag)
        allow(service).to receive(:success)

        execute

        expect(repository).to have_received(:before_remove_tag)
        expect(service).to have_received(:success)
      end

      context 'when skip_find is true' do
        let(:skip_find) { true }

        before do
          allow(repository).to receive(:find_tag)
          execute
        end

        it 'does not verify the tag exists in the repository' do
          expect(repository).not_to have_received(:find_tag)
        end
      end

      it 'calls the RefDeleteUnlockArtifactsWorker' do
        expect(Ci::RefDeleteUnlockArtifactsWorker).to receive(:perform_async).with(project.id, user.id, "refs/tags/#{tag_name}")

        execute
      end
    end

    context 'when there is an associated release on the tag' do
      let(:tag) { repository.tags.first }
      let(:tag_name) { tag.name }

      before do
        project.add_maintainer(user)
        create(:release, tag: tag_name, project: project)
      end

      it 'destroys the release' do
        expect { subject }.to change { project.releases.count }.by(-1)
      end
    end
  end
end
