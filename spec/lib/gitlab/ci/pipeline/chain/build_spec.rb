require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Build do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }
  let(:pipeline) { Ci::Pipeline.new }

  let(:command) do
    double('command', source: :push,
                      origin_ref: 'master',
                      checkout_sha: project.commit.id,
                      after_sha: nil,
                      before_sha: nil,
                      trigger_request: nil,
                      schedule: nil,
                      project: project,
                      current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  before do
    stub_ci_pipeline_to_return_yaml_file

    step.perform!
  end

  it 'never breaks the chain' do
    expect(step.break?).to be false
  end

  it 'fills pipeline object with data' do
    expect(pipeline.sha).not_to be_empty
  end

  it 'sets a valid config source' do
    expect(pipeline.repository_source?).to be true
  end

  it 'returns a valid pipeline' do
    expect(pipeline).to be_valid
  end
end
