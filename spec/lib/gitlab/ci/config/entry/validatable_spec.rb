require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Validatable do
  let(:entry) do
    Class.new(Gitlab::Ci::Config::Entry::Node) do
      include Gitlab::Ci::Config::Entry::Validatable
    end
  end

  describe '.validator' do
    before do
      entry.class_eval do
        attr_accessor :test_attribute

        validations do
          validates :test_attribute, presence: true
        end
      end
    end

    it 'returns validator' do
      expect(entry.validator.superclass)
        .to be Gitlab::Ci::Config::Entry::Validator
    end

    it 'returns only one validator to mitigate leaks' do
      expect { entry.validator }.not_to change { entry.validator }
    end

    context 'when validating entry instance' do
      let(:entry_instance) { entry.new('something') }

      context 'when attribute is valid' do
        before do
          entry_instance.test_attribute = 'valid'
        end

        it 'instance of validator is valid' do
          expect(entry.validator.new(entry_instance)).to be_valid
        end
      end

      context 'when attribute is not valid' do
        before do
          entry_instance.test_attribute = nil
        end

        it 'instance of validator is invalid' do
          expect(entry.validator.new(entry_instance)).to be_invalid
        end
      end
    end
  end
end
