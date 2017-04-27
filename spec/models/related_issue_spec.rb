require 'spec_helper'

describe RelatedIssue do
  describe "Associations" do
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:related_issue).class_name('Issue') }
  end

  describe "Validation" do
    subject { create :related_issue }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:related_issue) }
    it { is_expected.to validate_uniqueness_of(:issue).scoped_to(:related_issue_id) }
  end
end
