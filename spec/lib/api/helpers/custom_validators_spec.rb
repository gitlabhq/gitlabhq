# frozen_string_literal: true

require 'spec_helper'

describe API::Helpers::CustomValidators do
  let(:scope) do
    Struct.new(:opts) do
      def full_name(attr_name)
        attr_name
      end
    end
  end

  describe API::Helpers::CustomValidators::Absence do
    subject do
      described_class.new(['test'], {}, false, scope.new)
    end

    context 'empty param' do
      it 'does not raise a validation error' do
        expect_no_validation_error({})
      end
    end

    context 'invalid parameters' do
      it 'raises a validation error' do
        expect_validation_error('test' => 'some_value')
      end
    end
  end

  describe API::Helpers::CustomValidators::FilePath do
    subject do
      described_class.new(['test'], {}, false, scope.new)
    end

    context 'valid file path' do
      it 'does not raise a validation error' do
        expect_no_validation_error('test' => './foo')
        expect_no_validation_error('test' => './bar.rb')
        expect_no_validation_error('test' => 'foo%2Fbar%2Fnew%2Ffile.rb')
        expect_no_validation_error('test' => 'foo%2Fbar%2Fnew')
        expect_no_validation_error('test' => 'foo%252Fbar%252Fnew%252Ffile.rb')
      end
    end

    context 'invalid file path' do
      it 'raise a validation error' do
        expect_validation_error('test' => '../foo')
        expect_validation_error('test' => '../')
        expect_validation_error('test' => 'foo/../../bar')
        expect_validation_error('test' => 'foo/../')
        expect_validation_error('test' => 'foo/..')
        expect_validation_error('test' => '../')
        expect_validation_error('test' => '..\\')
        expect_validation_error('test' => '..\/')
        expect_validation_error('test' => '%2e%2e%2f')
        expect_validation_error('test' => '/etc/passwd')
      end
    end
  end

  describe API::Helpers::CustomValidators::IntegerNoneAny do
    subject do
      described_class.new(['test'], {}, false, scope.new)
    end

    context 'valid parameters' do
      it 'does not raise a validation error' do
        expect_no_validation_error('test' => 2)
        expect_no_validation_error('test' => 100)
        expect_no_validation_error('test' => 'None')
        expect_no_validation_error('test' => 'Any')
        expect_no_validation_error('test' => 'none')
        expect_no_validation_error('test' => 'any')
      end
    end

    context 'invalid parameters' do
      it 'raises a validation error' do
        expect_validation_error({ 'test' => 'some_other_string' })
      end
    end
  end

  describe API::Helpers::CustomValidators::ArrayNoneAny do
    subject do
      described_class.new(['test'], {}, false, scope.new)
    end

    context 'valid parameters' do
      it 'does not raise a validation error' do
        expect_no_validation_error('test' => [])
        expect_no_validation_error('test' => [1, 2, 3])
        expect_no_validation_error('test' => 'None')
        expect_no_validation_error('test' => 'Any')
        expect_no_validation_error('test' => 'none')
        expect_no_validation_error('test' => 'any')
      end
    end

    context 'invalid parameters' do
      it 'raises a validation error' do
        expect_validation_error('test' => 'some_other_string')
      end
    end
  end

  def expect_no_validation_error(params)
    expect { validate_test_param!(params) }.not_to raise_error
  end

  def expect_validation_error(params)
    expect { validate_test_param!(params) }.to raise_error(Grape::Exceptions::Validation)
  end

  def validate_test_param!(params)
    subject.validate_param!('test', params)
  end
end
