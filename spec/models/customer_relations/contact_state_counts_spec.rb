# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::ContactStateCounts do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:counter) { described_class.new(user, group, params) }
  let(:params) { {} }

  before_all do
    group.add_reporter(user)
    create(:contact, group: group, first_name: 'filter')
    create(:contact, group: group, last_name: 'filter')
    create(:contact, group: group)
    create(:contact, group: group, state: 'inactive', email: 'filter@example.com')
    create(:contact, group: group, state: 'inactive')
  end

  describe '.declarative_policy_class' do
    subject { described_class.declarative_policy_class }

    it { is_expected.to eq('CustomerRelations::ContactPolicy') }
  end

  describe '#all' do
    it 'returns the total number of contacts' do
      expect(counter.all).to be(5)
    end
  end

  describe '#active' do
    it 'returns the number of active contacts' do
      expect(counter.active).to be(3)
    end
  end

  describe '#inactive' do
    it 'returns the number of inactive contacts' do
      expect(counter.inactive).to be(2)
    end
  end

  describe 'when filtered' do
    let(:params) { { search: 'filter' } }

    it '#all returns the number of contacts with a filter' do
      expect(counter.all).to be(3)
    end

    it '#active returns the number of active contacts with a filter' do
      expect(counter.active).to be(2)
    end

    it '#inactive returns the number of inactive contacts with a filter' do
      expect(counter.inactive).to be(1)
    end
  end
end
