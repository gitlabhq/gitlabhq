# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Enumerable, feature_category: :cell do
  using RSpec::Parameterized::TableSyntax

  before_all do
    ActiveRecord::Schema.define do
      create_table :_test_member_sources, force: true
    end
  end

  before do
    stub_const('TestMemberSource', klass)

    # rubocop:disable RSpec/AnyInstanceOf -- stub all instances, hooks and notifications are irrelevant to the tests.
    allow_any_instance_of(SystemHooksService).to receive(:execute_hooks_for)
    allow_any_instance_of(Member).to receive_messages(notifiable?: false, send_request: nil)
    # rubocop:enable RSpec/AnyInstanceOf
  end

  let_it_be(:klass) do
    Class.new(Namespace) do
      include Members::Enumerable

      self.table_name = '_test_member_sources'

      has_many :members, dependent: :destroy, as: :source, class_name: '::Member'
    end
  end

  let_it_be(:source) { create(:namespace).becomes(klass) } # rubocop: disable Cop/AvoidBecomes -- easier to reuse existing factory object for a dummy model
  let!(:owner) { create(:member, :owner, source: source).user }
  let!(:guest) { create(:member, :guest, source: source).user }
  let!(:requested) { create(:member, :access_request, source: source).user }
  let!(:invited) { create(:member, :invited, source: source, user: create(:user)).user }

  shared_context 'with parametrized filters table' do
    where(:filters, :selected) do
      nil | [ref(:owner), ref(:guest)]
      { access_level: Gitlab::Access::OWNER } | [ref(:owner)]
      { access_level: Gitlab::Access::GUEST } | [ref(:guest)]
    end
  end

  shared_examples 'extract value from selected members only' do |column|
    it 'extracted value from selected members' do
      expected_values = selected.map { |user| user.public_send(column) }
      expect(values).to contain_exactly(*expected_values)
    end

    it 'skips members with access request' do
      expect(values).not_to include(requested.public_send(column))
    end

    it 'skips invited members' do
      expect(values).not_to include(invited.public_send(column))
    end
  end

  describe '#each_member_user' do
    include_context 'with parametrized filters table'

    with_them do
      subject(:users) do
        users = []
        source.each_member_user(filters) { |user| users << user }
        users
      end

      it 'iterates over selected members' do
        expect(users).to contain_exactly(*selected)
      end

      it 'skips members with access request' do
        expect(users).not_to include(requested)
      end

      it 'skips invited members' do
        expect(users).not_to include(invited)
      end
    end
  end

  describe '#map_member_user' do
    include_context 'with parametrized filters table'

    with_them do
      subject(:values) { source.map_member_user(filters, &:name) }

      it_behaves_like 'extract value from selected members only', :name
    end
  end

  describe '#pluck_member_user' do
    include_context 'with parametrized filters table'

    with_them do
      context 'when single column passed' do
        subject(:values) { source.pluck_member_user(:name, filters: filters) }

        it_behaves_like 'extract value from selected members only', :name
      end

      context 'when multiple column passed' do
        subject(:values) { source.pluck_member_user(:name, :email, filters: filters) }

        it 'extract multiple values from selected members' do
          expected_values = selected.map { |user| [user.name, user.email] }
          expect(values).to contain_exactly(*expected_values)
        end

        it 'skips members with access request' do
          expect(values).not_to include([requested.name, requested.email])
        end

        it 'skips invited members' do
          expect(values).not_to include([invited.name, invited.email])
        end
      end
    end
  end
end
