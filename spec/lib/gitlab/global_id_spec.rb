# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GlobalId do
  describe '.build' do
    let_it_be(:object) { create(:issue) }

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

  describe '.as_global_id' do
    let(:project) { build_stubbed(:project) }

    it 'is the identify function on GlobalID instances' do
      gid = project.to_global_id

      expect(described_class.as_global_id(gid)).to eq(gid)
    end

    it 'wraps URI::GID in GlobalID' do
      uri = described_class.build(model_name: 'Foo', id: 1)

      expect(described_class.as_global_id(uri)).to eq(GlobalID.new(uri))
    end

    it 'cannot coerce Integers without a model name' do
      expect { described_class.as_global_id(1) }
        .to raise_error(described_class::CoerceError, 'Cannot coerce Integer')
    end

    it 'can coerce Integers with a model name' do
      uri = described_class.build(model_name: 'Foo', id: 1)

      expect(described_class.as_global_id(1, model_name: 'Foo')).to eq(GlobalID.new(uri))
    end

    it 'rejects any other value' do
      [:symbol, 'string', nil, [], {}, project].each do |value|
        expect { described_class.as_global_id(value) }.to raise_error(described_class::CoerceError)
      end
    end
  end
end
