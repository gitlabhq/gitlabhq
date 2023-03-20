# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::DestroyLabelLinksService, feature_category: :team_planning do
  describe '#execute' do
    context 'when target is an Issue' do
      let_it_be(:target) { create(:issue) }

      it_behaves_like 'service deleting label links of an issuable'
    end

    context 'when target is a MergeRequest' do
      let_it_be(:target) { create(:merge_request) }

      it_behaves_like 'service deleting label links of an issuable'
    end
  end
end
