# frozen_string_literal: true

require 'spec_helper'

RSpec.describe List do
  it_behaves_like 'having unique enum values'
  it_behaves_like 'boards listable model', :list

  describe 'relationships' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:list_type) }
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
