# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  describe 'tags:' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.owner }

    let(:ref) { 'refs/heads/master' }
    let(:source) { :push }
    let(:service) { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(source).payload }

    before do
      stub_ci_pipeline_yaml_file(config)
    end

    context 'with valid config' do
      let(:config) { YAML.dump({ test: { script: 'ls', tags: %w[tag1 tag2] } }) }

      it 'creates a pipeline', :aggregate_failures do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.first.tag_list).to eq(%w[tag1 tag2])
      end
    end

    context 'with too many tags' do
      let(:tags) { Array.new(50) {|i| "tag-#{i}" } }
      let(:config) { YAML.dump({ test: { script: 'ls', tags: tags } }) }

      it 'creates a pipeline without builds', :aggregate_failures do
        expect(pipeline).not_to be_created_successfully
        expect(pipeline.builds).to be_empty
        expect(pipeline.yaml_errors).to eq("jobs:test:tags config must be less than the limit of #{Gitlab::Ci::Config::Entry::Tags::TAGS_LIMIT} tags")
      end
    end
  end
end
