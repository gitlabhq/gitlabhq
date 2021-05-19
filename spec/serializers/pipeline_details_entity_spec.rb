# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineDetailsEntity do
  let_it_be(:user) { create(:user) }

  let(:request) { double('request') }

  let(:entity) do
    described_class.represent(pipeline, request: request)
  end

  it 'inherits from PipelineEntity' do
    expect(described_class).to be < Ci::PipelineEntity
  end

  before do
    stub_not_protect_default_branch

    allow(request).to receive(:current_user).and_return(user)
  end

  describe '#as_json' do
    subject { entity.as_json }

    context 'when pipeline is empty' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      it 'contains details' do
        expect(subject).to include :details
        expect(subject[:details])
          .to include :duration, :finished_at
        expect(subject[:details])
          .to include :stages, :manual_actions, :scheduled_actions
        expect(subject[:details][:status]).to include :icon, :favicon, :text, :label
      end

      it 'contains flags' do
        expect(subject).to include :flags
        expect(subject[:flags])
          .to include :latest, :stuck,
                      :yaml_errors, :retryable, :cancelable
      end
    end

    context 'when pipeline is retryable' do
      let(:project) { create(:project) }

      let(:pipeline) do
        create(:ci_pipeline, status: :success, project: project)
      end

      before do
        create(:ci_build, :failed, pipeline: pipeline)
      end

      context 'user has ability to retry pipeline' do
        before do
          project.add_developer(user)
        end

        it 'retryable flag is true' do
          expect(subject[:flags][:retryable]).to eq true
        end
      end

      context 'user does not have ability to retry pipeline' do
        it 'retryable flag is false' do
          expect(subject[:flags][:retryable]).to eq false
        end
      end

      it 'does not contain code_quality_build_path in details' do
        expect(subject[:details]).not_to include :code_quality_build_path
      end

      context 'when option code_quality_walkthrough is set and pipeline is a success' do
        let(:entity) do
          described_class.represent(pipeline, request: request, code_quality_walkthrough: true)
        end

        it 'contains details.code_quality_build_path' do
          expect(subject[:details]).to include :code_quality_build_path
        end
      end
    end

    context 'when pipeline is cancelable' do
      let(:project) { create(:project) }

      let(:pipeline) do
        create(:ci_pipeline, status: :running, project: project)
      end

      before do
        create(:ci_build, :pending, pipeline: pipeline)
      end

      context 'user has ability to cancel pipeline' do
        before do
          project.add_developer(user)
        end

        it 'cancelable flag is true' do
          expect(subject[:flags][:cancelable]).to eq true
        end
      end

      context 'user does not have ability to cancel pipeline' do
        it 'cancelable flag is false' do
          expect(subject[:flags][:cancelable]).to eq false
        end
      end
    end

    context 'when pipeline has commit statuses' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        create(:generic_commit_status, pipeline: pipeline)
      end

      it 'contains stages' do
        expect(subject).to include(:details)
        expect(subject[:details]).to include(:stages)
        expect(subject[:details][:stages].first).to include(name: 'test')
      end
    end

    context 'when pipeline has YAML errors' do
      let(:pipeline) do
        create(:ci_pipeline, yaml_errors: 'Some error occurred')
      end

      it 'contains information about error' do
        expect(subject[:yaml_errors]).to be_present
      end

      it 'contains flag that indicates there are errors' do
        expect(subject[:flags][:yaml_errors]).to be true
      end
    end

    context 'when pipeline does not have YAML errors' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      it 'does not contain field that normally holds an error' do
        expect(subject).not_to have_key(:yaml_errors)
      end

      it 'contains flag that indicates there are no errors' do
        expect(subject[:flags][:yaml_errors]).to be false
      end
    end

    context 'when pipeline is triggered by other pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        create(:ci_sources_pipeline, pipeline: pipeline)
      end

      it 'contains an information about depedent pipeline' do
        expect(subject[:triggered_by]).to be_a(Hash)
        expect(subject[:triggered_by][:path]).not_to be_nil
        expect(subject[:triggered_by][:details]).not_to be_nil
        expect(subject[:triggered_by][:details][:status]).not_to be_nil
        expect(subject[:triggered_by][:project]).not_to be_nil
      end
    end

    context 'when pipeline triggered other pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline) }
      let(:build) { create(:ci_build, name: 'child', stage: 'test', pipeline: pipeline) }
      let(:bridge) { create(:ci_bridge, name: 'cross-project', stage: 'build', pipeline: pipeline) }
      let(:child_pipeline) { create(:ci_pipeline, project: pipeline.project) }
      let(:cross_project_pipeline) { create(:ci_pipeline) }

      before do
        create(:ci_sources_pipeline, source_job: build, pipeline: child_pipeline)
        create(:ci_sources_pipeline, source_job: bridge, pipeline: cross_project_pipeline)
      end

      it 'contains an information about dependent pipeline', :aggregate_failures do
        expect(subject[:triggered]).to be_a(Array)
        expect(subject[:triggered].length).to eq(2)
        expect(subject[:triggered].first[:path]).not_to be_nil
        expect(subject[:triggered].first[:details]).not_to be_nil
        expect(subject[:triggered].first[:details][:status]).not_to be_nil
        expect(subject[:triggered].first[:project]).not_to be_nil

        source_jobs = subject[:triggered]
          .index_by { |pipeline| pipeline[:id] }
          .transform_values { |pipeline| pipeline.fetch(:source_job) }

        expect(source_jobs[cross_project_pipeline.id][:name]).to eq('cross-project')
        expect(source_jobs[child_pipeline.id][:name]).to eq('child')
      end
    end
  end
end
