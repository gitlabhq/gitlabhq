# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelLink do
  it { expect(build(:label_link)).to be_valid }

  it { is_expected.to belong_to(:label) }
  it { is_expected.to belong_to(:target) }

  it_behaves_like 'a BulkInsertSafe model', LabelLink do
    let(:valid_items_for_bulk_insertion) { build_list(:label_link, 10) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'scopes' do
    describe '.for_target' do
      it 'returns the label links for a given target' do
        label_link = create(:label_link, target: create(:merge_request))

        create(:label_link, target: create(:issue))

        expect(described_class.for_target(label_link.target_id, label_link.target_type))
          .to contain_exactly(label_link)
      end
    end

    describe '.with_remove_on_close_labels' do
      it 'responds with label_links that can be removed when an issue is closed' do
        issue = create(:issue)
        removable_label = create(:label, project: issue.project, remove_on_close: true)
        create(:label_link, target: issue)
        removable_issue_label_link = create(:label_link, label: removable_label, target: issue)

        expect(described_class.with_remove_on_close_labels).to contain_exactly(removable_issue_label_link)
      end
    end
  end
end
