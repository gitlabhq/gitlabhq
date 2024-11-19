# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::ComponentUsage, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:resource) { create(:ci_catalog_resource) }

  let_it_be(:release) { create(:release, project: resource.project, tag: '1.2.0', sha: 'my_component_sha') }
  let_it_be(:version) do
    create(:ci_catalog_resource_version, catalog_resource: resource, release: release, semver: release.tag)
  end

  let_it_be(:component) { create(:ci_catalog_resource_component, version: version, name: 'my_component') }

  let(:dry_run) { false }
  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user, dry_run: dry_run) }
  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject(:perform) { step.perform! }

    before do
      allow(command).to receive(:yaml_processor_result)
        .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result,
          included_components: [{
            project: component.project,
            sha: version.sha,
            name: component.name
          }]
        ))
    end

    it_behaves_like 'internal event tracking' do
      let(:event) { 'ci_catalog_component_included' }
      let(:label) { component.id.to_s }
      let(:value) { 1 } # Default resource_type
    end

    it 'creates a component usage record' do
      expect { perform }.to change { Ci::Catalog::Resources::Components::Usage.count }.by(1)
                        .and change { Ci::Catalog::Resources::Components::LastUsage.count }.by(1)
    end

    context 'when component usage has already been recorded', :freeze_time do
      let!(:existing_last_usage) do
        create(:catalog_resource_component_last_usage,
          component: component, used_by_project_id: project.id, last_used_date: Time.current.to_date - 3.days)
      end

      it 'updates the last_used_date for the existing last_usage record' do
        expect { step.perform! }.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }

        last_usage = Ci::Catalog::Resources::Components::LastUsage.find_by(component: component,
          used_by_project_id: project.id)
        expect(last_usage.last_used_date).to eq(Time.current.to_date)
      end

      it 'does not create a component usage record' do
        step.perform!

        expect { perform }.not_to change { Ci::Catalog::Resources::Components::Usage.count }
      end
    end
  end
end
