# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PostProcessPipeline, feature_category: :markdown do
  subject { described_class.call(doc, context) }

  let_it_be(:project) { create(:project, :public, :repository) }

  let(:context) { { project: project, ref: 'master' } }

  context 'when a document only has upload links' do
    let(:doc) do
      <<-HTML.strip_heredoc
        <a href="/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg">Relative Upload Link</a>
        <img src="/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg">
      HTML
    end

    it 'does not make any Gitaly calls', :request_store do
      Gitlab::GitalyClient.reset_counts

      subject

      expect(Gitlab::GitalyClient.get_request_count).to eq(0)
    end
  end

  context 'when both upload and repository links are present' do
    let(:html) do
      <<-HTML.strip_heredoc
        <a href="/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg">Relative Upload Link</a>
        <img src="/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg">
        <a href="/test.jpg">Just a link</a>
      HTML
    end

    let(:doc) { HTML::Pipeline.parse(html) }
    let(:non_related_xpath_calls) { 1 }

    it 'searches for attributes only once' do
      expect(doc).to receive(:xpath).exactly(non_related_xpath_calls + 1).times
        .and_call_original

      subject
    end
  end
end
