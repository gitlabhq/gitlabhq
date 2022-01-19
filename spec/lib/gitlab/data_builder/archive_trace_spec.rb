# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::ArchiveTrace do
  let_it_be(:build) { create(:ci_build, :trace_artifact) }

  describe '.build' do
    let(:data) { described_class.build(build) }

    it 'has correct attributes', :aggregate_failures do
      expect(data[:object_kind]).to eq 'archive_trace'
      expect(data[:trace_url]).to eq build.job_artifacts_trace.file.url
      expect(data[:build_id]).to eq build.id
      expect(data[:pipeline_id]).to eq build.pipeline_id
      expect(data[:project]).to eq build.project.hook_attrs
    end
  end
end
