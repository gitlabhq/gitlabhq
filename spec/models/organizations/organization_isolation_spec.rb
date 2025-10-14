# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationIsolation, feature_category: :organization do
  let(:factory_name) { :organization_isolation }

  it_behaves_like 'an IsolationRecord model'

  describe 'associations' do
    it "belongs to organization" do
      is_expected.to belong_to(:organization).class_name('Organizations::Organization').inverse_of(:isolated_record)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:organization) }
  end

  describe 'database constraints' do
    let_it_be(:organization) { create(:organization) }

    it 'enforces unique organization_id' do
      create(:organization_isolation, organization: organization)

      expect do
        create(:organization_isolation, organization: organization)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'enforces not null constraint on organization_id' do
      expect do
        described_class.new(organization_id: nil, isolated: false).save!(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces not null constraint on isolated' do
      expect do
        described_class.new(organization: organization, isolated: nil).save!(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
