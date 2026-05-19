# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProjectMetric, feature_category: :pipeline_composition do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'factory' do
    it 'creates a valid record' do
      expect(build(:ci_project_metric)).to be_valid
    end

    it 'creates a valid record with first_pipeline_succeeded trait' do
      metric = build(:ci_project_metric, :with_first_pipeline_succeeded)

      expect(metric).to be_valid
      expect(metric.first_pipeline_succeeded_at).to be_present
    end
  end

  describe '.first_pipeline_success_recorded?' do
    let_it_be(:project) { create(:project) }

    context 'when no record exists for the project' do
      it 'returns false' do
        expect(described_class.first_pipeline_success_recorded?(project.id)).to be(false)
      end
    end

    context 'when a record exists with first_pipeline_succeeded_at set' do
      before do
        create(:ci_project_metric, :with_first_pipeline_succeeded, project: project)
      end

      it 'returns true' do
        expect(described_class.first_pipeline_success_recorded?(project.id)).to be(true)
      end
    end

    context 'when a record exists with nil first_pipeline_succeeded_at' do
      before do
        create(:ci_project_metric, project: project, first_pipeline_succeeded_at: nil)
      end

      it 'returns false' do
        expect(described_class.first_pipeline_success_recorded?(project.id)).to be(false)
      end
    end
  end

  describe '.record_first_pipeline_success!' do
    let_it_be(:project) { create(:project) }

    context 'when no record exists for the project' do
      it 'creates a record with first_pipeline_succeeded_at set' do
        freeze_time do
          described_class.record_first_pipeline_success!(project.id)

          metric = described_class.find_by(project_id: project.id)
          expect(metric.first_pipeline_succeeded_at).to eq(Time.current)
        end
      end
    end

    context 'when a record already exists for the project with a timestamp' do
      before do
        create(:ci_project_metric, :with_first_pipeline_succeeded, project: project)
      end

      it 'keeps exactly one record' do
        described_class.record_first_pipeline_success!(project.id)

        expect(described_class.where(project_id: project.id).count).to eq(1)
      end
    end

    context 'when a record already exists with nil first_pipeline_succeeded_at' do
      before do
        create(:ci_project_metric, project: project, first_pipeline_succeeded_at: nil)
      end

      it 'sets first_pipeline_succeeded_at on the existing row' do
        freeze_time do
          described_class.record_first_pipeline_success!(project.id)

          expect(described_class.find_by(project_id: project.id).first_pipeline_succeeded_at).to eq(Time.current)
        end
      end
    end

    context 'when called multiple times for the same project' do
      it 'results in exactly one record' do
        2.times { described_class.record_first_pipeline_success!(project.id) }

        expect(described_class.where(project_id: project.id).count).to eq(1)
        expect(described_class.find_by(project_id: project.id).first_pipeline_succeeded_at).to be_present
      end
    end
  end
end
