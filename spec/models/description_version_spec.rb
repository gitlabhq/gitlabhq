# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DescriptionVersion do
  describe 'associations' do
    it { is_expected.to belong_to :issue }
    it { is_expected.to belong_to :merge_request }
  end

  describe 'validations' do
    describe 'exactly_one_issuable' do
      using RSpec::Parameterized::TableSyntax

      subject { described_class.new(issue_id: issue_id, merge_request_id: merge_request_id).valid? }

      where(:issue_id, :merge_request_id, :valid?) do
        nil | 1   | true
        1   | nil | true
        nil | nil | false
        1   | 1   | false
      end

      with_them do
        it { is_expected.to eq(valid?) }
      end
    end
  end
end
