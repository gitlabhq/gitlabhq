# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::BroadcastMessageSanitizationFilter do
  include FilterSpecHelper

  it_behaves_like 'default whitelist'

  describe 'custom whitelist' do
    it_behaves_like 'XSS prevention'
    it_behaves_like 'sanitize link'

    subject { filter(exp).to_html }

    context 'allows `a` elements' do
      let(:exp) { %q{<a href="/">Link</a>} }

      it { is_expected.to eq(exp) }
    end

    context 'allows `br` elements' do
      let(:exp) { %q{Hello<br>World} }

      it { is_expected.to eq(exp) }
    end

    context 'when `a` elements have `style` attribute' do
      let(:whitelisted_style) { 'color: red; border: blue; background: green; padding: 10px; margin: 10px; text-decoration: underline;' }

      context 'allows specific properties' do
        let(:exp) { %{<a href="#" style="#{whitelisted_style}">Stylish Link</a>} }

        it { is_expected.to eq(exp) }
      end

      it 'disallows other properties in `style` attribute on `a` elements' do
        style = [whitelisted_style, 'position: fixed'].join(';')
        doc = filter(%{<a href="#" style="#{style}">Stylish Link</a>})

        expect(doc.at_css('a')['style']).to eq(whitelisted_style)
      end
    end

    context 'allows `class` on `a` elements' do
      let(:exp) { %q{<a href="#" class="btn">Button Link</a>} }

      it { is_expected.to eq(exp) }
    end
  end
end
