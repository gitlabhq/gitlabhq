require 'spec_helper'

describe Gitlab::Serialize::YamlVariables do
  subject do
    Gitlab::Serialize::YamlVariables.load(
      Gitlab::Serialize::YamlVariables.dump(object))
  end

  let(:object) do
    [{ key: :key, value: 'value', public: true },
     { key: 'wee', value: 1, public: false }]
  end

  it 'converts key and values into strings' do
    is_expected.to eq([
      { key: 'key', value: 'value', public: true },
      { key: 'wee', value: '1', public: false }])
  end

  context 'with a subclass of Array' do
    let(:object) do
      Kaminari::PaginatableArray.new << 'I am evil'
    end

    it 'ignores it' do
      is_expected.to eq([])
    end
  end

  context 'with the array containing subclasses of Hash' do
    let(:object) do
      [ActiveSupport::OrderedOptions.new(
        key: 'key', value: 'value', public: true)]
    end

    it 'ignores it' do
      is_expected.to eq([])
    end
  end
end
