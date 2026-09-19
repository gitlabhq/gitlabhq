# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Count, feature_category: :database do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [::Project, ::Identity] }

  describe '.approximate_counts' do
    context 'fallbacks' do
      subject { described_class.approximate_counts(models, strategies: strategies) }

      let(:strategies) do
        [
          double('s1', new: first_strategy),
          double('s2', new: second_strategy)
        ]
      end

      let(:first_strategy) { double('first strategy', count: {}) }
      let(:second_strategy) { double('second strategy', count: {}) }

      it 'gets results from first strategy' do
        expect(strategies[0]).to receive(:new).with(models).and_return(first_strategy)
        expect(first_strategy).to receive(:count)

        subject
      end

      it 'gets more results from second strategy if some counts are missing' do
        expect(first_strategy).to receive(:count).and_return({ ::Project => 3 })
        expect(strategies[1]).to receive(:new).with([::Identity]).and_return(second_strategy)
        expect(second_strategy).to receive(:count).and_return({ ::Identity => 1 })

        expect(subject).to eq({ ::Project => 3, ::Identity => 1 })
      end

      it 'does not get more results as soon as all counts are present' do
        expect(first_strategy).to receive(:count).and_return({ ::Project => 3, ::Identity => 1 })
        expect(strategies[1]).not_to receive(:new)

        subject
      end
    end

    context 'default strategies' do
      subject { described_class.approximate_counts(models) }

      context 'with a read-only database' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'only uses the ExactCountStrategy' do
          allow_next_instance_of(Gitlab::Database::Count::TablesampleCountStrategy) do |instance|
            expect(instance).not_to receive(:count)
          end
          allow_next_instance_of(Gitlab::Database::Count::ReltuplesCountStrategy) do |instance|
            expect(instance).not_to receive(:count)
          end
          expect_next_instance_of(Gitlab::Database::Count::ExactCountStrategy) do |instance|
            expect(instance).to receive(:count).and_return({})
          end

          subject
        end
      end

      context 'with a read-write database' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(false)
        end

        it 'uses the available strategies' do
          [
            Gitlab::Database::Count::TablesampleCountStrategy,
            Gitlab::Database::Count::ReltuplesCountStrategy,
            Gitlab::Database::Count::ExactCountStrategy
          ].each do |strategy_klass|
            expect_next_instance_of(strategy_klass) do |instance|
              expect(instance).to receive(:count).and_return({})
            end
          end

          subject
        end
      end
    end
  end

  describe '.approximate_counts_for_organization' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:other_organization) { create(:organization) }

    let_it_be(:project) { create(:project, organization: organization) }
    let_it_be(:other_project) { create(:project, organization: other_organization) }

    let(:models) { [::Project] }

    subject { described_class.approximate_counts_for_organization(models, organization) }

    it 'exactly counts a regular organization without the statistical strategies' do
      create(:project, organization: organization)

      [
        Gitlab::Database::Count::TablesampleCountStrategy,
        Gitlab::Database::Count::ReltuplesCountStrategy,
        Gitlab::Database::Count::ExactCountStrategy
      ].each do |strategy_klass|
        expect(strategy_klass).not_to receive(:new)
      end

      expect(subject).to eq({ ::Project => 2 })
    end

    context 'with the default organization' do
      before do
        allow(organization).to receive(:default?).and_return(true)
        allow(Gitlab::Database).to receive(:read_only?).and_return(false)
      end

      it 'falls back to the whole-table statistical estimate' do
        [
          Gitlab::Database::Count::TablesampleCountStrategy,
          Gitlab::Database::Count::ReltuplesCountStrategy,
          Gitlab::Database::Count::ExactCountStrategy
        ].each do |strategy_klass|
          expect_next_instance_of(strategy_klass) do |instance|
            allow(instance).to receive(:count).and_return({})
          end
        end

        expect(subject).to eq({})
      end
    end

    context 'when counting a model times out' do
      let(:models) { [::Project, ::Group] }

      before do
        create(:group, organization: organization)

        allow(::Project).to receive(:in_organization)
          .and_raise(ActiveRecord::StatementInvalid.new('timeout'))
      end

      it 'omits only the failing model and still counts the others' do
        expect(subject).to eq({ ::Group => 1 })
      end
    end

    context 'when a model does not support the scope' do
      let(:models) { [::Identity] }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(
          ArgumentError, 'Identity does not respond to :in_organization for organization scoping'
        )
      end
    end

    context 'with a per-model scope override' do
      let_it_be(:homed_user) { create(:user, organization: organization) }

      let_it_be(:member_only_user) do
        create(:user, organization: other_organization).tap do |user|
          create(:organization_user, organization: organization, user: user)
        end
      end

      let(:models) { [::User] }

      subject do
        described_class.approximate_counts_for_organization(
          models, organization, scopes: { ::User => :member_of_organization }
        )
      end

      it 'uses the overridden scope rather than the default' do
        member_count = ::User.member_of_organization(organization).count
        default_count = ::User.in_organization(organization).count

        expect(member_count).to be > default_count
        expect(subject).to eq({ ::User => member_count })
      end

      context 'when the overridden scope is not defined' do
        subject do
          described_class.approximate_counts_for_organization(models, organization, scopes: { ::User => :nonexistent })
        end

        it 'raises ArgumentError' do
          expect { subject }.to raise_error(
            ArgumentError, 'User does not respond to :nonexistent for organization scoping'
          )
        end
      end
    end
  end
end
