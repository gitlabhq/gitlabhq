# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Abuse::Reports::UserMention, feature_category: :insider_threat do
  describe 'associations' do
    it { is_expected.to belong_to(:abuse_report).optional(false) }
    it { is_expected.to belong_to(:note).optional(false) }
  end

  it_behaves_like 'has user mentions'
end
