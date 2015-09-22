# == Schema Information
#
# Table name: variables
#
#  id                   :integer          not null, primary key
#  project_id           :integer          not null
#  key                  :string(255)
#  value                :text
#  encrypted_value      :text
#  encrypted_value_salt :string(255)
#  encrypted_value_iv   :string(255)
#

require 'spec_helper'

describe Ci::Variable do
  subject { Ci::Variable.new }

  let(:secret_value) { 'secret' }

  before :each do
    subject.value = secret_value
  end

  describe :value do
    it 'stores the encrypted value' do
      expect(subject.encrypted_value).not_to be_nil
    end

    it 'stores an iv for value' do
      expect(subject.encrypted_value_iv).not_to be_nil
    end

    it 'stores a salt for value' do
      expect(subject.encrypted_value_salt).not_to be_nil
    end

    it 'fails to decrypt if iv is incorrect' do
      subject.encrypted_value_iv = nil
      subject.instance_variable_set(:@value, nil)
      expect { subject.value }.
        to raise_error(OpenSSL::Cipher::CipherError, 'bad decrypt')
    end
  end
end
