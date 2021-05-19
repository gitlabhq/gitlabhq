# frozen_string_literal: true

class Redis
  ForbiddenCommand = Class.new(StandardError)

  def keys(*args)
    raise ForbiddenCommand, "Don't use `Redis#keys` as it iterates over all "\
                               "keys in redis. Use `Redis#scan_each` instead."
  end
end
