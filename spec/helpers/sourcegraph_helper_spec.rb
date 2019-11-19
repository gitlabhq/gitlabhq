# frozen_string_literal: true

require 'spec_helper'

describe SourcegraphHelper do
  describe '#sourcegraph_url_message' do
    let(:sourcegraph_url) { 'http://sourcegraph.example.com' }

    before do
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_url).and_return(sourcegraph_url)
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_url_is_com?).and_return(is_com)
    end

    subject { helper.sourcegraph_url_message }

    context 'with .com sourcegraph url' do
      let(:is_com) { true }

      it { is_expected.to have_text('Uses Sourcegraph.com') }
      it { is_expected.to have_link('Sourcegraph.com', href: sourcegraph_url) }
    end

    context 'with custom sourcegraph url' do
      let(:is_com) { false }

      it { is_expected.to have_text('Uses a custom Sourcegraph instance') }
      it { is_expected.to have_link('Sourcegraph instance', href: sourcegraph_url) }

      context 'with unsafe url' do
        let(:sourcegraph_url) { '\" onload=\"alert(1);\"' }

        it { is_expected.to have_link('Sourcegraph instance', href: sourcegraph_url) }
      end
    end
  end

  context '#sourcegraph_experimental_message' do
    let(:feature_conditional) { false }
    let(:public_only) { false }

    before do
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_public_only).and_return(public_only)
      allow(Gitlab::Sourcegraph).to receive(:feature_conditional?).and_return(feature_conditional)
    end

    subject { helper.sourcegraph_experimental_message }

    context 'when not limited by feature or public only' do
      it { is_expected.to eq "This feature is experimental." }
    end

    context 'when limited by feature' do
      let(:feature_conditional) { true }

      it { is_expected.to eq "This feature is experimental and currently limited to certain projects." }
    end

    context 'when limited by public only' do
      let(:public_only) { true }

      it { is_expected.to eq "This feature is experimental and limited to public projects." }
    end
  end
end
