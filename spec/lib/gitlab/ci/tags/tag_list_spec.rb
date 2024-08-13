# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Tags::TagList, feature_category: :continuous_integration do
  let(:tag_list) { described_class.new('chunky', 'bacon') }
  let(:another_tag_list) { described_class.new('chunky', 'crazy', 'cut') }

  it { is_expected.to be_a_kind_of(Array) }

  describe '#add' do
    it 'adds a new word' do
      tag_list.add('cool')

      expect(tag_list).to include('cool')
    end

    it 'adds delimited lists of words' do
      tag_list.add('cool, fox', parse: true)

      expect(tag_list).to include('cool', 'fox')
    end

    it 'adds delimited list of words with quoted delimiters' do
      tag_list.add("'cool, wicked', \"really cool, really wicked\"", parse: true)

      expect(tag_list).to include('cool, wicked', 'really cool, really wicked')
    end

    it 'handles other uses of quotation marks correctly' do
      tag_list.add("john's cool car, mary's wicked toy", parse: true)

      expect(tag_list).to include("john's cool car", "mary's wicked toy")
    end

    it 'is able to add an array of words' do
      tag_list.add(%w[cool fox], parse: true)

      expect(tag_list).to include('cool', 'fox')
    end

    it 'escapes tags with commas in them' do
      tag_list.add('cool', 'rad,fox')

      expect(tag_list.to_s).to eq("chunky, bacon, cool, \"rad,fox\"")
    end
  end

  describe '#remove' do
    it 'removes words' do
      tag_list.remove('chunky')

      expect(tag_list).not_to include('chunky')
    end

    it 'removes delimited lists of words' do
      tag_list.remove('chunky, bacon', parse: true)

      expect(tag_list).to be_empty
    end

    it 'removes an array of words' do
      tag_list.remove(%w[chunky bacon], parse: true)

      expect(tag_list).to be_empty
    end
  end

  describe '#+' do
    it 'does not have duplicate tags' do
      new_tag_list = tag_list + another_tag_list

      expect(new_tag_list).to eq(%w[chunky bacon crazy cut])
    end

    it 'returns an instance of the same class' do
      new_tag_list = tag_list + another_tag_list

      expect(new_tag_list).to be_an_instance_of(described_class)
    end
  end

  describe '#concat' do
    it 'does not have duplicate tags' do
      expect(tag_list.concat(another_tag_list)).to eq(%w[chunky bacon crazy cut])
    end

    it 'returns an instance of the same class' do
      new_tag_list = tag_list.concat(another_tag_list)

      expect(new_tag_list).to be_an_instance_of(described_class)
    end

    context 'without duplicates' do
      let(:arr) { %w[crazy cut] }
      let(:another_tag_list) { described_class.new(*arr) }

      it { expect(tag_list.concat(another_tag_list)).to eq(%w[chunky bacon crazy cut]) }
      it { expect(tag_list.concat(arr)).to eq(%w[chunky bacon crazy cut]) }
    end
  end

  describe '#to_s' do
    it 'gives a delimited list of words when converted to string' do
      expect(tag_list.to_s).to eq('chunky, bacon')
    end
  end

  describe 'cleaning' do
    it 'removes duplicates and empty spaces' do
      tag_list = described_class.new('Ruby On Rails', ' Ruby on Rails ', 'Ruby on Rails', ' ', '')

      expect(tag_list.to_s).to eq('Ruby On Rails, Ruby on Rails')
    end
  end
end
