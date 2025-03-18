# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProjectWithPipelineVariable, feature_category: :continuous_integration do
  describe '.upsert_for_pipeline' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    context 'when the pipeline has variables' do
      before do
        create(:ci_pipeline_variable, pipeline: pipeline, key: 'foo', value: 'bar')
      end

      it 'creates a corresponding project_with_pipeline_variable record' do
        expect { described_class.upsert_for_pipeline(pipeline) }
          .to change { described_class.count }.by(1)

        expect(described_class.last.project_id).to eq(project.id)
      end

      context 'when a record already exists for the project' do
        before do
          described_class.create!(project_id: project.id)
        end

        it 'does not create a duplicate record' do
          expect { described_class.upsert_for_pipeline(pipeline) }
            .not_to change { described_class.count }
        end
      end
    end

    context 'when the pipeline has no variables' do
      it 'does not create a project_with_pipeline_variable record' do
        expect { described_class.upsert_for_pipeline(pipeline) }
          .not_to change { described_class.count }
      end
    end
  end
end
