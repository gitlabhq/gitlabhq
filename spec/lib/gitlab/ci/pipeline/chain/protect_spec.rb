# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Protect do
  set(:project) { create(:project) }
  set(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master')
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user, origin_ref: 'master')
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when the ref is protected' do
    before do
      allow(project).to receive(:protected_for?).with('master').and_return(true)

      step.perform!
    end

    it 'protects the pipeline' do
      expect(pipeline.protected).to eq(true)
    end
  end

  context 'when the ref is not protected' do
    before do
      allow(project).to receive(:protected_for?).with('master').and_return(false)

      step.perform!
    end

    it 'does not protect the pipeline' do
      expect(pipeline.protected).to eq(false)
    end
  end
end
