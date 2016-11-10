require 'spec_helper'

describe PipelineSerializer do
  let(:serializer) do
    described_class.new(user: user)
  end

  let(:pipelines) do
    create_list(:ci_pipeline, 2)
  end

  let(:user) { create(:user) }

  context 'when using incremental serializer' do
    let(:json) do
      serializer.incremental(pipelines, time).as_json
    end

    context 'when pipeline has been already updated' do
      let(:time) { Time.now }

      it 'exposes only minimal information' do
        expect(json.first.keys).to contain_exactly(:id, :url)
        expect(json.second.keys).to contain_exactly(:id, :url)
      end
    end

    context 'when pipeline updated in the meantime' do
      let(:time) { Time.now - 10.minutes }

      it 'exposes new data incrementally' do
        expect(json.first.keys.count).to eq 9
      end
    end
  end
end
