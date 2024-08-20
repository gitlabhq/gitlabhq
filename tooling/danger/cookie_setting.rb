# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    class CookieSetting < Suggestion
      MATCH = %r{cookies(?:\.encrypted|\.signed|\.permanent)*\[([^\]]+)\]\s*=[^=]}
      REPLACEMENT = nil
      DOCUMENTATION_LINK = 'https://docs.gitlab.com/ee/development/cookies.html#cookies-on-rails'

      SUGGESTION = <<~MESSAGE_MARKDOWN.freeze
        It looks like you are setting a server-side cookie. Please note that if you set
        the `:domain` attribute for this cookie, you must ensure the cookie is unset when
        the user logs out. Most cookies do not require this attribute.

        ----

        For more information, see [cookies documentation](#{DOCUMENTATION_LINK}).
      MESSAGE_MARKDOWN
    end
  end
end
