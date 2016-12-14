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
end
