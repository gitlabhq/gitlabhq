# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Aws::Role do
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

      context 'ARN is nil' do
        let(:role_arn) {}

        it { is_expected.to be_truthy }
      end
    end
  end

  describe 'callbacks' do
    describe '#ensure_role_external_id!' do
      subject { role.validate }

      context 'for a new record' do
        let(:role) { build(:aws_role, role_external_id: nil) }

        it 'calls #ensure_role_external_id!' do
          expect(role).to receive(:ensure_role_external_id!)

          subject
        end
      end

      context 'for an existing record' do
        let(:role) { create(:aws_role) }

        it 'does not call #ensure_role_external_id!' do
          expect(role).not_to receive(:ensure_role_external_id!)

          subject
        end
      end
    end
  end

  describe '#ensure_role_external_id!' do
    let(:role) { build(:aws_role, role_external_id: external_id) }

    subject { role.ensure_role_external_id! }

    context 'role_external_id is blank' do
      let(:external_id) { nil }

      it 'generates an external ID and assigns it to the record' do
        subject

        expect(role.role_external_id).to be_present
      end
    end

    context 'role_external_id is already set' do
      let(:external_id) { 'external-id' }

      it 'does not change the existing external id' do
        subject

        expect(role.role_external_id).to eq external_id
      end
    end
  end
end
