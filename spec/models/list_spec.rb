require 'rails_helper'

describe List do
  describe 'relationships' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:list_type) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }

    it 'does not require label to be set when list_type is set to backlog' do
      subject.list_type = :backlog

      expect(subject).not_to validate_presence_of(:label)
    end

    it 'does not require label to be set when list_type is set to done' do
      subject.list_type = :done

      expect(subject).not_to validate_presence_of(:label)
    end
  end
end
