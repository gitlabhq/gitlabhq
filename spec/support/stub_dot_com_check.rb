# frozen_string_literal: true

RSpec.configure do |config|
  %i[saas saas_registration saas_trial].each do |metadata|
    config.before(:context, metadata) do
      # Ensure Gitlab.com? returns true during context.
      # This is needed for let_it_be which is shared across examples,
      # therefore the value must be changed in before_all,
      # but RSpec prevent stubbing method calls in before_all,
      # therefore we have to resort to temporarily swap url value.
      @_original_gitlab_url = Gitlab.config.gitlab['url']
      Gitlab.config.gitlab['url'] = Gitlab::Saas.com_url
    end

    config.after(:context, metadata) do
      # Swap back original value
      Gitlab.config.gitlab['url'] = @_original_gitlab_url
    end
  end
end
