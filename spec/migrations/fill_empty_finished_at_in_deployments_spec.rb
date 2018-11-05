require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181030135124_fill_empty_finished_at_in_deployments')

describe FillEmptyFinishedAtInDeployments, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:environments) { table(:environments) }
  let(:deployments) { table(:deployments) }

  context 'when a deployment row does not have a value on finished_at' do
    context 'when a deployment succeeded' do
      before do
        namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
        projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
        environments.create!(id: 1, name: 'production', slug: 'production', project_id: 1)
        deployments.create!(id: 1, iid: 1, project_id: 1, environment_id: 1, ref: 'master', sha: 'xxx', tag: false)
      end

      it 'correctly replicates finished_at by created_at' do
        expect(deployments.last.created_at).not_to be_nil
        expect(deployments.last.finished_at).to be_nil

        migrate!

        expect(deployments.last.created_at).not_to be_nil
        expect(deployments.last.finished_at).to eq(deployments.last.created_at)
      end
    end

    context 'when a deployment is running' do
      before do
        namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
        projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
        environments.create!(id: 1, name: 'production', slug: 'production', project_id: 1)
        deployments.create!(id: 1, iid: 1, project_id: 1, environment_id: 1, ref: 'master', sha: 'xxx', tag: false, status: 1)
      end

      it 'does not fill finished_at' do
        expect(deployments.last.created_at).not_to be_nil
        expect(deployments.last.finished_at).to be_nil

        migrate!

        expect(deployments.last.created_at).not_to be_nil
        expect(deployments.last.finished_at).to be_nil
      end
    end
  end

  context 'when a deployment row does has a value on finished_at' do
    let(:finished_at) { '2018-10-30 11:12:02 UTC' }

    before do
      namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
      projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
      environments.create!(id: 1, name: 'production', slug: 'production', project_id: 1)
      deployments.create!(id: 1, iid: 1, project_id: 1, environment_id: 1, ref: 'master', sha: 'xxx', tag: false, finished_at: finished_at)
    end

    it 'does not affect existing value' do
      expect(deployments.last.created_at).not_to be_nil
      expect(deployments.last.finished_at).not_to be_nil

      migrate!

      expect(deployments.last.created_at).not_to be_nil
      expect(deployments.last.finished_at).to eq(finished_at)
    end
  end
end
