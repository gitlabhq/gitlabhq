# frozen_string_literal: true

require 'spec_helper'

describe Aws::Role do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_length_of(:role_external_id).is_at_least(1).is_at_most(64) }

  describe 'custom validations' do
    subject { role.valid? }

    context ':role_arn' do
      let(:role) { build(:aws_role, role_arn: role_arn) }

      context 'length is zero' do
        let(:role_arn) { '' }

        it { is_expected.to be_falsey }
      end

      context 'length is longer than 2048' do
        let(:role_arn) { '1' * 2049 }

        it { is_expected.to be_falsey }
      end

      context 'ARN is valid' do
        let(:role_arn) { 'arn:aws:iam::123456789012:role/test-role' }

        it { is_expected.to be_truthy }
      end
    end
  end
end
