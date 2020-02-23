# frozen_string_literal: true

RSpec.shared_examples 'setting CSP connect-src' do
  let_it_be(:default_csp_values) { "'self' https://some-cdn.test" }

  shared_context 'csp config' do |csp_rule|
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.send(csp_rule, default_csp_values) if csp_rule
      end

      expect_next_instance_of(extended_controller_class) do |controller|
        expect(controller).to receive(:current_content_security_policy).and_return(csp)
      end
    end
  end

  context 'when no CSP config' do
    include_context 'csp config', nil

    it 'does not add CSP directives' do
      is_expected.to be_blank
    end
  end

  describe 'when a CSP config exists for connect-src' do
    include_context 'csp config', :connect_src

    context 'when feature is enabled' do
      it 'appends to connect-src' do
        is_expected.to eql("connect-src #{default_csp_values} #{whitelisted_url}")
      end
    end

    context 'when feature is disabled' do
      include_context 'disable feature'

      it 'keeps original connect-src' do
        is_expected.to eql("connect-src #{default_csp_values}")
      end
    end
  end

  describe 'when a CSP config exists for default-src but not connect-src' do
    include_context 'csp config', :default_src

    context 'when feature is enabled' do
      it 'uses default-src values in connect-src' do
        is_expected.to eql("default-src #{default_csp_values}; connect-src #{default_csp_values} #{whitelisted_url}")
      end
    end

    context 'when feature is disabled' do
      include_context 'disable feature'

      it 'does not add connect-src' do
        is_expected.to eql("default-src #{default_csp_values}")
      end
    end
  end

  describe 'when a CSP config exists for font-src but not connect-src' do
    include_context 'csp config', :font_src

    context 'when feature is enabled' do
      it 'uses default-src values in connect-src' do
        is_expected.to eql("font-src #{default_csp_values}; connect-src #{whitelisted_url}")
      end
    end

    context 'when feature is disabled' do
      include_context 'disable feature'

      it 'does not add connect-src' do
        is_expected.to eql("font-src #{default_csp_values}")
      end
    end
  end
end
