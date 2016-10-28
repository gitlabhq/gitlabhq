require 'spec_helper'

describe EnvironmentSerializer do
  let(:serializer) do
    described_class.new(path: 'some path').represent(resource)
  end

  context 'when there is a single object provided' do
    let(:resource) { create(:environment) }

    it 'shows json' do
      puts serializer.to_json
    end

    it 'it generates payload for single object' do
      expect(parsed_json).to be_an_instance_of Hash
    end
  end

  context 'when there is a collection of objects provided' do
    let(:resource) { create_list(:environment, 2) }

    it 'shows json' do
      puts serializer.to_json
    end

    it 'generates payload for collection' do
      expect(parsed_json).to be_an_instance_of Array
    end
  end

  def parsed_json
    JSON.parse(serializer.to_json)
  end
end
