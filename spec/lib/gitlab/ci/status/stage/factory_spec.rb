# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::Stage::Factory do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:stage) do
    build(:ci_stage, pipeline: pipeline, name: 'test')
  end

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
    (HasStatus::AVAILABLE_STATUSES - %w(manual skipped scheduled)).each do |core_status|
      context "when core status is #{core_status}" do
        before do
          create(:ci_build, pipeline: pipeline, stage: 'test', status: core_status)
          create(:commit_status, pipeline: pipeline, stage: 'test', status: core_status)
          create(:ci_build, pipeline: pipeline, stage: 'build', status: :failed)
        end

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
      build(:ci_stage, name: 'test', status: :success, pipeline: pipeline)
    end

    before do
      create(:ci_build, :allowed_to_fail, :failed,
             stage: 'test', pipeline: stage.pipeline)
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
    (HasStatus::BLOCKED_STATUS + ['skipped']).each do |core_status|
      context "when status is #{core_status}" do
        before do
          create(:ci_build, pipeline: pipeline, stage: 'test', status: core_status)
          create(:commit_status, pipeline: pipeline, stage: 'test', status: core_status)
          create(:ci_build, pipeline: pipeline, stage: 'build', status: :manual)
        end

        it 'fabricates a play manual status' do
          expect(status).to be_a(Gitlab::Ci::Status::Stage::PlayManual)
        end
      end
    end
  end
end
