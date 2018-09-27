# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateExternalPipelineSource, :migration, schema: 20180916011959 do
  let(:migration) { described_class.new }

  let!(:internal_pipeline) { create(:ci_pipeline, source: Ci::Pipeline.sources[:web]) }
  let!(:external_pipeline) do
    build(:ci_pipeline, source: Ci::Pipeline.sources[:unknown])
      .tap { |pipeline| pipeline.save(validate: false) }
  end
  let!(:second_external_pipeline) do
    build(:ci_pipeline, source: Ci::Pipeline.sources[:unknown])
      .tap { |pipeline| pipeline.save(validate: false) }
  end

  before do
    create(:generic_commit_status, pipeline: external_pipeline)
    create(:ci_build, pipeline: internal_pipeline)
  end

  subject { migration.perform(external_pipeline.id, second_external_pipeline.id) }

  it 'populates the pipeline source' do
    subject

    expect(external_pipeline.reload.source).to eq('external')
  end

  it 'only processes a single batch of links at a time' do
    subject

    expect(second_external_pipeline.reload.source).to eq('unknown')
  end

  it 'can be repeated without effect' do
    subject

    expect { subject }.not_to change { external_pipeline.reload.source }
  end
end
