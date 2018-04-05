require 'spec_helper'

describe Gitlab::DataBuilder::Pipeline do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline,
           project: project,
           status: 'success',
           sha: project.commit.sha,
           ref: project.default_branch)
  end

  let!(:build) { create(:ci_build, pipeline: pipeline) }

  describe '.build' do
    let(:data) { described_class.build(pipeline) }
    let(:attributes) { data[:object_attributes] }
    let(:build_data) { data[:builds].first }
    let(:project_data) { data[:project] }

    it { expect(attributes).to be_a(Hash) }
    it { expect(attributes[:ref]).to eq(pipeline.ref) }
    it { expect(attributes[:sha]).to eq(pipeline.sha) }
    it { expect(attributes[:tag]).to eq(pipeline.tag) }
    it { expect(attributes[:id]).to eq(pipeline.id) }
    it { expect(attributes[:status]).to eq(pipeline.status) }
    it { expect(attributes[:detailed_status]).to eq('passed') }

    it { expect(build_data).to be_a(Hash) }
    it { expect(build_data[:id]).to eq(build.id) }
    it { expect(build_data[:status]).to eq(build.status) }

    it { expect(project_data).to eq(project.hook_attrs(backward: false)) }
  end
end
