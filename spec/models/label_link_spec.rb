# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelLink do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  subject { build(:label_link, target: issue) }

  it { is_expected.to be_valid }

  it { is_expected.to belong_to(:label) }
  it { is_expected.to belong_to(:target) }

  it_behaves_like 'a BulkInsertSafe model', described_class do
    let(:valid_items_for_bulk_insertion) do
      build_list(:label_link, 10, target: issue, namespace_id: issue.namespace_id)
    end

    let(:invalid_items_for_bulk_insertion) do
      [build(:label_link, target: issue, label: nil, namespace_id: issue.namespace_id)]
    end
  end

  describe 'validations' do
    describe 'label presence' do
      it { is_expected.to validate_presence_of(:label) }

      context 'when importing' do
        subject { build(:label_link, importing: true) }

        it { is_expected.to validate_presence_of(:label) }
      end
    end

    describe 'target presence' do
      it { is_expected.to validate_presence_of(:target) }

      context 'when importing' do
        subject { build(:label_link, importing: true) }

        it { is_expected.to validate_presence_of(:target) }
      end
    end

    describe 'namespace presence' do
      subject { build(:label_link) }

      it { is_expected.to validate_presence_of(:namespace) }

      context 'when importing' do
        subject { build(:label_link, importing: true) }

        it { is_expected.to validate_presence_of(:namespace) }
      end
    end
  end

  describe '.for_target' do
    it 'returns the label links for a given target' do
      label_link = create(:label_link, target: create(:merge_request))

      create(:label_link, target: create(:issue))

      expect(described_class.for_target(label_link.target_id, label_link.target_type))
        .to contain_exactly(label_link)
    end
  end
end
