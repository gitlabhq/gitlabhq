# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Contact, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:organization).optional }
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

    it_behaves_like 'an object with RFC3696 compliant email-formatted attributes', :email
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
end
