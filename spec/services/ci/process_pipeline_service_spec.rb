# frozen_string_literal: true

require 'spec_helper'

describe Ci::ProcessPipelineService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project)
  end

  before do
    stub_ci_pipeline_to_return_yaml_file

    stub_not_protect_default_branch

    project.add_developer(user)
  end

  context 'updates a list of retried builds' do
    subject { described_class.retried.order(:id) }

    let!(:build_retried) { create_build('build') }
    let!(:build) { create_build('build') }
    let!(:test) { create_build('test') }

    it 'returns unique statuses' do
      process_pipeline

      expect(all_builds.latest).to contain_exactly(build, test)
      expect(all_builds.retried).to contain_exactly(build_retried)
    end
  end

  def process_pipeline
    described_class.new(pipeline).execute
  end

  def create_build(name, **opts)
    create(:ci_build, :created, pipeline: pipeline, name: name, **opts)
  end

  def all_builds
    pipeline.builds.order(:stage_idx, :id)
  end
end
