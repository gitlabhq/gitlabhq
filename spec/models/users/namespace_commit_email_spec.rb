# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::NamespaceCommitEmail, type: :model do
  subject { build(:namespace_commit_email) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:email) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:email) }
  end

  it { is_expected.to be_valid }
end
