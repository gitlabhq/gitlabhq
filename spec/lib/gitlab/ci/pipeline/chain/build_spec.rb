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
    stub_repository_ci_yaml_file(sha: anything)

    step.perform!
  end

  it 'never breaks the chain' do
    expect(step.break?).to be false
  end

  it 'fills pipeline object with data' do
    expect(pipeline.sha).not_to be_empty
    expect(pipeline.sha).to eq project.commit.id
    expect(pipeline.ref).to eq 'master'
    expect(pipeline.user).to eq user
    expect(pipeline.project).to eq project
  end

  it 'sets a valid config source' do
    expect(pipeline.repository_source?).to be true
  end

  it 'returns a valid pipeline' do
    expect(pipeline).to be_valid
  end

  it 'does not persist a pipeline' do
    expect(pipeline).not_to be_persisted
  end
end
