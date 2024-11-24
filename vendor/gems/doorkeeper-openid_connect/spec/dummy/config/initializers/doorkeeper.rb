# frozen_string_literal: true

Doorkeeper.configure do
  optional_scopes :openid

  resource_owner_authenticator do
    if params[:current_user].present?
      User.find(params[:current_user])
    else
      redirect_to('/login')
      nil
    end
  end

  grant_flows %w[authorization_code client_credentials implicit_oidc]
end
