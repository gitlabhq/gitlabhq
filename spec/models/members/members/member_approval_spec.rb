# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::MemberApproval, feature_category: :groups_and_projects do
  describe 'associations' do
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:member_namespace) }
    it { is_expected.to belong_to(:reviewed_by) }
    it { is_expected.to belong_to(:requested_by) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:new_access_level) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:member_namespace) }

    context 'with metadata' do
      subject { build(:member_approval, metadata: attribute_mapping) }

      context 'with valid JSON schemas' do
        let(:attribute_mapping) do
          {
            expires_at: expiry,
            member_role_id: nil
          }
        end

        context 'with empty metadata' do
          let(:attribute_mapping) { {} }

          it { is_expected.to be_valid }
        end

        context 'with date expiry' do
          let(:expiry) { "1970-01-01" }

          it { is_expected.to be_valid }
        end

        context 'with empty expiry' do
          let(:expiry) { "" }

          it { is_expected.to be_valid }
        end

        context 'with nil expiry' do
          let(:expiry) { nil }

          it { is_expected.to be_valid }
        end

        context 'with not null member_role_id' do
          let(:attribute_mapping) do
            {
              member_role_id: 3
            }
          end

          it { is_expected.to be_valid }
        end

        context 'when property has extra attributes' do
          let(:attribute_mapping) do
            { access_level: 20 }
          end

          it { is_expected.to be_valid }
        end
      end

      context 'with invalid JSON schemas' do
        shared_examples 'is invalid record' do
          it do
            expect(subject).to be_invalid
            expect(subject.errors.messages[:metadata]).to eq(['must be a valid json schema'])
          end
        end

        context 'when property is not an object' do
          let(:attribute_mapping) do
            "That is not a valid schema"
          end

          it_behaves_like 'is invalid record'
        end

        context 'with invalid expiry' do
          let(:attribute_mapping) do
            {
              expires_at: "1242"
            }
          end

          it_behaves_like 'is invalid record'
        end

        context 'with member_role_id' do
          let(:attribute_mapping) do
            {
              member_role_id: "some role"
            }
          end

          it_behaves_like 'is invalid record'
        end
      end
    end
  end
end
