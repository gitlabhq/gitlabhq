# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::ActiveRecordSource do
  if testing_rails?
    describe "finding by ID" do
      it_dataloads "loads once, then returns from a cache when available" do |d|
        log = with_active_record_log(colorize: false) do
          r1 = d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load(1)
          assert_equal "Vulfpeck", r1.name
        end

        assert_includes log, 'SELECT "bands".* FROM "bands" WHERE "bands"."id" = ?  [["id", 1]]'

        log = with_active_record_log(colorize: false) do
          r1 = d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load(1)
          assert_equal "Vulfpeck", r1.name
        end

        assert_equal "", log

        log = with_active_record_log(colorize: false) do
          records = d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load_all([1, 99, 2, 3])
          assert_equal ["Vulfpeck", nil, "Tom's Story", "Chon"], records.map { |r| r&.name }
        end

        assert_includes log, '[["id", 99], ["id", 2], ["id", 3]]'
      end

      it_dataloads "casts load values to the column type" do |d|
        log = with_active_record_log(colorize: false) do
          r1 = d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load("1")
          assert_equal "Vulfpeck", r1.name
        end

        assert_includes log, 'SELECT "bands".* FROM "bands" WHERE "bands"."id" = ?  [["id", 1]]'

        log = with_active_record_log(colorize: false) do
          d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load(1)
        end

        assert_equal "", log

        log = with_active_record_log(colorize: false) do
          d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load("1")
        end

        assert_equal "", log
      end
    end

    describe "finding by other columns" do
      it_dataloads "uses the alternative primary key" do |d|
        log = with_active_record_log(colorize: false) do
          r1 = d.with(GraphQL::Dataloader::ActiveRecordSource, AlternativeBand).load("Vulfpeck")
          assert_equal "Vulfpeck", r1.name
          if Rails::VERSION::STRING > "8"
            assert_equal 1, r1["id"]
          else
            assert_equal 1, r1._read_attribute("id")
          end
        end

        assert_includes log, 'SELECT "bands".* FROM "bands" WHERE "bands"."name" = ?  [["name", "Vulfpeck"]]'
      end

      it_dataloads "uses specified find_by columns" do |d|
        log = with_active_record_log(colorize: false) do
          r1 = d.with(GraphQL::Dataloader::ActiveRecordSource, Band, find_by: :name).load("Chon")
          assert_equal "Chon", r1.name
          assert_equal 3, r1.id
        end

        assert_includes log, 'SELECT "bands".* FROM "bands" WHERE "bands"."name" = ?  [["name", "Chon"]]'
      end
    end

    describe "warming the cache" do
      it_dataloads "can receive passed-in objects with a class" do |d|
        d.with(GraphQL::Dataloader::ActiveRecordSource, Band).merge({ 100 => Band.find(3) })
        log = with_active_record_log(colorize: false) do
          band3 = d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load(100)
          assert_equal "Chon", band3.name
          assert_equal 3, band3.id
        end

        assert_equal "", log
      end

      it_dataloads "can infer class of passed-in objects" do |d|
        d.merge_records([Band.find(3), Album.find(4)])
        log = with_active_record_log(colorize: false) do
          band3 = d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load(3)
          assert_equal "Chon", band3.name

          album4 = d.with(GraphQL::Dataloader::ActiveRecordSource, Album).load(4)
          assert_equal "Homey", album4.name
        end
        assert_equal "", log
      end
    end

    describe "in queries" do
      it "loads records with dataload_record"

      it "accepts custom find-by with dataload_record"
    end
  end
end
