# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PipelineEntity do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:request) { double('request') }

  before do
    stub_not_protect_default_branch

    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
  end

  let(:entity) do
    described_class.represent(pipeline, request: request)
  end

  subject { entity.as_json }

  describe '#as_json' do
    it 'contains required fields' do
      is_expected.to include(
        :id, :path, :active, :coverage, :ref, :commit, :details,
        :flags, :triggered, :triggered_by
      )
      expect(subject[:commit]).to include(:short_id, :commit_path)
      expect(subject[:ref]).to include(:branch)
      expect(subject[:details]).to include(:artifacts, :name, :status, :stages, :finished_at)
      expect(subject[:details][:status]).to include(:icon, :favicon, :text, :label, :tooltip)
      expect(subject[:flags]).to include(:merge_request_pipeline)
    end

    it 'excludes coverage data when disabled' do
      entity = described_class
        .represent(pipeline, request: request, disable_coverage: true)

      expect(entity.as_json).not_to include(:coverage)
    end
  end
end
