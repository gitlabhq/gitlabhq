# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ChangesList, feature_category: :source_code_management do
  let(:valid_changes_string) { "\n000000 570e7b2 refs/heads/my_branch\nd14d6c 6fd24d refs/heads/master" }
  let(:invalid_changes) { 1 }

  context 'when changes is a valid string' do
    let(:changes_list) { described_class.new(valid_changes_string) }

    it 'splits elements by newline character' do
      expect(changes_list).to contain_exactly({
        oldrev: "000000",
        newrev: "570e7b2",
        ref: "refs/heads/my_branch"
      }, {
        oldrev: "d14d6c",
        newrev: "6fd24d",
        ref: "refs/heads/master"
      })
    end

    it 'behaves like a list' do
      expect(changes_list.first).to eq({
        oldrev: "000000",
        newrev: "570e7b2",
        ref: "refs/heads/my_branch"
      })
    end
  end
end
