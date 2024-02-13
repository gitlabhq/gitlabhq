# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::DestroyService, feature_category: :release_orchestration do
  let(:project) { create(:project, :repository) }
  let(:mainatiner) { create(:user) }
  let(:repoter) { create(:user) }
  let(:tag) { 'v1.1.0' }
  let!(:release) { create(:release, project: project, tag: tag) }
  let(:service) { described_class.new(project, user, params) }
  let(:params) { { tag: tag } }
  let(:user) { mainatiner }

  before do
    project.add_maintainer(mainatiner)
    project.add_reporter(repoter)
  end

  describe '#execute' do
    subject { service.execute }

    context 'when there is a release' do
      it 'removes the release' do
        expect { subject }.to change { project.releases.count }.by(-1)
      end

      it 'returns the destroyed object' do
        is_expected.to include(status: :success, release: release)
      end

      context 'when the release is for a catalog resource' do
        let!(:catalog_resource) { create(:ci_catalog_resource, :published, project: project) }
        let!(:version) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource, release: release) }

        it 'does not update the catalog resources if there are still releases' do
          second_release = create(:release, project: project, tag: '1.2.0')
          create(:ci_catalog_resource_version, catalog_resource: catalog_resource, release: second_release)

          subject

          expect(catalog_resource.reload.state).to eq('published')
        end

        it 'updates the catalog resource if there are no more releases' do
          subject

          expect(catalog_resource.reload.state).to eq('unpublished')
        end
      end
    end

    context 'when tag does not exist in the repository' do
      let(:tag) { 'v1.1.1' }

      it 'removes the orphaned release' do
        expect { subject }.to change { project.releases.count }.by(-1)
      end
    end

    context 'when release is not found' do
      let!(:release) {}

      it 'returns an error' do
        is_expected.to include(status: :error, message: 'Release does not exist', http_status: 404)
      end
    end

    context 'when user does not have permission' do
      let(:user) { repoter }

      it 'returns an error' do
        is_expected.to include(status: :error, message: 'Access Denied', http_status: 403)
      end
    end

    context 'when a milestone is tied to the release' do
      let!(:milestone) { create(:milestone, :active, project: project, title: 'v1.0') }
      let!(:release) { create(:release, milestones: [milestone], project: project, tag: tag) }

      it 'destroys the release but leave the milestone intact' do
        expect { subject }.not_to change { Milestone.count }
        expect(milestone.reload).to be_persisted
      end
    end

    it 'executes hooks' do
      expect(service.release).to receive(:execute_hooks).with('delete')

      service.execute
    end
  end
end
