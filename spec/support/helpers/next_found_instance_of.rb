# frozen_string_literal: true

module NextFoundInstanceOf
  ERROR_MESSAGE = 'NextFoundInstanceOf mock helpers can only be used with ActiveRecord targets'

  def expect_next_found_instance_of(klass)
    check_if_active_record!(klass)

    stub_allocate(expect(klass), klass) do |expectation|
      yield(expectation)
    end
  end

  def allow_next_found_instance_of(klass)
    check_if_active_record!(klass)

    stub_allocate(allow(klass), klass) do |allowance|
      yield(allowance)
    end
  end

  private

  def check_if_active_record!(klass)
    raise ArgumentError, ERROR_MESSAGE unless klass < ActiveRecord::Base
  end

  def stub_allocate(target, klass)
    target.to receive(:allocate).and_wrap_original do |method|
      method.call.tap do |allocation|
        # ActiveRecord::Core.allocate returns a frozen object:
        # https://github.com/rails/rails/blob/291a3d2ef29a3842d1156ada7526f4ee60dd2b59/activerecord/lib/active_record/core.rb#L620
        # It's unexpected behavior and probably a bug in Rails
        # Let's work it around by setting the attributes to default to unfreeze the object for now
        allocation.instance_variable_set(:@attributes, klass._default_attributes)

        yield(allocation)
      end
    end
  end
end
