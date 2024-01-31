# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Stage::Factory, feature_category: :continuous_integration do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:stage) { create(:ci_stage, pipeline: pipeline) }

  subject do
    described_class.new(stage, user)
  end

  let(:status) do
    subject.fabricate!
  end

  before do
    project.add_developer(user)
  end

  context 'when stage has a core status' do
    (Ci::HasStatus::AVAILABLE_STATUSES - %w[manual skipped scheduled]).each do |core_status|
      context "when core status is #{core_status}" do
        let(:stage) { create(:ci_stage, pipeline: pipeline, status: core_status) }

        it "fabricates a core status #{core_status}" do
          expect(status).to be_a(
            Gitlab::Ci::Status.const_get(core_status.camelize, false))
        end

        it 'extends core status with common stage methods' do
          expect(status).to have_details
          expect(status.details_path).to include "pipelines/#{pipeline.id}"
          expect(status.details_path).to include "##{stage.name}"
        end
      end
    end
  end

  context 'when stage has warnings' do
    let(:stage) do
      create(:ci_stage, status: :success, pipeline: pipeline)
    end

    before do
      create(:ci_build, :allowed_to_fail, :failed, stage_id: stage.id, pipeline: stage.pipeline)
    end

    it 'fabricates extended "success with warnings" status' do
      expect(status)
        .to be_a Gitlab::Ci::Status::SuccessWarning
    end

    it 'extends core status with common stage method' do
      expect(status).to have_details
      expect(status.details_path).to include "pipelines/#{pipeline.id}##{stage.name}"
    end
  end

  context 'when stage has manual builds' do
    (Ci::HasStatus::BLOCKED_STATUS + ['skipped']).each do |core_status|
      context "when status is #{core_status}" do
        let(:stage) { create(:ci_stage, pipeline: pipeline, status: core_status) }

        it 'fabricates a play manual status' do
          expect(status).to be_a(Gitlab::Ci::Status::Stage::PlayManual)
        end
      end
    end
  end
end
