# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sortable do
  describe 'scopes' do
    describe 'secondary ordering by id' do
      let(:sorted_relation) { Group.all.order_created_asc }

      def arel_orders(relation)
        relation.arel.orders
      end

      it 'allows secondary ordering by id ascending' do
        orders = arel_orders(sorted_relation.with_order_id_asc)

        expect(orders.map { |arel| arel.expr.name }).to eq(%w[created_at id])
        expect(orders).to all(be_kind_of(Arel::Nodes::Ascending))
      end

      it 'allows secondary ordering by id descending' do
        orders = arel_orders(sorted_relation.with_order_id_desc)

        expect(orders.map { |arel| arel.expr.name }).to eq(%w[created_at id])
        expect(orders.first).to be_kind_of(Arel::Nodes::Ascending)
        expect(orders.last).to be_kind_of(Arel::Nodes::Descending)
      end
    end
  end

  describe '.order_by' do
    let(:arel_table) { Group.arel_table }
    let(:relation) { Group.all }

    describe 'ordering by id' do
      it 'ascending' do
        expect(relation).to receive(:reorder).with(arel_table['id'].asc)

        relation.order_by('id_asc')
      end

      it 'descending' do
        expect(relation).to receive(:reorder).with(arel_table['id'].desc)

        relation.order_by('id_desc')
      end
    end

    describe 'ordering by created day' do
      it 'ascending' do
        expect(relation).to receive(:reorder).with(arel_table['created_at'].asc)

        relation.order_by('created_asc')
      end

      it 'descending' do
        expect(relation).to receive(:reorder).with(arel_table['created_at'].desc)

        relation.order_by('created_desc')
      end

      it 'order by "date"' do
        expect(relation).to receive(:reorder).with(arel_table['created_at'].desc)

        relation.order_by('created_date')
      end
    end

    describe 'ordering by name' do
      it 'ascending' do
        expect(relation).to receive(:reorder).once.and_call_original

        table = Regexp.escape(ApplicationRecord.connection.quote_table_name(:namespaces))
        column = Regexp.escape(ApplicationRecord.connection.quote_column_name(:name))

        sql = relation.order_by('name_asc').to_sql

        expect(sql).to match(/.+ORDER BY LOWER\(#{table}.#{column}\) ASC\z/)
      end

      it 'descending' do
        expect(relation).to receive(:reorder).once.and_call_original

        table = Regexp.escape(ApplicationRecord.connection.quote_table_name(:namespaces))
        column = Regexp.escape(ApplicationRecord.connection.quote_column_name(:name))

        sql = relation.order_by('name_desc').to_sql

        expect(sql).to match(/.+ORDER BY LOWER\(#{table}.#{column}\) DESC\z/)
      end
    end

    describe 'ordering by Updated Time' do
      it 'ascending' do
        expect(relation).to receive(:reorder).with(arel_table['updated_at'].asc)

        relation.order_by('updated_asc')
      end

      it 'descending' do
        expect(relation).to receive(:reorder).with(arel_table['updated_at'].desc)

        relation.order_by('updated_desc')
      end
    end

    it 'does not call reorder in case of unrecognized ordering' do
      expect(relation).not_to receive(:reorder)

      relation.order_by('random_ordering')
    end
  end

  describe 'sorting groups' do
    def ordered_group_names(order)
      Group.all.order_by(order).map(&:name)
    end

    let!(:ref_time) { Time.zone.parse('2018-05-01 00:00:00') }
    let!(:group1) { create(:group, name: 'aa', id: 1, created_at: ref_time - 15.seconds, updated_at: ref_time) }
    let!(:group2) { create(:group, name: 'AAA', id: 2, created_at: ref_time - 10.seconds, updated_at: ref_time - 5.seconds) }
    let!(:group3) { create(:group, name: 'BB', id: 3, created_at: ref_time - 5.seconds, updated_at: ref_time - 10.seconds) }
    let!(:group4) { create(:group, name: 'bbb', id: 4, created_at: ref_time, updated_at: ref_time - 15.seconds) }

    it 'sorts groups by id' do
      expect(ordered_group_names('id_asc')).to eq(%w[aa AAA BB bbb])
      expect(ordered_group_names('id_desc')).to eq(%w[bbb BB AAA aa])
    end

    it 'sorts groups by name via case-insensitive comparision' do
      expect(ordered_group_names('name_asc')).to eq(%w[aa AAA BB bbb])
      expect(ordered_group_names('name_desc')).to eq(%w[bbb BB AAA aa])
    end

    it 'sorts groups by created_at' do
      expect(ordered_group_names('created_asc')).to eq(%w[aa AAA BB bbb])
      expect(ordered_group_names('created_desc')).to eq(%w[bbb BB AAA aa])
      expect(ordered_group_names('created_date')).to eq(%w[bbb BB AAA aa])
    end

    it 'sorts groups by updated_at' do
      expect(ordered_group_names('updated_asc')).to eq(%w[bbb BB AAA aa])
      expect(ordered_group_names('updated_desc')).to eq(%w[aa AAA BB bbb])
    end
  end
end
