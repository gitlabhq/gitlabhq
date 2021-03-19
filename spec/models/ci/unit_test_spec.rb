# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnitTest do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:unit_test_failures) }
  end

  describe 'validations' do
    subject { build(:ci_unit_test) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:key_hash) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:suite_name) }
  end

  describe '.find_or_create_by_batch' do
    let(:project) { create(:project) }

    it 'finds or creates records for the given unit test keys', :aggregate_failures do
      existing_test = create(:ci_unit_test, project: project, suite_name: 'rspec', name: 'Math#sum adds numbers')
      new_key = Digest::SHA256.hexdigest(SecureRandom.hex)
      attrs = [
        {
          key_hash: existing_test.key_hash,
          name: 'This new name will not apply',
          suite_name: 'This new suite name will not apply'
        },
        {
          key_hash: new_key,
          name: 'Component works',
          suite_name: 'jest'
        }
      ]

      result = described_class.find_or_create_by_batch(project, attrs)

      expect(result).to match_array([
        have_attributes(
          key_hash: existing_test.key_hash,
          suite_name: 'rspec',
          name: 'Math#sum adds numbers'
        ),
        have_attributes(
          key_hash: new_key,
          suite_name: 'jest',
          name: 'Component works'
        )
      ])

      expect(result).to all(be_persisted)
    end

    context 'when a given name or suite_name exceeds the string size limit' do
      before do
        stub_const("#{described_class}::MAX_NAME_SIZE", 6)
        stub_const("#{described_class}::MAX_SUITE_NAME_SIZE", 6)
      end

      it 'truncates the values before storing the information' do
        new_key = Digest::SHA256.hexdigest(SecureRandom.hex)
        attrs = [
          {
            key_hash: new_key,
            name: 'abcdefg',
            suite_name: 'abcdefg'
          }
        ]

        result = described_class.find_or_create_by_batch(project, attrs)

        expect(result).to match_array([
          have_attributes(
            key_hash: new_key,
            suite_name: 'abc...',
            name: 'abc...'
          )
        ])

        expect(result).to all(be_persisted)
      end
    end
  end
end
