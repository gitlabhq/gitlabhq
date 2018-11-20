module DeviseHelpers
  # explicitly tells Devise which mapping to use
  # this is needed when we are testing a Devise controller bypassing the router
  def set_devise_mapping(context:)
    env = env_from_context(context)

    env['devise.mapping'] = Devise.mappings[:user] if env
  end

  def env_from_context(context)
    # When we modify env_config, that is on the global
    # Rails.application, and we need to stub it and allow it to be
    # modified in-place, without polluting later tests.
    if context.respond_to?(:env_config)
      context.env_config.deep_dup.tap do |env|
        allow(context).to receive(:env_config).and_return(env)
      end
    # When we modify env, then the context is a request, or something
    # else that only lives for a single spec.
    elsif context.respond_to?(:env)
      context.env
    end
  end
end
