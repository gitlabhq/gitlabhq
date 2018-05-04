require 'spec_helper'

class TestClass
  ColumnMock = Struct.new("ColumnMock", :type)
  include RedisCacheable

  cached_attr_reader :some_string, :some_time

  def read_attribute(attribute)
  end

  def id
    123
  end

  def self.columns_hash
    {
      "some_string" => ColumnMock.new(:string),
      "some_time" => ColumnMock.new(:datetime)
    }
  end
end

describe RedisCacheable do
  let(:model) { TestClass.new }

  describe 'getter method' do
    let(:payload) { { some_string: 'string value', some_time: '2018-05-04T07:29:50.548+02:00' } }

    before do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:get).with('cache:TestClass:123:attributes')
          .and_return(payload.to_json)
      end
    end

    context 'when value is cached' do
      it 'returns the string value' do
        expect(model.some_string).to eq('string value')
      end

      context 'with a datetime type value' do
        it 'converts the value into ActiveSupport::TimeWithZone' do
          expect(model.some_time).to be_kind_of(ActiveSupport::TimeWithZone)
          expect(model.some_time).to eq(Time.zone.parse('2018-05-04T07:29:50.548+02:00'))
        end

        context 'when value is nil' do
          let(:payload) { { some_time: nil } }

          it 'returns nil' do
            expect(model.some_time).to be_nil
          end
        end
      end
    end
  end

  describe '#cached_attribute' do
    let(:payload) { { attribute: 'value' } }

    subject { model.cached_attribute(payload.keys.first) }

    it 'gets the cache attribute' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:get).with('cache:TestClass:123:attributes')
          .and_return(payload.to_json)
      end

      expect(subject).to eq(payload.values.first)
    end
  end

  describe '#cache_attributes' do
    let(:values) { { name: 'new_name' } }

    subject { model.cache_attributes(values) }

    it 'sets the cache attributes' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:set).with('cache:TestClass:123:attributes', values.to_json, anything)
      end

      subject
    end
  end
end
