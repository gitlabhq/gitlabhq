# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Pipeline::PostProcessPipeline do
  context 'when a document only has upload links' do
    it 'does not make any Gitaly calls', :request_store do
      markdown = <<-MARKDOWN.strip_heredoc
        [Relative Upload Link](/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg)

        ![Relative Upload Image](/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg)
      MARKDOWN

      context = {
        project: create(:project, :public, :repository),
        ref: 'master'
      }

      Gitlab::GitalyClient.reset_counts

      described_class.call(markdown, context)

      expect(Gitlab::GitalyClient.get_request_count).to eq(0)
    end
  end
end
