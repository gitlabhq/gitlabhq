# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AttrEncrypted do
  describe '#encrypted_attributes' do
    subject do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'projects'

        attr_accessor :encrypted_foo
        attr_accessor :encrypted_foo_iv

        attr_encrypted :foo, key: 'This is a key that is 256 bits!!'
      end
    end

    it 'does not share state with other instances' do
      instance = subject.new
      instance.foo = 'bar'

      another_instance = subject.new

      expect(instance.encrypted_attributes[:foo][:operation]).to eq(:encrypting)
      expect(another_instance.encrypted_attributes[:foo][:operation]).to be_nil
    end
  end
end
