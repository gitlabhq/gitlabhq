# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProcessPipelineService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project)
  end

  subject { described_class.new(pipeline) }

  before do
    stub_ci_pipeline_to_return_yaml_file
    stub_not_protect_default_branch

    project.add_developer(user)
  end

  describe 'processing events counter' do
    let(:metrics) { double('pipeline metrics') }
    let(:counter) { double('events counter') }

    before do
      allow(subject)
        .to receive(:metrics).and_return(metrics)
      allow(metrics)
        .to receive(:pipeline_processing_events_counter)
        .and_return(counter)
    end

    it 'increments processing events counter' do
      expect(counter).to receive(:increment)

      subject.execute
    end
  end

  describe 'updating a list of retried builds' do
    let!(:build_retried) { create_build('build') }
    let!(:build) { create_build('build') }
    let!(:test) { create_build('test') }

    it 'returns unique statuses' do
      subject.execute

      expect(all_builds.latest).to contain_exactly(build, test)
      expect(all_builds.retried).to contain_exactly(build_retried)
    end

    def create_build(name, **opts)
      create(:ci_build, :created, pipeline: pipeline, name: name, **opts)
    end

    def all_builds
      pipeline.builds.order(:stage_idx, :id)
    end
  end
end
