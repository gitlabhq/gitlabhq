# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::ComponentUsage, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:resource) { create(:ci_catalog_resource) }

  let_it_be(:version) do
    create(:release, :with_catalog_resource_version, project: resource.project, tag: '1.2.0', sha: 'my_component_sha')
      .catalog_resource_version
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
            component_project: component.project,
            component_sha: version.sha,
            component_name: component.name
          }]
        ))
    end

    it_behaves_like 'internal event tracking' do
      let(:event) { 'ci_catalog_component_included' }
      let(:label) { component.project.full_path }
      let(:property) { 'my_component@1.2.0' }
      let(:value) { 1 } # Default resource_type
    end

    context 'when the FF `ci_track_catalog_component_usage` is disabled' do
      before do
        stub_feature_flags(ci_track_catalog_component_usage: false)
      end

      it 'does not track an internal event' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event)

        perform
      end
    end
  end
end
