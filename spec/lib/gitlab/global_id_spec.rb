# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GlobalId do
  describe '.build' do
    set(:object) { create(:issue) }

    it 'returns a standard GlobalId if only object is passed' do
      expect(described_class.build(object).to_s).to eq(object.to_global_id.to_s)
    end

    it 'returns a GlobalId from params' do
      expect(described_class.build(model_name: 'MyModel', id: 'myid').to_s).to eq(
        'gid://gitlab/MyModel/myid'
      )
    end

    it 'returns a GlobalId from object and `id` param' do
      expect(described_class.build(object, id: 'myid').to_s).to eq(
        'gid://gitlab/Issue/myid'
      )
    end

    it 'returns a GlobalId from object and `model_name` param' do
      expect(described_class.build(object, model_name: 'MyModel').to_s).to eq(
        "gid://gitlab/MyModel/#{object.id}"
      )
    end

    it 'returns an error if model_name and id are not able to be determined' do
      expect { described_class.build(id: 'myid') }.to raise_error(URI::InvalidComponentError)
      expect { described_class.build(model_name: 'MyModel') }.to raise_error(URI::InvalidComponentError)
      expect { described_class.build }.to raise_error(URI::InvalidComponentError)
    end
  end
end
