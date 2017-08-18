require 'spec_helper'

describe Editable do
  describe '#is_edited?' do
    let(:issue) { create(:issue, last_edited_at: nil) }
    let(:edited_issue) { create(:issue, created_at: 3.days.ago, last_edited_at: 2.days.ago) }

    it { expect(issue.is_edited?).to eq(false) }
    it { expect(edited_issue.is_edited?).to eq(true) }
  end
end
