# frozen_string_literal: true

module SnippetHelpers
  def sign_in_as(user)
    sign_in(public_send(user)) if user
  end
end
