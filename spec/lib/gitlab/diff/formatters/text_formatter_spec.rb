require 'spec_helper'

describe Gitlab::Diff::Formatters::TextFormatter do
  let!(:base) do
    {
      base_sha: 123,
      start_sha: 456,
      head_sha: 789,
      old_path: 'old_path.txt',
      new_path: 'new_path.txt'
    }
  end

  let!(:complete) do
    base.merge(old_line: 1, new_line: 2)
  end

  it_behaves_like "position formatter" do
    let(:base_attrs) { base }

    let(:attrs) { complete }
  end

  # Specific text formatter examples
  let!(:formatter) { described_class.new(attrs) }

  describe '#line_age' do
    subject { formatter.line_age }

    context ' when there is only new_line' do
      let(:attrs) { base.merge(new_line: 1) }

      it { is_expected.to eq('new') }
    end

    context ' when there is only old_line' do
      let(:attrs) { base.merge(old_line: 1) }

      it { is_expected.to eq('old') }
    end
  end
end
