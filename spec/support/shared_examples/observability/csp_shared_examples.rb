# frozen_string_literal: true

# Verifies that the proper CSP rules for Observabilty UI are applied to a given controller/path
#
# It requires the following variables declared in the context including this example:
#
# - `tested_path`: the path under test
# - `user`: the test user
# - `group`: the test group
#
# e.g.
#
# ```
#   let_it_be(:group) { create(:group) }
#   let_it_be(:user) { create(:user) }
#   it_behaves_like "observability csp policy" do
#     let(:tested_path) { ....the path under test }
#   end
# ```
#
# It optionally supports specifying the controller class handling the tested path as a parameter, e.g.
#
# ```
#   it_behaves_like "observability csp policy", Groups::ObservabilityController
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
    group.add_developer(user)
    login_as(user)
    stub_feature_flags(observability_group_tab: true)
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

  context 'when observability is disabled' do
    let(:csp) do
      ActionDispatch::ContentSecurityPolicy.new do |p|
        p.frame_src 'https://something.test'
      end
    end

    before do
      stub_feature_flags(observability_group_tab: false)
    end

    it 'does not add observability urls to the csp header' do
      expect(subject).to include("frame-src https://something.test")
      expect(subject).not_to include("#{observability_url} #{signin_url} #{oauth_url}")
    end
  end

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

  context 'when signin is already present in the policy' do
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

  context 'when oauth is already present in the policy' do
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
