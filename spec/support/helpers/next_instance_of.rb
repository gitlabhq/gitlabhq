# frozen_string_literal: true

module NextInstanceOf
  def expect_next_instance_of(klass, *new_args)
    stub_new(expect(klass), *new_args) do |expectation|
      yield(expectation)
    end
  end

  def allow_next_instance_of(klass, *new_args)
    stub_new(allow(klass), *new_args) do |allowance|
      yield(allowance)
    end
  end

  private

  def stub_new(target, *new_args)
    receive_new = receive(:new)
    receive_new.with(*new_args) if new_args.any?

    target.to receive_new.and_wrap_original do |method, *original_args|
      method.call(*original_args).tap do |instance|
        yield(instance)
      end
    end
  end
end
