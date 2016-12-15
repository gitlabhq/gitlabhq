require 'spec_helper'

describe PipelineSerializer do
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline) }

  let(:serializer) do
    described_class.new(user: user)
  end

  describe '#represent' do
    subject { serializer.represent(pipeline) }

    it 'serializers the pipeline object' do
      expect(subject.as_json).to include :id
    end
  end
end
