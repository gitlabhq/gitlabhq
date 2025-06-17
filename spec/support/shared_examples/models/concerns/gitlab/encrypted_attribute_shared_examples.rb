# frozen_string_literal: true

RSpec.shared_examples 'encrypted attribute' do |attr, key_method|
  describe "encrypted attribute :#{attr}" do
    it 'uses correct key method' do
      expect(record.attr_encrypted_encrypted_attributes[attr][:key]).to eq(key_method)
    end
  end
end

RSpec.shared_examples 'encrypted attribute being migrated to the new encryption framework' do |attribute|
  let(:secret_value) { 'my secret' }

  it 'is encrypted with both encryption frameworks' do
    record.public_send(:"#{attribute}=", secret_value)
    record.save!

    expect(record.public_send(attribute)).to eq(secret_value)
    expect(record.public_send(:"attr_encrypted_#{attribute}")).to eq(secret_value)
    expect(record.public_send(:"tmp_#{attribute}")).to eq(secret_value)

    expect(record.ciphertext_for(:"tmp_#{attribute}")).not_to eq(secret_value)
    expect(record.public_send(:"encrypted_#{attribute}")).not_to eq(secret_value)
  end
end
