# frozen_string_literal: true

require 'spec_helper'

describe PipelineDetailsEntity do
  set(:user) { create(:user) }
  let(:request) { double('request') }

  it 'inherrits from PipelineEntity' do
    expect(described_class).to be < PipelineEntity
  end

  before do
    stub_not_protect_default_branch

    allow(request).to receive(:current_user).and_return(user)
  end

  let(:entity) do
    described_class.represent(pipeline, request: request)
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
          .to include :stages, :artifacts, :manual_actions, :scheduled_actions
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
      let(:build) { create(:ci_build, pipeline: pipeline) }

      before do
        create(:ci_sources_pipeline, source_job: build)
        create(:ci_sources_pipeline, source_job: build)
      end

      it 'contains an information about depedent pipeline' do
        expect(subject[:triggered]).to be_a(Array)
        expect(subject[:triggered].length).to eq(2)
        expect(subject[:triggered].first[:path]).not_to be_nil
        expect(subject[:triggered].first[:details]).not_to be_nil
        expect(subject[:triggered].first[:details][:status]).not_to be_nil
        expect(subject[:triggered].first[:project]).not_to be_nil
      end
    end
  end
end
