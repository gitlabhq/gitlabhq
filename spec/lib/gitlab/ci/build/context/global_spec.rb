# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Global, feature_category: :pipeline_composition do
  let(:pipeline)       { create(:ci_pipeline) }
  let(:yaml_variables) { {} }

  let(:context) { described_class.new(pipeline, yaml_variables: yaml_variables) }

  shared_examples 'variables collection' do
    it { is_expected.to include('CI_COMMIT_REF_NAME' => 'master') }
    it { is_expected.to include('CI_PIPELINE_IID'    => pipeline.iid.to_s) }
    it { is_expected.to include('CI_PROJECT_PATH'    => pipeline.project.full_path) }

    it { is_expected.not_to have_key('CI_JOB_NAME') }

    context 'with passed yaml variables' do
      let(:yaml_variables) { [{ key: 'SUPPORTED', value: 'parsed', public: true }] }

      it { is_expected.to include('SUPPORTED' => 'parsed') }
    end
  end

  describe '#variables' do
    subject { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it_behaves_like 'variables collection'
  end

  describe '#variables_hash' do
    subject { context.variables_hash }

    it { is_expected.to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }

    it_behaves_like 'variables collection'
  end

  describe '#top_level_worktree_paths' do
    subject(:top_level_worktree_paths) { context.top_level_worktree_paths }

    it 'delegates to pipeline' do
      expect(pipeline).to receive(:top_level_worktree_paths)

      top_level_worktree_paths
    end
  end

  describe '#all_worktree_paths' do
    subject(:all_worktree_paths) { context.all_worktree_paths }

    it 'delegates to pipeline' do
      expect(pipeline).to receive(:all_worktree_paths)

      all_worktree_paths
    end
  end
end
