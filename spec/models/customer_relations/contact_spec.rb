# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Contact, type: :model do
  let_it_be(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to have_many(:issue_contacts) }
    it { is_expected.to have_many(:issues) }
  end

  describe 'validations' do
    subject { build(:contact) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }

    it { is_expected.to validate_length_of(:phone).is_at_most(32) }
    it { is_expected.to validate_length_of(:first_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:last_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }

    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:group_id) }

    it_behaves_like 'an object with RFC3696 compliant email-formatted attributes', :email
  end

  describe '.reference_prefix' do
    it { expect(described_class.reference_prefix).to eq('[contact:') }
  end

  describe '.reference_prefix_quoted' do
    it { expect(described_class.reference_prefix_quoted).to eq('["contact:') }
  end

  describe '.reference_postfix' do
    it { expect(described_class.reference_postfix).to eq(']') }
  end

  describe '#root_group' do
    context 'when root group' do
      subject { build(:contact, group: group) }

      it { is_expected.to be_valid }
    end

    context 'when subgroup' do
      subject { build(:contact, group: create(:group, parent: group)) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#before_validation' do
    it 'strips leading and trailing whitespace' do
      contact = described_class.new(first_name: '  First  ', last_name: ' Last  ', phone: '  123456 ')
      contact.valid?

      expect(contact.first_name).to eq('First')
      expect(contact.last_name).to eq('Last')
      expect(contact.phone).to eq('123456')
    end
  end

  describe '#self.find_ids_by_emails' do
    let_it_be(:group_contacts) { create_list(:contact, 2, group: group) }
    let_it_be(:other_contacts) { create_list(:contact, 2) }

    it 'returns ids of contacts from group' do
      contact_ids = described_class.find_ids_by_emails(group, group_contacts.pluck(:email))

      expect(contact_ids).to match_array(group_contacts.pluck(:id))
    end

    it 'does not return ids of contacts from other groups' do
      contact_ids = described_class.find_ids_by_emails(group, other_contacts.pluck(:email))

      expect(contact_ids).to be_empty
    end

    it 'raises ArgumentError when called with too many emails' do
      too_many_emails = described_class::MAX_PLUCK + 1
      expect { described_class.find_ids_by_emails(group, Array(0..too_many_emails)) }.to raise_error(ArgumentError)
    end
  end

  describe '#self.exists_for_group?' do
    context 'with no contacts in group' do
      it 'returns false' do
        expect(described_class.exists_for_group?(group)).to be_falsey
      end
    end

    context 'with contacts in group' do
      it 'returns true' do
        create(:contact, group: group)

        expect(described_class.exists_for_group?(group)).to be_truthy
      end
    end
  end
end
