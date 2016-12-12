require 'spec_helper'

describe Gitlab::Ci::Status::Stage::Common do
  let(:pipeline) { create(:ci_empty_pipeline) }
  let(:stage) { build(:ci_stage, pipeline: pipeline, name: 'test') }

  subject do
    Class.new(Gitlab::Ci::Status::Core)
      .new(stage).extend(described_class)
  end

  it 'does not have action' do
    expect(subject).not_to have_action
  end

  it 'has details' do
    expect(subject).to have_details
  end

  it 'links to the pipeline details page' do
    expect(subject.details_path)
      .to include "pipelines/#{pipeline.id}"
    expect(subject.details_path)
      .to include "##{stage.name}"
  end
end
