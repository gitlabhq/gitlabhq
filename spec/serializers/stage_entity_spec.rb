# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StageEntity, feature_category: :continuous_integration do
  let(:pipeline) { create(:ci_pipeline) }
  let(:request) { double('request') }
  let(:user) { create(:user) }

  let(:entity) do
    described_class.new(stage, request: request)
  end

  let(:stage) do
    create(:ci_stage, pipeline: pipeline, status: :success)
  end

  before do
    allow(request).to receive(:current_user).and_return(user)
    create(:ci_build, :success, pipeline: pipeline, stage_id: stage.id)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains relevant fields' do
      expect(subject).to include :name, :status, :path
    end

    it 'contains detailed status' do
      expect(subject[:status]).to include :text, :label, :group, :icon, :tooltip
      expect(subject[:status][:label]).to eq s_('CiStatusLabel|passed')
    end

    it 'contains valid name' do
      expect(subject[:name]).to eq 'test'
    end

    it 'contains valid id' do
      expect(subject[:id]).to eq stage.id
    end

    it 'contains path to the stage' do
      expect(subject[:path])
        .to include "pipelines/#{pipeline.id}##{stage.name}"
    end

    it 'contains path to the stage dropdown' do
      expect(subject[:dropdown_path])
        .to include "pipelines/#{pipeline.id}/stage.json?stage=test"
    end

    it 'contains stage title' do
      expect(subject[:title]).to eq "test: #{s_('CiStatusLabel|passed')}"
    end

    it 'does not contain play_details info' do
      expect(subject[:status][:action]).not_to be_present
    end

    context 'when the jobs should be grouped' do
      let(:entity) { described_class.new(stage, request: request, grouped: true) }

      it 'exposes the group key' do
        expect(subject).to include :groups
      end

      context 'and contains commit status' do
        before do
          create(:generic_commit_status, pipeline: pipeline, ci_stage: stage)
        end

        it 'contains commit status' do
          groups = subject[:groups].map { |group| group[:name] }
          expect(groups).to include('generic')
        end
      end
    end

    context 'with a skipped stage ' do
      let(:stage) { create(:ci_stage, status: 'skipped') }

      it 'contains play_all_manual' do
        expect(subject[:status][:action]).to be_present
      end
    end

    context 'with a scheduled stage ' do
      let(:stage) { create(:ci_stage, status: 'scheduled') }

      it 'contains play_all_manual' do
        expect(subject[:status][:action]).to be_present
      end
    end

    context 'with a manual stage ' do
      let(:stage) { create(:ci_stage, status: 'manual') }

      it 'contains play_all_manual' do
        expect(subject[:status][:action]).to be_present
      end
    end

    context 'when details: true' do
      def serialize(stage)
        described_class.new(stage, request: request, details: true).as_json
      end

      it 'avoids N+1 queries on latest_statuses', :use_sql_query_cache, :request_store do
        pipeline = create(:ci_pipeline)
        stage = create(:ci_stage, pipeline: pipeline, status: :success)

        serialize(stage) # Warm up O(1) queries

        # Prepare control
        create(:ci_build, :tags, ci_stage: stage, pipeline: pipeline)
        create(:ci_bridge, ci_stage: stage, pipeline: pipeline)
        create(:generic_commit_status, ci_stage: stage, pipeline: pipeline)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          serialize(stage)
        end

        # Prepare sample using a generous number to counteract any caches from
        # the control
        create_list(:ci_build, 10, :tags, ci_stage: stage, pipeline: pipeline)
        create_list(:ci_bridge, 10, ci_stage: stage, pipeline: pipeline)
        create_list(:generic_commit_status, 10, ci_stage: stage, pipeline: pipeline)

        expect { serialize(stage) }.not_to exceed_query_limit(control)
      end
    end

    context 'when details: true and retried: true' do
      let(:pipeline) { create(:ci_pipeline) }
      let(:stage) { create(:ci_stage, pipeline: pipeline, status: :success) }
      let(:entity) { described_class.new(stage, request: request, details: true, retried: true) }

      before do
        create(:ci_build, :success, pipeline: pipeline, stage_id: stage.id, name: 'latest_job')
        create(:ci_build, :retried, pipeline: pipeline, stage_id: stage.id, name: 'retried_job')
        create(:ci_build, :failed, pipeline: pipeline, stage_id: stage.id, name: 'failed_job')
      end

      it 'exposes latest_statuses and retried' do
        result = entity.as_json

        expect(result).to include(:latest_statuses, :retried)
        expect(result[:latest_statuses].map { |job| job[:name] }).to include('failed_job', 'latest_job')
        expect(result[:retried].map { |job| job[:name] }).to eq(['retried_job'])
      end

      it 'does not expose latest_statuses when details is false' do
        result = described_class.new(stage, request: request, retried: true).as_json

        expect(result).not_to include(:latest_statuses)
        expect(result).to include(:retried)
      end

      it 'does not expose retried when retried is false' do
        result = described_class.new(stage, request: request, details: true).as_json

        expect(result).to include(:latest_statuses)
        expect(result).not_to include(:retried)
      end
    end
  end
end
