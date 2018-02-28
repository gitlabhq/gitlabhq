require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Validate::Repository do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:command) do
    double('command', project: project, current_user: user)
  end

  let!(:step) { described_class.new(pipeline, command) }

  before do
    step.perform!
  end

  context 'when pipeline ref and sha exists' do
    let(:pipeline) do
      build_stubbed(:ci_pipeline, ref: 'master', sha: '123', project: project)
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'does not append pipeline errors' do
      expect(pipeline.errors).to be_empty
    end
  end

  context 'when pipeline ref does not exist' do
    let(:pipeline) do
      build_stubbed(:ci_pipeline, ref: 'something', project: project)
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'adds an error about missing ref' do
      expect(pipeline.errors.to_a)
        .to include 'Reference not found'
    end
  end

  context 'when pipeline does not have SHA set' do
    let(:pipeline) do
      build_stubbed(:ci_pipeline, ref: 'master', sha: nil, project: project)
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'adds an error about missing SHA' do
      expect(pipeline.errors.to_a)
        .to include 'Commit not found'
    end
  end
end
