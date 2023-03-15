# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineObservabilityFilter, feature_category: :metrics do
  include FilterSpecHelper

  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  before do
    allow(Gitlab::Observability).to receive(:embeddable_url).and_return('embeddable-url')
    stub_config_setting(url: "https://www.gitlab.com")
  end

  describe '#filter?' do
    context 'when the document contains a valid observability link' do
      let(:url) { "https://www.gitlab.com/groups/some-group/-/observability/test" }

      it 'leaves the original link unchanged' do
        expect(doc.at_css('a').to_s).to eq(input)
      end

      it 'appends an observability charts placeholder' do
        node = doc.at_css('.js-render-observability')

        expect(node).to be_present
        expect(node.attribute('data-frame-url').to_s).to eq('embeddable-url')
        expect(Gitlab::Observability).to have_received(:embeddable_url).with(url).once
      end
    end

    context 'with duplicate URLs' do
      let(:url) { "https://www.gitlab.com/groups/some-group/-/observability/test" }
      let(:input) { %(<a href="#{url}">example1</a><a href="#{url}">example2</a>) }

      where(:embeddable_url) do
        [
          'not-nil',
          nil
        ]
      end

      with_them do
        it 'calls Gitlab::Observability.embeddable_url only once' do
          allow(Gitlab::Observability).to receive(:embeddable_url).with(url).and_return(embeddable_url)

          filter(input)

          expect(Gitlab::Observability).to have_received(:embeddable_url).with(url).once
        end
      end
    end

    shared_examples 'does not embed observabilty' do
      it 'leaves the original link unchanged' do
        expect(doc.at_css('a').to_s).to eq(input)
      end

      it 'does not append an observability charts placeholder' do
        node = doc.at_css('.js-render-observability')

        expect(node).not_to be_present
      end
    end

    context 'when the embeddable url is nil' do
      let(:url) { "https://www.gitlab.com/groups/some-group/-/something-else/test" }

      before do
        allow(Gitlab::Observability).to receive(:embeddable_url).and_return(nil)
      end

      it_behaves_like 'does not embed observabilty'
    end

    context 'when the document has an unrecognised link' do
      let(:url) { "https://www.gitlab.com/groups/some-group/-/something-else/test" }

      it_behaves_like 'does not embed observabilty'

      it 'does not build the embeddable url' do
        expect(Gitlab::Observability).not_to have_received(:embeddable_url)
      end
    end

    context 'when feature flag is disabled' do
      let(:url) { "https://www.gitlab.com/groups/some-group/-/observability/test" }

      before do
        stub_feature_flags(observability_group_tab: false)
      end

      it_behaves_like 'does not embed observabilty'

      it 'does not build the embeddable url' do
        expect(Gitlab::Observability).not_to have_received(:embeddable_url)
      end
    end
  end
end
