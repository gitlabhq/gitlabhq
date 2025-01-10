# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PipelineEntity do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, name: 'Build pipeline') }

  let(:request) { double('request') }

  before do
    stub_not_protect_default_branch

    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
    allow(pipeline).to receive(:coverage).and_return(35.0)
  end

  let(:entity) do
    described_class.represent(pipeline, request: request)
  end

  subject { entity.as_json }

  describe '#as_json' do
    it 'contains required fields' do
      allow(pipeline).to receive(:merge_request_event_type).and_return(:merged_result)

      is_expected.to include(
        :id, :iid, :project_path, :path, :active, :coverage, :ref, :commit, :details,
        :flags, :triggered, :triggered_by, :name
      )
      expect(subject[:commit]).to include(:short_id, :commit_path)
      expect(subject[:ref]).to include(:branch)
      expect(subject[:details]).to include(:artifacts, :event_type_name, :status, :stages, :finished_at)
      expect(subject[:details][:status]).to include(:icon, :favicon, :text, :label, :tooltip)
      expect(subject[:flags]).to include(:merge_request_pipeline, :merged_result_pipeline, :merge_train_pipeline)

      expect(subject[:details][:event_type_name]).to eq('Merged results pipeline')
    end

    it 'returns presented coverage' do
      expect(subject[:coverage]).to eq('35.00')
    end

    it 'excludes coverage data when disabled' do
      entity = described_class
        .represent(pipeline, request: request, disable_coverage: true)

      expect(entity.as_json).not_to include(:coverage)
    end
  end
end
