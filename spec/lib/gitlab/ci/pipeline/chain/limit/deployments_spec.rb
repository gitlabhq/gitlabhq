# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::Deployments do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, namespace: namespace) }
  let_it_be(:plan_limits, reload: true) { create(:plan_limits, :default_plan) }

  let(:stage_seeds) do
    [
      double(:test, seeds: [
        double(:test, attributes: {})
      ]),
      double(:staging, seeds: [
        double(:staging, attributes: { environment: 'staging' })
      ]),
      double(:production, seeds: [
        double(:production, attributes: { environment: 'production' })
      ])
    ]
  end

  let(:save_incompleted) { false }

  let(:command) do
    double(:command,
      project: project,
      stage_seeds: stage_seeds,
      save_incompleted: save_incompleted
    )
  end

  let(:pipeline) { build(:ci_pipeline, project: project) }
  let(:step) { described_class.new(pipeline, command) }

  subject(:perform) { step.perform! }

  context 'when pipeline deployments limit is exceeded' do
    before do
      plan_limits.update!(ci_pipeline_deployments: 1)
    end

    context 'when saving incompleted pipelines' do
      let(:save_incompleted) { true }

      it 'drops the pipeline' do
        perform

        expect(pipeline).to be_persisted
        expect(pipeline.reload).to be_failed
      end

      it 'breaks the chain' do
        perform

        expect(step.break?).to be true
      end

      it 'sets a valid failure reason' do
        perform

        expect(pipeline.deployments_limit_exceeded?).to be true
      end
    end

    context 'when not saving incomplete pipelines' do
      let(:save_incompleted) { false }

      it 'does not persist the pipeline' do
        perform

        expect(pipeline).not_to be_persisted
      end

      it 'breaks the chain' do
        perform

        expect(step.break?).to be true
      end

      it 'adds an informative error to the pipeline' do
        perform

        expect(pipeline.errors.messages).to include(base: ['Pipeline has too many deployments! Requested 2, but the limit is 1.'])
      end
    end

    it 'logs the error' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Gitlab::Ci::Limit::LimitExceededError),
        project_id: project.id, plan: namespace.actual_plan_name
      )

      perform
    end
  end

  context 'when pipeline deployments limit is not exceeded' do
    before do
      plan_limits.update!(ci_pipeline_deployments: 100)
    end

    it 'does not break the chain' do
      perform

      expect(step.break?).to be false
    end

    it 'does not invalidate the pipeline' do
      perform

      expect(pipeline.errors).to be_empty
    end

    it 'does not log any error' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

      perform
    end
  end
end
