# frozen_string_literal: true

# Verifies that the proper CSP rules for Observabilty UI are applied to a given controller/path
#
# The path under test needs to be declared with  `let(:tested_path) { .. }` in the context including this example
#
# ```
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

  before do
    setup_csp_for_controller(described_class, csp)
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

  context 'when frame-src exists in the CSP config' do
    let(:csp) do
      ActionDispatch::ContentSecurityPolicy.new do |p|
        p.frame_src 'https://something.test'
      end
    end

    it 'appends the proper url to frame-src CSP directives' do
      expect(subject).to include(
        "frame-src https://something.test #{observability_url} 'self'")
    end
  end

  context 'when self is already present in the policy' do
    let(:csp) do
      ActionDispatch::ContentSecurityPolicy.new do |p|
        p.frame_src "'self'"
      end
    end

    it 'does not append self again' do
      expect(subject).to include(
        "frame-src 'self' #{observability_url};")
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
        "frame-src https://something.test #{observability_url} 'self'")
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
        "frame-src https://something.test #{observability_url} 'self'")
      expect(subject).to include(
        "default-src https://something_default.test")
    end
  end
end
