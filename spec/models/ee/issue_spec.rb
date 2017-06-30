require 'spec_helper'

describe Issue do
  describe '#allows_multiple_assignees?' do
    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: false)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_falsey
    end

    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: true)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_truthy
    end
  end

  describe '#weight' do
    [
      { license: true,  database: 5,    expected: 5 },
      { license: true,  database: nil,  expected: nil },
      { license: false, database: 5,    expected: nil },
      { license: false, database: nil,  expected: nil }
    ].each do |spec|
      context spec.inspect do
        let(:spec) { spec }
        let(:issue) { build(:issue, weight: spec[:database]) }

        subject { issue.weight }

        before do
          stub_licensed_features(issue_weights: spec[:license])
        end

        it { is_expected.to eq(spec[:expected]) }
      end
    end
  end
end
