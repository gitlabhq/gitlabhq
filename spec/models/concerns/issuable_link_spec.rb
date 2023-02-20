# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableLink do
  let(:test_class) do
    Class.new(ApplicationRecord) do
      include IssuableLink

      self.table_name = 'issue_links'

      belongs_to :source, class_name: 'Issue'
      belongs_to :target, class_name: 'Issue'

      def self.name
        'TestClass'
      end
    end
  end

  describe '.inverse_link_type' do
    it 'returns the inverse type of link' do
      expect(test_class.inverse_link_type('relates_to')).to eq('relates_to')
    end
  end

  describe '.issuable_type' do
    let_it_be(:source_issue) { create(:issue) }
    let_it_be(:target_issue) { create(:issue) }

    before do
      test_class.create!(source: source_issue, target: target_issue)
    end

    context 'when opposite relation already exists' do
      it 'raises NotImplementedError when performing validations' do
        instance = test_class.new(source: target_issue, target: source_issue)

        expect { instance.save! }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '.available_link_types' do
    let(:expected_link_types) do
      if Gitlab.ee?
        %w[relates_to blocks is_blocked_by]
      else
        %w[relates_to]
      end
    end

    subject { test_class.available_link_types }

    it { is_expected.to match_array(expected_link_types) }
  end
end
