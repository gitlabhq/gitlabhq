require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Create do
  set(:project) { create(:project) }
  set(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master')
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when pipeline is ready to be saved' do
    before do
      pipeline.stages.build(name: 'test', position: 0, project: project)

      step.perform!
    end

    it 'saves a pipeline' do
      expect(pipeline).to be_persisted
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'creates stages' do
      expect(pipeline.reload.stages).to be_one
      expect(pipeline.stages.first).to be_persisted
    end
  end

  context 'when pipeline has validation errors' do
    shared_examples_for 'expectations' do
      it 'breaks the chain' do
        expect(step.break?).to be true
      end

      it 'appends validation error' do
        expect(pipeline.errors.to_a)
          .to include /Failed to persist the pipeline/
      end
    end

    context 'when ref is nil' do
      let(:pipeline) do
        build(:ci_pipeline, project: project, ref: nil)
      end

      before do
        step.perform!
      end

      it_behaves_like 'expectations'
    end

    context 'when pipeline has a duplicate iid' do
      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:ensure_project_iid!) { |p| p.send(:write_attribute, :iid, 1) }
        create(:ci_pipeline, project: project)

        step.perform!
      end

      it_behaves_like 'expectations'
    end
  end
end
