# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddNewPostEoaPlans do
  let(:plans) { table(:plans) }

  subject(:migration) { described_class.new }

  describe '#up' do
    it 'creates the two new records' do
      expect { migration.up }.to change { plans.count }.by(2)

      new_plans = plans.last(2)
      expect(new_plans.map(&:name)).to contain_exactly('premium', 'ultimate')
    end
  end

  describe '#down' do
    it 'removes these two new records' do
      plans.create!(name: 'premium', title: 'Premium (Formerly Silver)')
      plans.create!(name: 'ultimate', title: 'Ultimate (Formerly Gold)')

      expect { migration.down }.to change { plans.count }.by(-2)

      expect(plans.find_by(name: 'premium')).to be_nil
      expect(plans.find_by(name: 'ultimate')).to be_nil
    end
  end
end
