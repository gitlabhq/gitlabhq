# frozen_string_literal: true

RSpec.shared_examples 'encrypted attribute' do |attr, key_method|
  describe "encrypted attribute :#{attr}" do
    it 'uses correct key method' do
      expect(record.attr_encrypted_attributes[attr][:key]).to eq(key_method)
    end
  end
end
