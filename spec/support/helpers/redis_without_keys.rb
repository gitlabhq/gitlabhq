class Redis
  ForbiddenCommand = Class.new(StandardError)

  def keys(*args)
    raise ForbiddenCommand.new("Don't use `Redis#keys` as it iterates over all "\
                               "keys in redis. Use `Redis#scan_each` instead.")
  end
end
