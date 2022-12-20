# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillDeploymentsFinishedAt, :migration, feature_category: :continuous_delivery do
  let(:deployments) { table(:deployments) }
  let(:namespaces) { table(:namespaces) }

  let(:namespace) { namespaces.create!(name: 'user', path: 'user') }
  let(:project_namespace) { namespaces.create!(name: 'project', path: 'project', type: 'Project') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: project_namespace.id) }
  let(:environment) { table(:environments).create!(name: 'production', slug: 'production', project_id: project.id) }

  describe '#up' do
    context 'when a deployment row does not have a value for finished_at' do
      context 'and deployment succeeded' do
        before do
          create_deployment!(status: described_class::DEPLOYMENT_STATUS_SUCCESS, finished_at: nil)
        end

        it 'copies created_at to finished_at' do
          expect { migrate! }
            .to change { deployments.last.finished_at }.from(nil).to(deployments.last.created_at)
            .and not_change { deployments.last.created_at }
        end
      end

      context 'and deployment does not have status: success' do
        before do
          create_deployment!(status: 0, finished_at: nil)
          create_deployment!(status: 1, finished_at: nil)
          create_deployment!(status: 3, finished_at: nil)
          create_deployment!(status: 4, finished_at: nil)
          create_deployment!(status: 5, finished_at: nil)
          create_deployment!(status: 6, finished_at: nil)
        end

        it 'does not fill finished_at' do
          expect { migrate! }.to not_change { deployments.where(finished_at: nil).count }
        end
      end
    end

    context 'when a deployment row has value for finished_at' do
      let(:finished_at) { '2018-10-30 11:12:02 UTC' }

      before do
        create_deployment!(status: described_class::DEPLOYMENT_STATUS_SUCCESS, finished_at: finished_at)
      end

      it 'does not affect existing value' do
        expect { migrate! }
          .to not_change { deployments.last.finished_at }
          .and not_change { deployments.last.created_at }
      end
    end
  end

  def create_deployment!(status:, finished_at:)
    deployments.create!(
      environment_id: environment.id,
      project_id: project.id,
      ref: 'master',
      tag: false,
      sha: 'x',
      status: status,
      iid: deployments.count + 1,
      finished_at: finished_at
    )
  end
end
