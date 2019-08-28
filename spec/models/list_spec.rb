# frozen_string_literal: true

require 'rails_helper'

describe List do
  it_behaves_like 'having unique enum values'

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

    context 'when list_type is set to closed' do
      subject { described_class.new(list_type: :closed) }

      it { is_expected.not_to validate_presence_of(:label) }
      it { is_expected.not_to validate_presence_of(:position) }
    end
  end

  describe '#destroy' do
    it 'can be destroyed when list_type is set to label' do
      subject = create(:list)

      expect(subject.destroy).to be_truthy
    end

    it 'can not be destroyed when list_type is set to closed' do
      subject = create(:closed_list)

      expect(subject.destroy).to be_falsey
    end
  end

  describe '#destroyable?' do
    it 'returns true when list_type is set to label' do
      subject.list_type = :label

      expect(subject).to be_destroyable
    end

    it 'returns false when list_type is set to closed' do
      subject.list_type = :closed

      expect(subject).not_to be_destroyable
    end
  end

  describe '#movable?' do
    it 'returns true when list_type is set to label' do
      subject.list_type = :label

      expect(subject).to be_movable
    end

    it 'returns false when list_type is set to closed' do
      subject.list_type = :closed

      expect(subject).not_to be_movable
    end
  end

  describe '#title' do
    it 'returns label name when list_type is set to label' do
      subject.list_type = :label
      subject.label = Label.new(name: 'Development')

      expect(subject.title).to eq 'Development'
    end

    it 'returns Closed when list_type is set to closed' do
      subject.list_type = :closed

      expect(subject.title).to eq 'Closed'
    end
  end

  describe '#update_preferences_for' do
    let(:user) { create(:user) }
    let(:list) { create(:list) }

    context 'when user is present' do
      context 'when there are no preferences for user' do
        it 'creates new user preferences' do
          expect { list.update_preferences_for(user, collapsed: true) }.to change { ListUserPreference.count }.by(1)
          expect(list.preferences_for(user).collapsed).to eq(true)
        end
      end

      context 'when there are preferences for user' do
        it 'updates user preferences' do
          list.update_preferences_for(user, collapsed: false)

          expect { list.update_preferences_for(user, collapsed: true) }.not_to change { ListUserPreference.count }
          expect(list.preferences_for(user).collapsed).to eq(true)
        end
      end

      context 'when user is nil' do
        it 'does not create user preferences' do
          expect { list.update_preferences_for(nil, collapsed: true) }.not_to change { ListUserPreference.count }
        end
      end
    end
  end

  describe '#preferences_for' do
    let(:user) { create(:user) }
    let(:list) { create(:list) }

    context 'when user is nil' do
      it 'returns not persisted preferences' do
        preferences = list.preferences_for(nil)

        expect(preferences.persisted?).to eq(false)
        expect(preferences.list_id).to eq(list.id)
        expect(preferences.user_id).to be_nil
      end
    end

    context 'when a user preference already exists' do
      before do
        list.update_preferences_for(user, collapsed: true)
      end

      it 'loads preference for user' do
        preferences = list.preferences_for(user)

        expect(preferences).to be_persisted
        expect(preferences.collapsed).to eq(true)
      end

      context 'when preferences are already loaded for user' do
        it 'gets preloaded user preferences' do
          fetched_list = described_class.where(id: list.id).with_preferences_for(user).first

          expect(fetched_list).to receive(:preloaded_preferences_for).with(user).and_call_original

          preferences = fetched_list.preferences_for(user)

          expect(preferences.collapsed).to eq(true)
        end
      end
    end

    context 'when preferences for user does not exist' do
      it 'returns not persisted preferences' do
        preferences = list.preferences_for(user)

        expect(preferences.persisted?).to eq(false)
        expect(preferences.user_id).to eq(user.id)
        expect(preferences.list_id).to eq(list.id)
      end
    end
  end
end
