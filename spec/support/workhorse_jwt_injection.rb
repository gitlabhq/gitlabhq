# frozen_string_literal: true

# Workhorse JWT enforcement test infrastructure
# ---------------------------------------------
#
# This file replaces the previous stub of `Gitlab::Workhorse.verify_api_request!`,
# which silently masked any senddata-emitting controller or Grape route that
# lacked a JWT guard. The replacement is two-part:
#
# 1. **Inject** a valid `Gitlab-Workhorse-Api-Request` JWT into every test
#    request before it is dispatched. The real `verify_api_request!` runs in
#    tests (there is no stubbing), so happy-path specs do not need to build
#    a JWT header themselves.
#
# 2. **Detect** any response that carries `Gitlab-Workhorse-Send-Data` while
#    the request lacked a verified Workhorse JWT. This fires the spec as red
#    with a pointer to the chokepoint helpers, so a future endpoint that
#    emits senddata without going through a guarded helper turns its own
#    happy-path test loud rather than passing silently.
#
# To exercise the real 403-on-missing-header path (i.e. specs that *intend*
# to assert the JWT enforcement boundary), tag the example or context with
# `:verify_workhorse_jwt`. The tag opts the example out of both the
# injection and the detection.

module WorkhorseJwtInjection
  # Prepend onto ActionDispatch::Integration::Session#process so that every
  # request issued by a request spec (get/post/put/delete/patch) carries the
  # Workhorse JWT in its headers hash unless the active example opts out.
  #
  # Controller specs and feature specs go through a different code path; the
  # RSpec `before` hook below handles them.
  module IntegrationSessionProcessPatch
    def process(method, path, **kwargs)
      example = RSpec.respond_to?(:current_example) ? RSpec.current_example : nil
      skip = example && example.metadata[:verify_workhorse_jwt]

      unless skip
        header_key = ::Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER
        # Merge into a NEW hash (rather than mutating `kwargs[:headers]` in
        # place) for two reasons:
        # 1. Always re-mint a fresh JWT: shared contexts such as the
        #    `'workhorse headers'` let memoize a JWT once per example,
        #    which can outlive the `iat_after` window in long specs that
        #    hold the same `let` across many requests.
        # 2. Many specs pass `headers:` from a `let_it_be(..., freeze: true)`
        #    block; mutating that hash raises `FrozenError`.
        kwargs[:headers] = (kwargs[:headers] || {}).merge(header_key => ::WorkhorseHelpers.jwt_token)
      end

      super
    end
  end
end

ActionDispatch::Integration::Session.prepend(WorkhorseJwtInjection::IntegrationSessionProcessPatch)

RSpec.configure do |config|
  workhorse_header = ::Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER

  # Controller specs: assign on the in-memory TestRequest. Read it via the
  # `@request` instance variable rather than `request`, because many specs
  # define `subject(:request) { get :action, ... }` or `let(:request)` as a
  # side-effect block; calling `request` would lazily evaluate that block
  # before the example body has set up its preconditions.
  #
  # `@request` is populated by `ActionController::TestCase::Behavior#setup`
  # itself, but that runs *after* `before` hooks declared at config level. We
  # therefore probe it defensively and no-op when it isn't ready yet -- the
  # rare specs that don't have an `@request` set up (e.g. fixture-generation
  # paths that drive controllers without the full TestCase setup) simply
  # skip JWT injection and rely on the controller-side guards.
  config.before(type: :controller) do |example|
    next if example.metadata[:verify_workhorse_jwt]

    req = instance_variable_get(:@request)
    next unless req.respond_to?(:headers)

    req.headers[workhorse_header] = ::WorkhorseHelpers.jwt_token
  end

  # Feature and system specs drive a browser through Capybara. For
  # `:js`-tagged specs Capybara starts Puma behind a real workhorse via
  # `Capybara.server = :puma_via_workhorse`, so the request DOES transit
  # workhorse and arrives with a fresh signed JWT. For non-`:js` specs
  # Capybara uses `RackTest`, which bypasses the server and dispatches
  # directly to Rack -- there is no workhorse in the loop, so the request
  # arrives without any `Gitlab-Workhorse-Api-Request` header and the
  # senddata chokepoint helper rejects it with 403.
  #
  # Stub `verify_api_request!` to no-op in feature/system specs. The JWT
  # boundary itself is verified by the unit specs in
  # `spec/lib/gitlab/workhorse_spec.rb` and by `:verify_workhorse_jwt`-
  # tagged request specs; feature specs assert UI behaviour, not the
  # cryptographic guard, so stubbing here does not mask any regression
  # the surrounding test suite was designed to catch.
  config.before(type: :feature) do
    allow(::Gitlab::Workhorse).to receive(:verify_api_request!)
  end
  config.before(type: :system) do
    allow(::Gitlab::Workhorse).to receive(:verify_api_request!)
  end

  # Senddata-emit detector for controller specs. We deliberately do NOT
  # register a `type: :request` variant: request specs frequently bind
  # `let(:request) { get api(url), headers: ... }` as a side-effect helper,
  # and any reference to `request` from an after hook lazy-invokes that
  # block. The `IntegrationSessionProcessPatch` prepend already gives every
  # request spec a valid JWT, which is the substantive guarantee we want.
  config.after(type: :controller) do |example|
    res = instance_variable_get(:@response)
    req = instance_variable_get(:@request)
    next unless res && req

    WorkhorseJwtInjection.detect_unverified_senddata!(example, res, req)
  end
end

module WorkhorseJwtInjection
  def self.detect_unverified_senddata!(example, response, request)
    return if example.metadata[:verify_workhorse_jwt]
    return unless response.respond_to?(:headers)

    send_data = response.headers[::Gitlab::Workhorse::SEND_DATA_HEADER]
    return if send_data.blank?

    begin
      ::Gitlab::Workhorse.verify_api_request!(request.headers)
    rescue StandardError => e
      raise <<~MSG
        Gitlab-Workhorse-Send-Data emitted by #{example.location} without a
        verified Workhorse JWT on the request. Senddata payloads carry Gitaly
        credentials, pre-signed object storage URLs, AI Gateway tokens, and
        similar secrets; emitting them on a request that did not transit
        Workhorse is the threat model this enforcement closes.

        Route the senddata through a guarded helper:
          * lib/api/helpers.rb (Grape):
              send_git_blob, send_git_diff, send_git_archive,
              send_artifacts_entry, present_carrierwave_file!,
              send_workhorse_headers!
          * app/helpers/workhorse_helper.rb (Rails controllers):
              send_git_blob, send_git_diff, send_git_patch,
              send_git_archive, send_artifacts_entry, send_dependency

        Underlying verification error: #{e.class}: #{e.message}
      MSG
    end
  end
end
