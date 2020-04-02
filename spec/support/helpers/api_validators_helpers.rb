# frozen_string_literal: true

module ApiValidatorsHelpers
  def scope
    Struct.new(:opts) do
      def full_name(attr_name)
        attr_name
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
