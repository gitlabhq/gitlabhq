
# AccessMatchersForController
#
# For testing authorize_xxx in controller. 
module AccessMatchersForController
  extend RSpec::Matchers::DSL
  include Warden::Test::Helpers

  EXPECTED_STATUS_CODE_ALLOWED = [200, 302].freeze
  EXPECTED_STATUS_CODE_DENIED = [404].freeze

  def emulate_user(role, membership = nil)
    case role
    when :admin
      user = create(:admin)
      sign_in(user)
    when :user
      user = create(:user)
      sign_in(user)
    when :external
      user = create(:user, external: true)
      sign_in(user)
    when :visitor # rubocop:disable Lint/EmptyWhen
      # no-op
    when User
      user = role
      sign_in(user)
    when *Gitlab::Access.sym_options_with_owner.keys # owner, master, developer, reporter, guest
      raise ArgumentError, "cannot emulate #{role} without membership parent" unless membership

      if role == :owner && membership.owner
        user = membership.owner
      else
        user = create(:user)
        membership.public_send(:"add_#{role}", user)
      end

      sign_in(user)
    else
      raise ArgumentError, "cannot emulate user #{role}"
    end

    user
  end

  def description_for(role, type, expected, result)
    "be #{type} for #{role}." \
    " Expected: #{expected.join(',')} Got: #{result}"
  end

  matcher :be_allowed_for do |role|
    match do |action|
      user = emulate_user(role, @membership)
      # begin
        action.call(user)
      # rescue
      #   # Ignore internal exceptions which will be caused in the controller
      #   # In such cases, response.status will be 200.
      # end

      EXPECTED_STATUS_CODE_ALLOWED.include?(response.status)
    end

    chain :of do |membership|
      @membership = membership
    end

    description { description_for(role, 'allowed', EXPECTED_STATUS_CODE_ALLOWED, response.status) }
    supports_block_expectations
  end

  matcher :be_denied_for do |role|
    match do |action|
      user = emulate_user(role, @membership)
      # begin
        action.call(user)
      # rescue
      #   # Ignore internal exceptions which will be caused in the controller
      #   # In such cases, response.status will be 200.
      # end

      EXPECTED_STATUS_CODE_DENIED.include?(response.status)
    end

    chain :of do |membership|
      @membership = membership
    end

    description { description_for(role, 'denied', EXPECTED_STATUS_CODE_DENIED, response.status) }
    supports_block_expectations
  end
end
