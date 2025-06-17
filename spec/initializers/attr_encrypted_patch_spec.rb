# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AttrEncrypted InstanceMethodsPatch', feature_category: :database do
  describe '#attribute_instance_methods_as_symbols_available?' do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'users'

        attr_encrypted :foo
      end
    end

    it { expect(ActiveRecord::Base.__send__(:attribute_instance_methods_as_symbols_available?)).to be_falsy }

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
  end
end
