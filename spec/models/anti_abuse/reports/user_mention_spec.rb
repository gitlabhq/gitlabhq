# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::Reports::UserMention, feature_category: :insider_threat do
  subject(:user_mention) { build(:abuse_report_user_mention) }

  describe 'associations' do
    it { is_expected.to belong_to(:abuse_report).optional(false) }
    it { is_expected.to belong_to(:note).optional(false) }
    it { is_expected.to belong_to(:organization) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:organization_id) }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'abuse_report_id' }
    let_it_be(:user) { create(:user, :with_namespace) }
    let_it_be(:mentionable) { create(:abuse_report, user: user, reporter: user) }
    let_it_be(:additional_params) { { organization_id: mentionable.organization_id } }
  end
end
