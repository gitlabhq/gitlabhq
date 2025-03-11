# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Schema::Member::HasDataloader do
    class DataloaderExample
      include GraphQL::Schema::Member::HasDataloader
      def initialize(dataloader, object = nil)
        @context = OpenStruct.new(dataloader: dataloader)
        @object = object
      end

      attr_reader :context, :object
    end

    class PlusSource < GraphQL::Dataloader::Source
      def fetch(keys)
        res = keys.reduce(&:+)
        keys.map { |k| res }
      end
    end

    it_dataloads "loads records with dataload_record" do |d|
      example = DataloaderExample.new(d)
      assert_equal "Homey", example.dataload_record(Album, 4).name
      assert_equal 4, example.dataload_record(Album, "Homey", find_by: :name).id
    end

    it_dataloads "loads association with dataload_association" do |d|
      album1 = Album.find(1)
      example = DataloaderExample.new(d, album1)
      assert_equal "Vulfpeck", example.dataload_association(:band).name, "Defaults to record = object"

      album = Album.find(4)
      assert_equal "Chon", example.dataload_association(album, :band).name
      album.reload
      assert_nil example.dataload_association(album, :band, scope: Band.country)
    end

    it_dataloads "calls any source with dataload..." do |d|
      example = DataloaderExample.new(d)
      d.with(PlusSource).request(2)
      d.with(PlusSource).request(3)
      assert_equal 9, example.dataload(PlusSource, 4)
      assert_equal 5, example.dataload(PlusSource, 5)
    end
  end
end
