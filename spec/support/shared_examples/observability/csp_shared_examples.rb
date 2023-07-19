# frozen_string_literal: true

# Verifies that the proper CSP rules for Observabilty UI are applied to a given controller/path
#
# It requires the following variables declared in the context including this example:
#
# - `tested_path`: the path under test
#
# e.g.
#
# ```
#   it_behaves_like "observability csp policy" do
#     let(:tested_path) { ....the path under test }
#   end
# ```
#
# Note that the context's user is expected to be logged-in and the
# related resources (group, project, etc)  are supposed to be provided with proper
# permissions already, e.g.
#
# before do
#   login_as(user)
#   group.add_developer(user)
# end
#
# It optionally supports specifying the controller class handling the tested path as a parameter, e.g.
#
# ```
#   it_behaves_like "observability csp policy", Projects::TracingController
# ```
# (If not specified it will default to `described_class`)
#
RSpec.shared_examples 'observability csp policy' do |controller_class = described_class|
  include ContentSecurityPolicyHelpers

  let(:observability_url) { Gitlab::Observability.observability_url }
  let(:signin_url) do
    Gitlab::Utils.append_path(Gitlab.config.gitlab.url,
      '/users/sign_in')
  end

  let(:oauth_url) do
    Gitlab::Utils.append_path(Gitlab.config.gitlab.url,
      '/oauth/authorize')
  end

  before do
    setup_csp_for_controller(controller_class, csp, any_time: true)
  end

  subject do
    get tested_path
    response.headers['Content-Security-Policy']
  end

  context 'when there is no CSP config' do
    let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

    it 'does not add any csp header' do
      expect(subject).to be_blank
    end
  end

  describe 'frame-src' do
    context 'when frame-src exists in the CSP config' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.frame_src 'https://something.test'
        end
      end

      it 'appends the proper url to frame-src CSP directives' do
        expect(subject).to include(
          "frame-src https://something.test #{observability_url} #{signin_url} #{oauth_url}")
      end
    end

    context 'when signin url is already present in the policy' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.frame_src signin_url
        end
      end

      it 'does not append signin again' do
        expect(subject).to include(
          "frame-src #{signin_url} #{observability_url} #{oauth_url};")
      end
    end

    context 'when oauth url is already present in the policy' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.frame_src oauth_url
        end
      end

      it 'does not append oauth again' do
        expect(subject).to include(
          "frame-src #{oauth_url} #{observability_url} #{signin_url};")
      end
    end

    context 'when default-src exists in the CSP config' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.default_src 'https://something.test'
        end
      end

      it 'does not change default-src' do
        expect(subject).to include(
          "default-src https://something.test;")
      end

      it 'appends the proper url to frame-src CSP directives' do
        expect(subject).to include(
          "frame-src https://something.test #{observability_url} #{signin_url} #{oauth_url}")
      end
    end

    context 'when frame-src and default-src exist in the CSP config' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.default_src 'https://something_default.test'
          p.frame_src 'https://something.test'
        end
      end

      it 'appends to frame-src CSP directives' do
        expect(subject).to include(
          "frame-src https://something.test #{observability_url} #{signin_url} #{oauth_url}")
        expect(subject).to include(
          "default-src https://something_default.test")
      end
    end
  end

  describe 'connect-src' do
    context 'when connect-src exists in the CSP config' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.connect_src 'https://something.test'
        end
      end

      it 'appends the proper url to connect-src CSP directives' do
        expect(subject).to include(
          "connect-src https://something.test localhost #{observability_url}")
      end
    end

    context 'when default-src exists in the CSP config' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.default_src 'https://something.test'
        end
      end

      it 'does not change default-src' do
        expect(subject).to include(
          "default-src https://something.test;")
      end

      it 'appends the proper url to connect-src CSP directives' do
        expect(subject).to include(
          "connect-src https://something.test localhost #{observability_url}")
      end
    end

    context 'when connect-src and default-src exist in the CSP config' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.default_src 'https://something_default.test'
          p.connect_src 'https://something.test'
        end
      end

      it 'appends to connect-src CSP directives' do
        expect(subject).to include(
          "connect-src https://something.test localhost #{observability_url}")
        expect(subject).to include(
          "default-src https://something_default.test")
      end
    end
  end
end
