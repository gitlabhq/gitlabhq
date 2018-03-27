module DeviseHelpers
  # explicitly tells Devise which mapping to use
  # this is needed when we are testing a Devise controller bypassing the router
  def set_devise_mapping(context:)
    env = env_from_context(context)

    env['devise.mapping'] = Devise.mappings[:user] if env
  end

  def env_from_context(context)
    if context.respond_to?(:env_config)
      context.env_config
    elsif context.respond_to?(:env)
      context.env
    end
  end
end
