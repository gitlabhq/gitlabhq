# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateKustomizationApiVersion, feature_category: :environment_management do
  let(:migration) { described_class.new }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  let(:environments_table) { table(:environments) }

  old_version_path = 'https://cluster.kustomize.toolkit.fluxcd.io/v1beta1/foo'
  new_version_path = 'https://cluster.kustomize.toolkit.fluxcd.io/v1/foo'

  context 'when flux_resource_path is a kustomization resource path' do
    before do
      environments_table.create!(name: 'kustomize', slug: 'kustomize', project_id: project.id,
        flux_resource_path: old_version_path)
    end

    it 'updates the API version from v1beta1 to v1 in flux_resource_path' do
      expect { migrate! }
        .to change { environments_table.first.flux_resource_path }.from(old_version_path).to(new_version_path)
    end

    context 'when flux_resource_path is not a kustomization resource path' do
      before do
        environments_table.create!(name: 'helm', slug: 'helm', project_id: project.id, flux_resource_path: 'https://cluster.helm.toolkit.fluxcd.io/v2beta1/foo')
      end

      it 'does not update the flux_resource_path' do
        expect { migrate! }.not_to change { environments_table.second.flux_resource_path }
      end
    end

    context 'when flux_resource_path is nil' do
      before do
        environments_table.create!(name: 'no flux', slug: 'no-flux', project_id: project.id)
      end

      it 'does not update the flux_resource_path' do
        expect { migrate! }.not_to change { environments_table.second.flux_resource_path }
      end
    end
  end
end
