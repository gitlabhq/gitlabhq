# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Concerns::PositionableList do
  subject do
    Class.new do
      include Sidebars::Concerns::PositionableList
    end.new
  end

  describe '#add_element' do
    it 'adds the element to the last position of the list' do
      list = [1, 2]

      subject.add_element(list, 3)

      expect(list).to eq([1, 2, 3])
    end
  end

  describe '#insert_element_before' do
    let(:user) { build(:user) }
    let(:list) { [1, user] }

    it 'adds element before the specific element class' do
      subject.insert_element_before(list, User, 2)

      expect(list).to eq [1, 2, user]
    end

    context 'when reference element does not exist' do
      it 'adds the element to the top of the list' do
        subject.insert_element_before(list, Project, 2)

        expect(list).to eq [2, 1, user]
      end
    end
  end

  describe '#insert_element_after' do
    let(:user) { build(:user) }
    let(:list) { [1, user] }

    it 'adds element after the specific element class' do
      subject.insert_element_after(list, Integer, 2)

      expect(list).to eq [1, 2, user]
    end

    context 'when reference element does not exist' do
      it 'adds the element to the end of the list' do
        subject.insert_element_after(list, Project, 2)

        expect(list).to eq [1, user, 2]
      end
    end
  end
end
