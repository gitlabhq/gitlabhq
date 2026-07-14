# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProjectMetric, feature_category: :pipeline_composition do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it 'allows ci_config_generated_by to be nil' do
      expect(build(:ci_project_metric, ci_config_generated_by: nil)).to be_valid
    end

    it 'allows ci_config_generated_by with a valid value' do
      expect(build(:ci_project_metric, ci_config_generated_by: 'ci_expert_agent/v1')).to be_valid
    end

    it 'rejects ci_config_generated_by exceeding 255 characters' do
      expect(build(:ci_project_metric, ci_config_generated_by: 'a' * 256)).not_to be_valid
    end
  end

  describe '.ci_config_generated_by_for' do
    let_it_be(:project) { create(:project) }

    context 'when a ci_project_metrics record exists with a stored value' do
      before do
        create(:ci_project_metric, :ai_generated, project: project)
      end

      it 'returns the stored ci_config_generated_by value' do
        expect(described_class.ci_config_generated_by_for(project.id)).to eq('ci_expert_agent/v1')
      end
    end

    context 'when no ci_project_metrics record exists' do
      it 'returns nil' do
        expect(described_class.ci_config_generated_by_for(project.id)).to be_nil
      end
    end

    context 'when a record exists with nil ci_config_generated_by' do
      before do
        create(:ci_project_metric, project: project, ci_config_generated_by: nil)
      end

      it 'returns nil' do
        expect(described_class.ci_config_generated_by_for(project.id)).to be_nil
      end
    end
  end

  describe '.track_ai_generated_config!' do
    let_it_be(:project) { create(:project) }

    it 'creates a new record when none exists for the project' do
      expect do
        described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')
      end.to change { described_class.count }.by(1)
    end

    it 'sets ci_config_generated_by to the given value' do
      described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')

      expect(described_class.find_by(project_id: project.id).ci_config_generated_by).to eq('ci_expert_agent/v1')
    end

    it 'does not raise on conflict for an existing project record' do
      create(:ci_project_metric, project: project, ci_config_generated_by: nil)

      expect do
        described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')
      end.not_to raise_error
    end

    it 'does not overwrite first_pipeline_succeeded_at on existing records' do
      succeeded_at = 1.day.ago
      create(:ci_project_metric, project: project, first_pipeline_succeeded_at: succeeded_at)

      described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')

      metric = described_class.find_by(project_id: project.id)
      expect(metric.first_pipeline_succeeded_at).to be_within(1.second).of(succeeded_at)
    end

    it 'does not create or update for an unknown agent source' do
      expect do
        result = described_class.track_ai_generated_config!(project.id, author_source: 'fake_agent')
        expect(result).to be_nil
      end.not_to change { described_class.count }
    end

    it 'rejects empty string' do
      expect do
        result = described_class.track_ai_generated_config!(project.id, author_source: '')
        expect(result).to be_nil
      end.not_to change { described_class.count }
    end

    it 'rejects nil' do
      expect do
        result = described_class.track_ai_generated_config!(project.id, author_source: nil)
        expect(result).to be_nil
      end.not_to change { described_class.count }
    end

    it 'rejects arbitrary user input' do
      expect do
        result = described_class.track_ai_generated_config!(project.id, author_source: 'some_random_agent/v99')
        expect(result).to be_nil
      end.not_to change { described_class.count }
    end

    describe 'ci_config_first_generated_at' do
      it 'sets ci_config_first_generated_at on insert' do
        freeze_time do
          described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')

          metric = described_class.find_by(project_id: project.id)
          expect(metric.ci_config_first_generated_at).to be_like_time(Time.current)
        end
      end

      it 'preserves the original ci_config_first_generated_at when called again' do
        first_generated_at = travel_to(2.days.ago) do
          described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')
          described_class.find_by(project_id: project.id).ci_config_first_generated_at
        end

        described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')

        expect(described_class.find_by(project_id: project.id).ci_config_first_generated_at)
          .to be_within(1.second).of(first_generated_at)
      end

      it 'backfills ci_config_first_generated_at on an existing row where it is nil', :aggregate_failures do
        create(:ci_project_metric, project: project, ci_config_generated_by: nil, ci_config_first_generated_at: nil)

        freeze_time do
          described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')

          metric = described_class.find_by(project_id: project.id)
          expect(metric.ci_config_generated_by).to eq('ci_expert_agent/v1')
          expect(metric.ci_config_first_generated_at).to be_like_time(Time.current)
        end
      end

      it 'updates ci_config_generated_by to the latest agent, preserving the first timestamp', :aggregate_failures do
        stub_const('Ci::ProjectMetric::KNOWN_AGENT_SOURCES', %w[ci_expert_agent/v1 ci_expert_agent/v2])

        first_generated_at = travel_to(2.days.ago) do
          described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')
          described_class.find_by(project_id: project.id).ci_config_first_generated_at
        end

        described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v2')

        metric = described_class.find_by(project_id: project.id)
        expect(metric.ci_config_generated_by).to eq('ci_expert_agent/v2')
        expect(metric.ci_config_first_generated_at).to be_within(1.second).of(first_generated_at)
      end
    end
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

    it 'creates a valid record with ai_generated trait' do
      metric = build(:ci_project_metric, :ai_generated)

      expect(metric).to be_valid
      expect(metric.ci_config_generated_by).to eq('ci_expert_agent/v1')
    end
  end

  describe 'integration' do
    it 'tracks, upserts, and preserves other columns correctly' do
      project = create(:project)
      succeeded_at = 2.days.ago

      described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')

      metric = described_class.find_by!(project_id: project.id)
      expect(metric.ci_config_generated_by).to eq('ci_expert_agent/v1')

      metric.update!(first_pipeline_succeeded_at: succeeded_at)

      described_class.track_ai_generated_config!(project.id, author_source: 'ci_expert_agent/v1')

      expect(described_class.where(project_id: project.id).count).to eq(1)

      metric.reload
      expect(metric.ci_config_generated_by).to eq('ci_expert_agent/v1')
      expect(metric.first_pipeline_succeeded_at).to be_within(1.second).of(succeeded_at)
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

  describe '.mark_ai_pipeline_results_viewed' do
    let_it_be(:project) { create(:project) }
    let(:pipeline_created_at) { Time.current }

    subject(:mark) { described_class.mark_ai_pipeline_results_viewed(project.id, pipeline_created_at) }

    context 'when the project is eligible' do
      let!(:metric) do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: 1.hour.ago)
      end

      it 'updates the row and returns 1' do
        freeze_time do
          expect(mark).to eq(1)
          expect(metric.reload.first_ai_pipeline_results_viewed_at).to eq(Time.current)
        end
      end
    end

    context 'when the config commit time equals the pipeline creation time (boundary)' do
      before do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: pipeline_created_at)
      end

      it { is_expected.to eq(1) }
    end

    context 'when the view was already recorded' do
      let(:viewed_at) { 2.days.ago }
      let!(:metric) do
        create(:ci_project_metric, :ai_generated, project: project,
          ci_config_first_generated_at: 1.hour.ago, first_ai_pipeline_results_viewed_at: viewed_at)
      end

      it 'returns 0 and preserves the original timestamp (first-wins)' do
        expect(mark).to eq(0)
        expect(metric.reload.first_ai_pipeline_results_viewed_at).to be_within(1.second).of(viewed_at)
      end
    end

    context 'when no agent is on record' do
      before do
        create(:ci_project_metric, project: project, ci_config_first_generated_at: 1.hour.ago)
      end

      it { is_expected.to eq(0) }
    end

    context 'when the AI config commit time is not recorded' do
      before do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: nil)
      end

      it { is_expected.to eq(0) }
    end

    context 'when the pipeline predates the AI config commit' do
      before do
        create(:ci_project_metric, :ai_generated, project: project, ci_config_first_generated_at: 1.hour.from_now)
      end

      it { is_expected.to eq(0) }
    end

    context 'when no metric row exists' do
      it { is_expected.to eq(0) }
    end
  end
end
