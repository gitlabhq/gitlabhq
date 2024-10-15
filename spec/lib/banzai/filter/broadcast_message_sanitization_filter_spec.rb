# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::BroadcastMessageSanitizationFilter, feature_category: :markdown do
  include FilterSpecHelper

  it_behaves_like 'default allowlist'

  describe 'custom allowlist' do
    subject { filter(exp).to_html }

    context 'allows `a` elements' do
      let(:exp) { %q(<a href="/">Link</a>) }

      it { is_expected.to eq(exp) }
    end

    context 'allows `br` elements' do
      let(:exp) { %q(Hello<br>World) }

      it { is_expected.to eq(exp) }
    end

    context 'when `a` elements have `style` attribute' do
      let(:allowed_style) { 'color: red; border: blue; background: green; padding: 10px; margin: 10px; text-decoration: underline;' }

      context 'allows specific properties' do
        let(:exp) { %(<a href="#" style="#{allowed_style}">Stylish Link</a>) }

        it { is_expected.to eq(exp) }
      end

      it 'disallows other properties in `style` attribute on `a` elements' do
        style = [allowed_style, 'position: fixed'].join(';')
        doc = filter(%(<a href="#" style="#{style}">Stylish Link</a>))

        expect(doc.at_css('a')['style']).to eq(allowed_style)
      end
    end

    context 'allows `class` on `a` elements' do
      let(:exp) { %q(<a href="#" class="btn">Button Link</a>) }

      it { is_expected.to eq(exp) }
    end
  end
end
