require 'spec_helper'

describe Sortable do

  class SortableModel
    def self.default_scope; end
    def self.scope(name, block)
      define_singleton_method(name, &block)
    end
    def self.all
      RECORDS
    end

    include Sortable

    sortable_by 'stars', :sort_by_stars

    RECORDS = [
      OpenStruct.new(title: 'Awesome', id: 1, stars: 1),
      OpenStruct.new(title: 'Amazing', id: 2, stars: 2),
      OpenStruct.new(title: 'Incredible', id: 3, stars: 0),
    ]

    scope :sort_by_stars, ->{ RECORDS.sort_by(&:stars).reverse }
  end

  describe :order_by do
    %w[id created_at updated_at].each do |attr|
      %i[asc desc].each do |way|
        it "can be sorted #{attr.sub('_at', '')}_#{way}" do
          expect(SortableModel).to receive(:reorder).with(attr.to_sym => way)

          SortableModel.order_by("#{attr.sub('_at', '')}_#{way}")
        end
      end
    end

    it 'returns .all when sort method is unknown' do
      expect(SortableModel.order_by('foo')).to eq SortableModel::RECORDS
    end

    it 'does not crash on nil' do
      expect(SortableModel.order_by(nil)).to eq SortableModel::RECORDS
    end
  end

  describe :sortable_by do
    it 'allows to define sorting methods' do
      expected = SortableModel.sort_by_stars

      expect(SortableModel.order_by('stars')).to eq expected
    end
  end
end
