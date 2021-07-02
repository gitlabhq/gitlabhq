# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab monkey-patches to AttrEncrypted' do
  describe '#attribute_instance_methods_as_symbols_available?' do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        # We need some sort of table to work on
        self.table_name = 'projects'

        attr_encrypted :foo
      end
    end

    it 'returns false' do
      expect(ActiveRecord::Base.__send__(:attribute_instance_methods_as_symbols_available?)).to be_falsy
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
end
