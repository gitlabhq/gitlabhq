# frozen_string_literal: true

module NextFoundInstanceOf
  ERROR_MESSAGE = 'NextFoundInstanceOf mock helpers can only be used with ActiveRecord targets'

  def expect_next_found_instance_of(klass)
    check_if_active_record!(klass)

    stub_allocate(expect(klass)) do |expectation|
      yield(expectation)
    end
  end

  def allow_next_found_instance_of(klass)
    check_if_active_record!(klass)

    stub_allocate(allow(klass)) do |allowance|
      yield(allowance)
    end
  end

  private

  def check_if_active_record!(klass)
    raise ArgumentError.new(ERROR_MESSAGE) unless klass < ActiveRecord::Base
  end

  def stub_allocate(target)
    target.to receive(:allocate).and_wrap_original do |method|
      method.call.tap { |allocation| yield(allocation) }
    end
  end
end
