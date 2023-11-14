# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UnnestedInFilters::Rewriter do
  let(:rewriter) { described_class.new(relation) }

  before_all do
    User.include(UnnestedInFilters::Dsl)
  end

  describe '#rewrite?' do
    subject(:rewrite?) { rewriter.rewrite? }

    context 'when a join table is receiving an IN list query' do
      let(:relation) { User.joins(:status).where(status: { message: %w[foo bar] }).order(id: :desc).limit(2) }

      it { is_expected.to be_falsey }
    end

    context 'when the given relation does not have an `IN` predicate' do
      let(:relation) { User.where(username: 'user') }

      it { is_expected.to be_falsey }
    end

    context 'when the given relation has an `IN` predicate' do
      context 'when there is no index coverage for the used columns' do
        let(:relation) { User.where(username: %w[user_1 user_2], state: :active) }

        it { is_expected.to be_falsey }
      end

      context 'when there is an index coverage for the used columns' do
        let(:relation) { User.where(state: :active, user_type: [:support_bot, :alert_bot]) }

        it { is_expected.to be_truthy }

        context 'when there is an ordering' do
          let(:relation) { User.where(state: %w[active blocked banned]).order(order).limit(2) }

          context 'when the order is an Arel node' do
            let(:order) { { user_type: :desc } }

            it { is_expected.to be_truthy }
          end

          context 'when the order is a Keyset order' do
            let(:order) do
              Gitlab::Pagination::Keyset::Order.build(
                [
                  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                    attribute_name: 'user_type',
                    order_expression: User.arel_table['user_type'].desc,
                    nullable: :not_nullable,
                    distinct: false
                  )
                ])
            end

            it { is_expected.to be_truthy }
          end
        end
      end
    end
  end

  describe '#rewrite' do
    let(:recorded_queries) { ActiveRecord::QueryRecorder.new { rewriter.rewrite.load } }
    let(:relation) { User.where(state: :active, user_type: %i[support_bot alert_bot]).limit(2) }
    let(:users_select) { 'SELECT "users".*' }
    let(:users_select_with_ignored_columns) { 'SELECT ("users"."\w+", )+("users"."\w+")' }

    let(:users_unnest) do
      'FROM unnest\(\'{1\,2}\'::smallint\[\]\) AS "user_types"\("user_type"\)\, LATERAL \('
    end

    let(:users_where) do
      'FROM
        "users"
      WHERE
        "users"."state" = \'active\' AND
        \(users."user_type" = "user_types"."user_type"\)
      LIMIT 2\)
        AS users
      LIMIT 2'
    end

    let(:expected_query_regexp) do
      Regexp.new(
        "(#{users_select}|#{users_select_with_ignored_columns})
        #{users_unnest}(#{users_select}|#{users_select_with_ignored_columns})
        #{users_where}".squish
      )
    end

    subject(:issued_query) { recorded_queries.occurrences.each_key.first }

    it 'changes the query' do
      expect(issued_query).to match(expected_query_regexp)
    end

    context 'when the relation has a subquery' do
      let(:relation) { User.where(state: User.select(:state), user_type: %i[support_bot alert_bot]).limit(1) }

      let(:users_unnest) do
        'FROM
          unnest\(ARRAY\(SELECT "users"."state" FROM "users"\)::character varying\[\]\) AS "states"\("state"\)\,
          unnest\(\'{1\,2}\'::smallint\[\]\) AS "user_types"\("user_type"\)\,
          LATERAL \('
      end

      let(:users_where) do
        'FROM
          "users"
        WHERE
          \(users."state" = "states"."state"\) AND
          \(users."user_type" = "user_types"."user_type"\)
        LIMIT 1\)
          AS users
        LIMIT 1'
      end

      it 'changes the query' do
        expect(issued_query).to match(expected_query_regexp)
      end
    end

    context 'when there is an order' do
      let(:relation) { User.where(state: %w[active blocked banned]).order(order).limit(2) }

      let(:users_unnest) do
        'FROM
          unnest\(\'{active\,blocked\,banned}\'::character varying\[\]\) AS "states"\("state"\)\,
          LATERAL \('
      end

      let(:users_where) do
        'FROM
          "users"
        WHERE
          \(users."state" = "states"."state"\)
        ORDER BY
          "users"."user_type" DESC
        LIMIT 2\)
          AS users
        ORDER BY
          "users"."user_type" DESC
        LIMIT 2'
      end

      context 'when the order is an Arel node' do
        let(:order) { { user_type: :desc } }

        it 'changes the query' do
          expect(issued_query).to match(expected_query_regexp)
        end
      end

      context 'when the order is a Keyset order' do
        let(:order) do
          Gitlab::Pagination::Keyset::Order.build(
            [
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: 'user_type',
                order_expression: User.arel_table['user_type'].desc,
                nullable: :not_nullable,
                distinct: false
              )
            ])
        end

        it 'changes the query' do
          expect(issued_query).to match(expected_query_regexp)
        end
      end
    end

    context 'when the combined attributes include the primary key' do
      let(:relation) { User.where(user_type: %i[support_bot alert_bot]).order(id: :desc).limit(2) }

      let(:users_where) do
        'FROM
          "users"
        WHERE
          "users"."id" IN
            \(SELECT
              "users"."id"
            FROM
              unnest\(\'{1\,2}\'::smallint\[\]\) AS "user_types"\("user_type"\)\,
              LATERAL
                \(SELECT
                  "users"."user_type"\,
                  "users"."id"
                FROM
                  "users"
                WHERE
                  \(users."user_type" = "user_types"."user_type"\)
                ORDER BY
                  "users"."id" DESC
                LIMIT 2\)
              AS users
            ORDER BY
              "users"."id" DESC
            LIMIT 2\)
        ORDER BY
          "users"."id" DESC
        LIMIT 2'
      end

      let(:expected_query_regexp) do
        Regexp.new("(#{users_select}|#{users_select_with_ignored_columns}) #{users_where}".squish)
      end

      it 'changes the query' do
        expect(issued_query).to match(expected_query_regexp)
      end
    end

    context 'when a join table is receiving an IN list query' do
      let(:relation) { User.joins(:status).where(status: { message: %w[foo bar] }).order(id: :desc).limit(2) }

      let(:users_where) do
        'FROM
          "users"
        WHERE
          "users"."id" IN
            \(SELECT
              "users"."id"
            FROM
              LATERAL
                \(SELECT
                  message,
                  "users"."id"
                FROM
                  "users"
                  INNER JOIN "user_statuses" "status" ON "status"."user_id" = "users"."id"
                WHERE
                  "status"."message" IN \(\'foo\'\, \'bar\'\)
                ORDER BY
                  "users"."id" DESC
                LIMIT 2\)
              AS users
            ORDER BY
              "users"."id" DESC
            LIMIT 2\)
        ORDER BY
          "users"."id" DESC
        LIMIT 2'
      end

      let(:expected_query_regexp) do
        Regexp.new("(#{users_select}|#{users_select_with_ignored_columns}) #{users_where}".squish)
      end

      it 'does not rewrite the in statement for the joined table' do
        expect(issued_query).to match(expected_query_regexp)
      end
    end

    describe 'logging' do
      subject(:load_reload) { rewriter.rewrite }

      before do
        allow(::Gitlab::AppLogger).to receive(:info)
      end

      it 'logs the call' do
        load_reload

        expect(::Gitlab::AppLogger)
          .to have_received(:info).with(message: 'Query is being rewritten by `UnnestedInFilters`', model: 'User')
      end
    end
  end
end
