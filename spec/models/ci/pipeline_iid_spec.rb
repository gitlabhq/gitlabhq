# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineIid, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  it 'prevents writes via model' do
    new_record = described_class.new(project: project, iid: 100)

    expect { new_record.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:pipeline) { create(:ci_pipeline, project: project) }
    let!(:model) { described_class.where(project: project).find_by(iid: pipeline.iid) }
    let!(:parent) { model.project }
  end

  describe 'database triggers on p_ci_pipelines' do
    let_it_be_with_reload(:pipeline_a_p100) { create(:ci_pipeline, project: project, partition_id: 100, iid: 1) }
    let_it_be_with_reload(:pipeline_b_p100) { create(:ci_pipeline, project: project, partition_id: 100, iid: 2) }
    let_it_be_with_reload(:pipeline_c_p101) { create(:ci_pipeline, project: project, partition_id: 101, iid: 3) }
    let_it_be_with_reload(:pipeline_d_p101_nil_iid) do
      create(:ci_pipeline, project: project, partition_id: 101).tap do |pipeline|
        # Pipeline factory automatically runs ensure_project_iid!, so we have to nullify it after build
        pipeline.update_column(:iid, nil)
      end
    end

    let(:new_iid) { described_class.where(project: project).maximum(:iid) + 1 }

    before do
      # Reset the state of ci_pipeline_iids to ensure consistency across tests
      described_class.delete_all
      described_class.insert_all([
        { project_id: project.id, iid: pipeline_a_p100.iid },
        { project_id: project.id, iid: pipeline_b_p100.iid },
        { project_id: project.id, iid: pipeline_c_p101.iid }
      ])

      # Add iid records for another project just to ensure they're ignored in the tests
      other_project = create(:project)
      described_class.insert_all([
        { project_id: other_project.id, iid: 1 },
        { project_id: other_project.id, iid: 2 },
        { project_id: other_project.id, iid: 3 },
        { project_id: other_project.id, iid: 4 }
      ])
    end

    shared_examples 'when the iid is a duplicate' do
      context 'when the iid is a duplicate on the same partition' do
        let(:new_iid) { pipeline_b_p100.iid }

        it 'raises a unique violation error' do
          expect { subject }
            .to not_change { described_class.pluck(:iid) }
            .and not_change { Ci::Pipeline.pluck(:iid) }
            .and raise_error(ActiveRecord::RecordNotUnique,
              /Pipeline with iid #{new_iid} already exists for project #{project.id}/)
        end
      end

      context 'when the iid is a duplicate on a different partition' do
        let(:new_iid) { pipeline_c_p101.iid }

        it 'raises a unique violation error' do
          expect { subject }
            .to not_change { described_class.pluck(:iid) }
            .and not_change { Ci::Pipeline.pluck(:iid) }
            .and raise_error(ActiveRecord::RecordNotUnique,
              /Pipeline with iid #{new_iid} already exists for project #{project.id}/)
        end
      end
    end

    describe 'ensure_pipeline_iid_uniqueness_before_insert trigger' do
      let(:new_pipeline) { build(:ci_pipeline, project: project, partition_id: 100, iid: new_iid) }

      subject(:insert_pipeline!) { new_pipeline.save! }

      it 'inserts a new pipeline iid record' do
        expect { insert_pipeline! }
          .to change { described_class.count }.by(1)

        expect(new_pipeline.reload.iid).to eq(new_iid)
        expect(described_class.where(project: project).pluck(:iid))
          .to match_array([pipeline_a_p100.iid, pipeline_b_p100.iid, pipeline_c_p101.iid, new_iid])
      end

      it_behaves_like 'when the iid is a duplicate'
    end

    describe 'ensure_pipeline_iid_uniqueness_before_update_iid trigger' do
      subject(:update_pipeline_iid!) { pipeline_a_p100.update!(iid: new_iid) }

      it 'inserts a new pipeline iid record and deletes the old one' do
        expect { update_pipeline_iid! }
          .not_to change { described_class.count }

        expect(pipeline_a_p100.reload.iid).to eq(new_iid)
        expect(described_class.where(project: project).pluck(:iid))
          .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid, new_iid])
      end

      it_behaves_like 'when the iid is a duplicate'

      context 'when the iid is not being changed' do
        let(:new_iid) { pipeline_a_p100.iid }

        it 'does not change the pipeline iid records' do
          expect { update_pipeline_iid! }
            .to not_change { described_class.pluck(:iid) }
            .and not_change { Ci::Pipeline.pluck(:iid) }
        end
      end

      context 'when the iid is updated to NULL' do
        let(:new_iid) { nil }

        it 'deletes the old pipeline iid record and does not insert a new one' do
          expect { update_pipeline_iid! }
            .to change { described_class.count }.by(-1)

          expect(pipeline_a_p100.reload.iid).to be_nil
          expect(described_class.where(project: project).pluck(:iid))
            .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid])
        end
      end

      context 'when the iid is updated from NULL to non-NULL' do
        it 'inserts a new pipeline iid record and does not delete any existing one' do
          expect { pipeline_d_p101_nil_iid.update!(iid: new_iid) }
            .to change { described_class.count }.by(1)

          expect(pipeline_d_p101_nil_iid.reload.iid).to eq(new_iid)
          expect(described_class.where(project: project).pluck(:iid))
            .to match_array([pipeline_a_p100.iid, pipeline_b_p100.iid, pipeline_c_p101.iid, new_iid])
        end
      end
    end

    describe 'cleanup_pipeline_iid_after_delete' do
      it 'deletes the pipeline iid record' do
        expect { pipeline_a_p100.delete }
          .to change { described_class.count }.by(-1)

        expect(Ci::Pipeline.where(project: project).pluck(:iid))
          .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid, pipeline_d_p101_nil_iid.iid])
        expect(described_class.where(project: project).pluck(:iid))
          .to match_array([pipeline_b_p100.iid, pipeline_c_p101.iid])
      end

      context 'when the deleted pipeline had a NULL iid' do
        it 'does not change the pipeline iid records' do
          expect { pipeline_d_p101_nil_iid.delete }
            .to not_change { described_class.pluck(:iid) }

          expect(Ci::Pipeline.where(project: project).pluck(:iid))
            .to match_array([pipeline_a_p100.iid, pipeline_b_p100.iid, pipeline_c_p101.iid])
        end
      end
    end
  end
end
