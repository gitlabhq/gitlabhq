# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Sidebars::Concerns::LinkWithHtmlOptions, feature_category: :navigation do
  let(:options) { {} }

  subject { Class.new { include Sidebars::Concerns::LinkWithHtmlOptions }.new }

  before do
    allow(subject).to receive(:container_html_options).and_return(options)
  end

  describe '#link_html_options' do
    context 'with existing classes' do
      let(:options) do
        {
          class: '_class1_ _class2_',
          aria: { label: '_label_' }
        }
      end

      it 'includes class and default aria-label attribute' do
        result = {
          class: '_class1_ _class2_ gl-link',
          aria: { label: '_label_' }
        }

        expect(subject.link_html_options).to eq(result)
      end
    end

    context 'without existing classes' do
      it 'includes gl-link class' do
        expect(subject.link_html_options).to eq(class: 'gl-link')
      end
    end
  end
end
