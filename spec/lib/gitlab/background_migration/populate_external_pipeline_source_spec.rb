# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
describe Gitlab::BackgroundMigration::PopulateExternalPipelineSource, :migration, schema: 20180916011959 do
  let(:migration) { described_class.new }

  before do
    # This migration was created before we introduced metadata configs
    stub_feature_flags(ci_build_metadata_config: false)
    # This migration was created before we introduced ProjectCiCdSetting#default_git_depth
    allow_any_instance_of(ProjectCiCdSetting).to receive(:default_git_depth).and_return(nil)
    allow_any_instance_of(ProjectCiCdSetting).to receive(:default_git_depth=).and_return(0)
  end

  let!(:internal_pipeline) { create(:ci_pipeline, source: :web) }
  let(:pipelines) { [internal_pipeline, unknown_pipeline].map(&:id) }

  let!(:unknown_pipeline) do
    build(:ci_pipeline, source: :unknown)
      .tap { |pipeline| pipeline.save(validate: false) }
  end

  subject { migration.perform(pipelines.min, pipelines.max) }

  shared_examples 'no changes' do
    it 'does not change the pipeline source' do
      expect { subject }.not_to change { unknown_pipeline.reload.source }
    end
  end

  context 'when unknown pipeline is external' do
    before do
      create(:generic_commit_status, pipeline: unknown_pipeline)
    end

    it 'populates the pipeline source' do
      subject

      expect(unknown_pipeline.reload.source).to eq('external')
    end

    it 'can be repeated without effect' do
      subject

      expect { subject }.not_to change { unknown_pipeline.reload.source }
    end
  end

  context 'when unknown pipeline has just a build' do
    before do
      create(:ci_build, pipeline: unknown_pipeline)
    end

    it_behaves_like 'no changes'
  end

  context 'when unknown pipeline has no statuses' do
    it_behaves_like 'no changes'
  end

  context 'when unknown pipeline has a build and a status' do
    before do
      create(:generic_commit_status, pipeline: unknown_pipeline)
      create(:ci_build, pipeline: unknown_pipeline)
    end

    it_behaves_like 'no changes'
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
