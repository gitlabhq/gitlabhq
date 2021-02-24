# frozen_string_literal: true

RSpec.shared_examples 'list_preferences_for user' do |list_factory, list_id_attribute|
  subject { create(list_factory) } # rubocop:disable Rails/SaveBang

  let_it_be(:user) { create(:user) }

  describe '#preferences_for' do
    context 'when user is nil' do
      it 'returns not persisted preferences' do
        preferences = subject.preferences_for(nil)

        expect(preferences).not_to be_persisted
        expect(preferences[list_id_attribute]).to eq(subject.id)
        expect(preferences.user_id).to be_nil
      end
    end

    context 'when a user preference already exists' do
      before do
        subject.update_preferences_for(user, collapsed: true)
      end

      it 'loads preference for user' do
        preferences = subject.preferences_for(user)

        expect(preferences).to be_persisted
        expect(preferences.collapsed).to eq(true)
      end
    end

    context 'when preferences for user does not exist' do
      it 'returns not persisted preferences' do
        preferences = subject.preferences_for(user)

        expect(preferences).not_to be_persisted
        expect(preferences.user_id).to eq(user.id)
        expect(preferences.public_send(list_id_attribute)).to eq(subject.id)
      end
    end
  end

  describe '#update_preferences_for' do
    context 'when user is present' do
      context 'when there are no preferences for user' do
        it 'creates new user preferences' do
          expect { subject.update_preferences_for(user, collapsed: true) }.to change { subject.preferences.count }.by(1)
          expect(subject.preferences_for(user).collapsed).to eq(true)
        end
      end

      context 'when there are preferences for user' do
        it 'updates user preferences' do
          subject.update_preferences_for(user, collapsed: false)

          expect { subject.update_preferences_for(user, collapsed: true) }.not_to change { subject.preferences.count }
          expect(subject.preferences_for(user).collapsed).to eq(true)
        end
      end

      context 'when user is nil' do
        it 'does not create user preferences' do
          expect { subject.update_preferences_for(nil, collapsed: true) }.not_to change { subject.preferences.count }
        end
      end
    end
  end
end
