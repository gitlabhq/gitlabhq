require 'spec_helper'

describe Editable do
  describe '#edited?' do
    let(:issue) { create(:issue, last_edited_at: nil) }
    let(:edited_issue) { create(:issue, created_at: 3.days.ago, last_edited_at: 2.days.ago) }

    it { expect(issue.edited?).to eq(false) }
    it { expect(edited_issue.edited?).to eq(true) }
  end
end
