# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab monkey-patches to AttrEncrypted', feature_category: :shared do
  # See https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/23306
  describe '#attribute_instance_methods_as_symbols_available?' do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        # We need some sort of table to work on
        self.table_name = 'projects'

        attr_encrypted :foo
      end
    end

    it 'returns false' do
      expect(klass.__send__(:attribute_instance_methods_as_symbols_available?)).to be_falsy
    end

    it 'does not define virtual attributes' do
      instance = klass.new

      aggregate_failures do
        %w[
          encrypted_foo encrypted_foo=
          encrypted_foo_iv encrypted_foo_iv=
          encrypted_foo_salt encrypted_foo_salt=
        ].each do |method_name|
          expect(instance).not_to respond_to(method_name)
        end
      end
    end

    it 'calls attr_changed? method with kwargs' do
      obj = klass.new

      expect(obj.foo_changed?).to eq(false)
    end
  end

  describe '#attr_encrypted_attributes' do
    let(:class_with_attr_encrypted) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'projects'

        attr_accessor :encrypted_foo
        attr_accessor :encrypted_foo_iv

        attr_encrypted :foo, key: 'This is a key that is 256 bits!!'
      end
    end

    it 'does not share state with other instances' do
      instance = class_with_attr_encrypted.new
      instance.foo = 'bar'

      another_instance = class_with_attr_encrypted.new

      expect(instance.attr_encrypted_attributes[:foo][:operation]).to eq(:encrypting)
      expect(another_instance.attr_encrypted_attributes[:foo][:operation]).to be_nil
    end
  end
end
