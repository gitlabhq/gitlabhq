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
end
