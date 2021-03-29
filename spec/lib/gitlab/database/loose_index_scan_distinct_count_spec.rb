# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LooseIndexScanDistinctCount do
  context 'counting distinct users' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }

    let(:column) { :creator_id }

    before_all do
      create_list(:project, 3, creator: user)
      create_list(:project, 1, creator: other_user)
    end

    subject(:count) { described_class.new(Project, :creator_id).count(from: Project.minimum(:creator_id), to: Project.maximum(:creator_id) + 1) }

    it { is_expected.to eq(2) }

    context 'when STI model is queried' do
      it 'does not raise error' do
        expect { described_class.new(Group, :owner_id).count(from: 0, to: 1) }.not_to raise_error
      end
    end

    context 'when model with default_scope is queried' do
      it 'does not raise error' do
        expect { described_class.new(GroupMember, :id).count(from: 0, to: 1) }.not_to raise_error
      end
    end

    context 'when the fully qualified column is given' do
      let(:column) { 'projects.creator_id' }

      it { is_expected.to eq(2) }
    end

    context 'when AR attribute is given' do
      let(:column) { Project.arel_table[:creator_id] }

      it { is_expected.to eq(2) }
    end

    context 'when invalid value is given for the column' do
      let(:column) { Class.new }

      it { expect { described_class.new(Group, column) }.to raise_error(Gitlab::Database::LooseIndexScanDistinctCount::ColumnConfigurationError) }
    end

    context 'when null values are present' do
      before do
        create_list(:project, 2).each { |p| p.update_column(:creator_id, nil) }
      end

      it { is_expected.to eq(2) }
    end
  end

  context 'counting STI models' do
    let!(:groups) { create_list(:group, 3) }
    let!(:namespaces) { create_list(:namespace, 2) }

    let(:max_id) { Namespace.maximum(:id) + 1 }

    it 'counts groups' do
      count = described_class.new(Group, :id).count(from: 0, to: max_id)
      expect(count).to eq(3)
    end
  end
end
