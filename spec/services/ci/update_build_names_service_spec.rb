# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateBuildNamesService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build1) { create(:ci_build, name: 'build1', pipeline: pipeline) }
  let_it_be(:build2) { create(:ci_build, name: 'build2', pipeline: pipeline) }
  let_it_be(:build3) { create(:ci_build, name: 'build3', pipeline: pipeline) }
  let_it_be(:bridge1) { create(:ci_bridge, name: 'bridge1', pipeline: pipeline) }

  describe '#execute' do
    subject(:service) { described_class.new(pipeline) }

    it "avoids N+1 database queries" do
      control = ActiveRecord::QueryRecorder.new { service.execute }
      create_list(:ci_build, 5, pipeline: pipeline)
      action = ActiveRecord::QueryRecorder.new { service.execute }

      expect { action }.not_to exceed_query_limit(control)
    end

    it 'updates build names with pipeline builds' do
      expect { service.execute }.to change { Ci::BuildName.count }.by(3)

      expect(Ci::BuildName.where(project_id: project.id).pluck(:build_id, :partition_id, :name))
        .to match_array([
          [build1.id, build1.partition_id, build1.name],
          [build2.id, build2.partition_id, build2.name],
          [build3.id, build3.partition_id, build3.name]
        ])
    end

    it 'updates build names with new builds on same pipeline' do
      expect { service.execute }.to change { Ci::BuildName.count }.by(3)

      build4 = create(:ci_build, name: 'build4', pipeline: pipeline)

      expect { service.execute }.to change { Ci::BuildName.count }.by(1)

      expect(Ci::BuildName.find_by(build_id: build4.id).name).to eq('build4')
    end

    it 'skips retried builds' do
      pipeline.builds.update_all(retried: true)
      build = create(:ci_build, name: 'retried-build', pipeline: pipeline)

      expect(Ci::BuildName).to receive(:upsert_all).with([{
        project_id: build.project_id,
        build_id: build.id,
        partition_id: build.partition_id,
        name: build.name
      }], anything)

      service.execute
    end

    it 'does not create build name for bridge job' do
      service.execute

      expect(Ci::BuildName.find_by_build_id(bridge1.id)).to be_nil
    end
  end
end
