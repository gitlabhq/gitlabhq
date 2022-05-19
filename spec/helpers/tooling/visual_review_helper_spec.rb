# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tooling::VisualReviewHelper do
  describe '#visual_review_toolbar_options' do
    subject(:result) { helper.visual_review_toolbar_options }

    before do
      stub_env('REVIEW_APPS_MERGE_REQUEST_IID', '123')
    end

    it 'returns the correct params' do
      expect(result).to eq(
        'data-merge-request-id': '123',
        'data-mr-url': 'https://gitlab.com',
        'data-project-id': '278964',
        'data-project-path': 'gitlab-org/gitlab',
        'data-require-auth': false,
        'id': 'review-app-toolbar-script',
        'src': 'https://gitlab.com/assets/webpack/visual_review_toolbar.js'
      )
    end
  end
end
