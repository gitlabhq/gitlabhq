require 'spec_helper'

describe GroupChildEntity do
  let(:request) { double('request') }
  let(:entity) { described_class.new(object, request: request) }
  subject(:json) { entity.as_json }

  describe 'for a project' do
    let(:object) { build_stubbed(:project) }

    it 'has the correct type' do
      expect(json[:type]).to eq('project')
    end
  end
end
