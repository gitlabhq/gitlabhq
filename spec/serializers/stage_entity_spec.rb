require 'spec_helper'

describe StageEntity do
  let(:pipeline) { create(:ci_pipeline) }
  let(:request) { double('request') }
  let(:user) { create(:user) }

  let(:entity) do
    described_class.new(stage, request: request)
  end

  let(:stage) do
    build(:ci_stage, pipeline: pipeline, name: 'test')
  end

  before do
    allow(request).to receive(:user).and_return(user)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains relevant fields' do
      expect(subject).to include :name, :status, :path
    end

    it 'contains detailed status' do
      expect(subject[:status]).to include :text, :label, :group, :icon
    end

    it 'contains valid name' do
      expect(subject[:name]).to eq 'test'
    end

    it 'contains path to the stage' do
      expect(subject[:path])
        .to include "pipelines/#{pipeline.id}##{stage.name}"
    end
  end
end
