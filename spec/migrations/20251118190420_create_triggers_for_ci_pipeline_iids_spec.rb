# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateTriggersForCiPipelineIids, feature_category: :continuous_integration do
  let(:pipelines) { table(:p_ci_pipelines, database: :ci, primary_key: :id) }
  let(:pipeline_iids) { table(:p_ci_pipeline_iids, database: :ci) }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(organization_id: organization.id, name: 'namespace', path: 'namespace') }
  let(:project) do
    table(:projects).create!(
      organization_id: organization.id, namespace_id: namespace.id, project_namespace_id: namespace.id)
  end

  let!(:pipeline_a_p100) { pipelines.create!(project_id: project.id, partition_id: 100, iid: 1) }
  let!(:pipeline_b_p100) { pipelines.create!(project_id: project.id, partition_id: 100, iid: 2) }
  let!(:pipeline_c_p101) { pipelines.create!(project_id: project.id, partition_id: 101, iid: 3) }
  let!(:pipeline_d_p101_nil_iid) { pipelines.create!(project_id: project.id, partition_id: 101, iid: nil) }

  before do
    migrate!

    # Ensure the iid records for existing pipelines are present
    pipeline_iids.insert_all([
      { project_id: project.id, iid: pipeline_a_p100.iid },
      { project_id: project.id, iid: pipeline_b_p100.iid },
      { project_id: project.id, iid: pipeline_c_p101.iid }
    ])

    # Add iid records for a different project just to ensure they're ignored in the tests
    pipeline_iids.insert_all([
      { project_id: project.id + 1, iid: 1 },
      { project_id: project.id + 1, iid: 2 },
      { project_id: project.id + 1, iid: 3 },
      { project_id: project.id + 1, iid: 4 }
    ])
  end

  shared_examples 'when the iid is a duplicate' do
    context 'when the iid is a duplicate on the same partition' do
      let(:new_iid) { pipeline_b_p100.iid }

      it 'raises a unique violation error' do
        expect { subject }
          .to not_change { pipeline_iids.pluck(:iid) }
          .and not_change { pipelines.pluck(:iid) }
          .and raise_error(ActiveRecord::RecordNotUnique,
            /Pipeline with iid #{new_iid} already exists for project #{project.id}/)
      end
    end

    context 'when the iid is a duplicate on a different partition' do
      let(:new_iid) { pipeline_c_p101.iid }

      it 'raises a unique violation error' do
        expect { subject }
          .to not_change { pipeline_iids.pluck(:iid) }
          .and not_change { pipelines.pluck(:iid) }
          .and raise_error(ActiveRecord::RecordNotUnique,
            /Pipeline with iid #{new_iid} already exists for project #{project.id}/)
      end
    end
  end

  describe 'ensure_pipeline_iid_uniqueness_before_insert trigger' do
    let(:new_iid) { new_unique_iid }
    let(:new_pipeline) { pipelines.build(project_id: project.id, partition_id: 100, iid: new_iid) }

    subject(:insert_pipeline!) { new_pipeline.save! }

    it 'inserts a new pipeline iid record' do
      expect { insert_pipeline! }
        .to change { pipeline_iids.count }.by(1)

      expect(new_pipeline.reload.iid).to eq(new_iid)
      expect(pipeline_iids.where(project_id: project.id).pluck(:iid))
        .to match_array([pipeline_a_p100.iid, pipeline_b_p100.iid, pipeline_c_p101.iid, new_iid])
    end

    it_behaves_like 'when the iid is a duplicate'

    context 'when the iid is NULL' do
      let(:new_iid) { nil }

      it 'does not insert a new pipeline iid record' do
        expect { insert_pipeline! }
          .to not_change { pipeline_iids.pluck(:iid) }

        expect(new_pipeline.reload.iid).to be_nil
      end
    end
  end

  describe 'ensure_pipeline_iid_uniqueness_before_update_iid trigger' do
    let(:new_iid) { new_unique_iid }

    subject(:update_pipeline_iid!) { pipeline_a_p100.update!(iid: new_iid) }

    it 'inserts a new pipeline iid record and deletes the old one' do
      expect { update_pipeline_iid! }
        .not_to change { pipeline_iids.count }

      expect(pipeline_a_p100.reload.iid).to eq(new_iid)
      expect(pipeline_iids.where(project_id: project.id).pluck(:iid))
        .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid, new_iid])
    end

    it_behaves_like 'when the iid is a duplicate'

    context 'when the iid is not being changed' do
      let(:new_iid) { pipeline_a_p100.iid }

      it 'does not change the pipeline iid records' do
        expect { update_pipeline_iid! }
          .to not_change { pipeline_iids.pluck(:iid) }
          .and not_change { pipelines.pluck(:iid) }
      end
    end

    context 'when the iid is updated to NULL' do
      let(:new_iid) { nil }

      it 'deletes the old pipeline iid record and does not insert a new one' do
        expect { update_pipeline_iid! }
          .to change { pipeline_iids.count }.by(-1)

        expect(pipeline_a_p100.reload.iid).to be_nil
        expect(pipeline_iids.where(project_id: project.id).pluck(:iid))
          .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid])
      end
    end

    context 'when the iid is updated from NULL to non-NULL' do
      let(:new_iid) { new_unique_iid }

      it 'inserts a new pipeline iid record and does not delete any existing one' do
        expect { pipeline_d_p101_nil_iid.update!(iid: new_iid) }
          .to change { pipeline_iids.count }.by(1)

        expect(pipeline_d_p101_nil_iid.reload.iid).to eq(new_iid)
        expect(pipeline_iids.where(project_id: project.id).pluck(:iid))
          .to match_array([pipeline_a_p100.iid, pipeline_b_p100.iid, pipeline_c_p101.iid, new_iid])
      end
    end
  end

  describe 'cleanup_pipeline_iid_after_delete' do
    it 'deletes the pipeline iid record' do
      expect { pipeline_a_p100.delete }
        .to change { pipeline_iids.count }.by(-1)

      expect(pipelines.where(project_id: project.id).pluck(:iid))
        .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid, pipeline_d_p101_nil_iid.iid])
      expect(pipeline_iids.where(project_id: project.id).pluck(:iid))
        .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid])
    end

    context 'when the deleted pipeline had a NULL iid' do
      it 'does not change the pipeline iid records' do
        expect { pipeline_d_p101_nil_iid.delete }
          .to not_change { pipeline_iids.pluck(:iid) }
      end
    end
  end

  private

  def new_unique_iid
    pipelines.where(project_id: project.id).maximum(:iid) + 1
  end
end
