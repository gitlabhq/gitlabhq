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

    RECORDS = [
      OpenStruct.new(title: 'Awesome', id: 1, stars: 1),
      OpenStruct.new(title: 'Amazing', id: 2, stars: 2),
      OpenStruct.new(title: 'Incredible', id: 3, stars: 0),
    ]

    scope :order_stars, ->{ RECORDS.sort_by(&:stars).reverse }
  end

  describe :order_by do
    %w[id created_at updated_at].each do |attr|
      %i[asc desc].each do |way|
        it "can be sorted #{attr.sub('_at', '')}_#{way}" do
          clean_attribute = attr.sub('_at', '')
          expect(SortableModel).to receive("order_#{clean_attribute}_#{way}")

          SortableModel.order_by("#{clean_attribute}_#{way}")
        end
      end
    end

    it 'returns .all when sort method is unknown' do
      expect(SortableModel.order_by('foo')).to eq SortableModel::RECORDS
    end

    it 'does not crash on nil' do
      expect(SortableModel.order_by(nil)).to eq SortableModel::RECORDS
    end

    describe 'custom sort methods' do
      it 'allows to define custom sorting methods' do
        expected = SortableModel.order_stars

        expect(SortableModel.order_by('stars')).to eq expected
      end
    end
  end
end
