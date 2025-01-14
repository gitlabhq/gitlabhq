# frozen_string_literal: true

RSpec.shared_examples 'setting CSP' do |rule_name|
  let_it_be(:default_csp_values) { "'self' https://some-cdn.test" }

  shared_context 'csp config' do |csp_rule|
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.send(csp_rule, *default_csp_values.split(' ')) if csp_rule
      end

      expect_next_instance_of(extended_controller_class) do |controller|
        expect(controller).to receive(:current_content_security_policy).at_least(:once).and_return(csp)
      end
    end
  end

  context 'csp config and feature toggle', :do_not_stub_snowplow_by_default do
    context 'when no CSP config' do
      include_context 'csp config', nil

      it 'does not add CSP directives' do
        is_expected.to be_blank
      end
    end

    describe "when a CSP config exists for #{rule_name}" do
      include_context 'csp config', rule_name.parameterize.underscore.to_sym

      context 'when feature is enabled' do
        it "appends to #{rule_name}" do
          is_expected.to include("#{rule_name} #{default_csp_values}")
          is_expected.to include(allowlisted_url)
        end
      end

      context 'when feature is disabled' do
        include_context 'disable feature'

        it "keeps original #{rule_name}" do
          is_expected.to include("#{rule_name} #{default_csp_values}")
        end
      end
    end

    describe "when a CSP config exists for default-src but not #{rule_name}" do
      include_context 'csp config', :default_src

      context 'when feature is enabled' do
        it "uses default-src values in #{rule_name}" do
          is_expected.to include("default-src #{default_csp_values}")
          is_expected.to include(allowlisted_url)
        end
      end

      context 'when feature is disabled' do
        include_context 'disable feature'

        it "does not add #{rule_name}" do
          is_expected.to include("default-src #{default_csp_values}")
        end
      end
    end

    describe "when a CSP config exists for font-src but not #{rule_name}" do
      include_context 'csp config', :font_src

      context 'when feature is enabled' do
        it "uses default-src values in #{rule_name}" do
          is_expected.to include("font-src #{default_csp_values}")
          is_expected.not_to include("#{rule_name} #{default_csp_values}")
        end
      end

      context 'when feature is disabled' do
        include_context 'disable feature'

        it "does not add #{rule_name}" do
          is_expected.to include("font-src #{default_csp_values}")
        end
      end
    end
  end
end
