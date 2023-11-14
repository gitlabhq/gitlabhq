# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::Formatters::FileFormatter, feature_category: :code_review_workflow do
  let(:base_attrs) do
    {
      base_sha: 123,
      start_sha: 456,
      head_sha: 789,
      old_path: nil,
      new_path: nil,
      position_type: 'file'
    }
  end

  let(:attrs) { base_attrs.merge(old_path: 'path.rb', new_path: 'path.rb') }

  it_behaves_like 'position formatter' do
    # rubocop:disable Fips/SHA1 -- This is used to match the existing class method
    let(:key) do
      [123, 456, 789,
        Digest::SHA1.hexdigest(formatter.old_path), Digest::SHA1.hexdigest(formatter.new_path),
        'path.rb', 'path.rb']
    end
    # rubocop:enable Fips/SHA1
  end

  describe '#==' do
    subject { described_class.new(attrs) }

    it { is_expected.to eq(subject) }

    [:old_path, :new_path].each do |attr|
      context "with attribute:#{attr}" do
        let(:other_formatter) do
          described_class.new(attrs.merge(attr => 9))
        end

        it { is_expected.not_to eq(other_formatter) }
      end
    end
  end
end
