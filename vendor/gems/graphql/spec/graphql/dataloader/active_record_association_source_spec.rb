# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::ActiveRecordAssociationSource do
  if testing_rails?
    it_dataloads "queries for associated records when the association isn't already loaded" do |d|
      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      log = with_active_record_log(colorize: false) do
        vulfpeck, chon = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey])
        assert_equal "Vulfpeck", vulfpeck.name
        assert_equal "Chon", chon.name
      end

      assert_includes log, '[["id", 1], ["id", 3]]'

      toms_story = ::Album.find(3)
      log = with_active_record_log(colorize: false) do
        vulfpeck, chon, toms_story_band = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey, toms_story])
        assert_equal "Vulfpeck", vulfpeck.name
        assert_equal "Chon", chon.name
        assert_equal "Tom's Story", toms_story_band.name
      end

      assert_includes log, '[["id", 2]]'
    end

    it_dataloads "doesn't load records that are already cached by ActiveRecordSource" do |d|
      d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load_all([1,2,3])

      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      toms_story = ::Album.find(3)

      log = with_active_record_log(colorize: false) do
        vulfpeck, chon, toms_story_band = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey, toms_story])
        assert_equal "Vulfpeck", vulfpeck.name
        assert_equal "Chon", chon.name
        assert_equal "Tom's Story", toms_story_band.name
      end

      assert_equal "", log
    end

    it_dataloads "warms the cache for ActiveRecordSource" do |d|
      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      toms_story = ::Album.find(3)
      d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey, toms_story])

      log = with_active_record_log(colorize: false) do
        d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load_all([1,2,3])
      end

      assert_equal "", log
    end

    it_dataloads "doesn't warm the cache when a scope is given" do |d|
      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      summerteeth = ::Album.find(6)
      results = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band, ::Band.country).load_all([my_first_car, homey, summerteeth])
      assert_equal [nil, nil, ::Band.find(4)], results

      log = with_active_record_log(colorize: false) do
        d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load_all([1,2,4])
      end

      assert_includes log, "SELECT \"bands\".* FROM \"bands\" WHERE \"bands\".\"id\" IN (?, ?, ?)  [[\"id\", 1], [\"id\", 2], [\"id\", 4]]"
    end

    it_dataloads "doesn't pause when the association is already loaded" do |d|
      source = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band)
      assert_equal 0, source.results.size
      assert_equal 0, source.pending.size

      my_first_car = ::Album.find(2)
      vulfpeck = my_first_car.band

      vulfpeck2 = source.load(my_first_car)

      assert_equal vulfpeck, vulfpeck2

      assert_equal 0, source.results.size
      assert_equal 0, source.pending.size

      my_first_car.reload
      vulfpeck3 = source.load(my_first_car)
      assert_equal vulfpeck, vulfpeck3

      assert_equal 1, source.results.size
      assert_equal 0, source.pending.size
    end

    it_dataloads "raises an error with a non-existent association" do |d|
      my_first_car = ::Album.find(2)
      source = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :tour_bus)
      assert_raises ActiveRecord::AssociationNotFoundError do
        source.load(my_first_car)
      end
    end

    it_dataloads "works with polymorphic associations" do |d|
      wilco = ::Band.find(4)
      vulfpeck = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :thing).load(wilco)
      assert_equal ::Band.find(1), vulfpeck
    end
  end
end
