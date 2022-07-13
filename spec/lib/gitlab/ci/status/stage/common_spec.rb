# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Stage::Common do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:stage) do
    build(:ci_stage, pipeline: pipeline, name: 'test')
  end

  subject do
    Class.new(Gitlab::Ci::Status::Core)
      .new(stage, user).extend(described_class)
  end

  it 'does not have action' do
    expect(subject).not_to have_action
  end

  it 'links to the pipeline details page' do
    expect(subject.details_path)
      .to include "pipelines/#{pipeline.id}"
    expect(subject.details_path)
      .to include "##{stage.name}"
  end

  context 'when user has permission to read pipeline' do
    before do
      project.add_maintainer(user)
    end

    it 'has details' do
      expect(subject).to have_details
    end
  end

  context 'when user does not have permission to read pipeline' do
    it 'does not have details' do
      expect(subject).not_to have_details
    end
  end
end
