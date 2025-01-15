# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::UpdateService, feature_category: :importers do
  let_it_be_with_reload(:placeholder_user) { create(:user, :placeholder, name: 'Placeholder', username: 'placeholder') }
  let_it_be(:import_user) { create(:user, :import_user) }
  let(:new_source_name) { 'John Doe' }
  let(:new_source_username) { 'johndoe' }
  let(:params) { { source_name: new_source_name, source_username: new_source_username } }
  let_it_be_with_reload(:import_source_user) do
    create(:import_source_user, placeholder_user: placeholder_user, source_name: nil, source_username: nil)
  end

  subject(:service) { described_class.new(import_source_user, params) }

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::Import::PlaceholderUserCreator) do |service|
        allow(service).to receive(:random_segment).and_return('random')
      end
    end

    it 'updates both placeholder user and source user' do
      result = service.execute

      expect(import_source_user.reload.source_name).to eq(new_source_name)
      expect(import_source_user.reload.source_username).to eq(new_source_username)

      expect(placeholder_user.reload.name).to eq('Placeholder John Doe')
      expect(placeholder_user.reload.username).to eq('johndoe_placeholder_random')

      expect(result).to be_success
    end

    it 'generates unique usernames' do
      create(:user, username: 'johndoe_placeholder_random')

      result = service.execute

      expect(placeholder_user.reload.username).to eq('johndoe_placeholder_random1')
      expect(import_source_user.reload.source_username).to eq(new_source_username)
      expect(result).to be_success
    end

    context 'when placeholder user fails to be updated' do
      before do
        import_source_user.placeholder_user.email = nil
      end

      it 'does not update source_user' do
        service.execute

        import_source_user.reload

        expect(import_source_user.source_name).to eq(nil)
        expect(import_source_user.reload.source_username).to eq(nil)
      end

      it 'converts Users::UpdateService hash error to ServiceResponse' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq("Email can't be blank")
      end
    end

    context 'when source user fails to be updated' do
      before do
        import_source_user.source_user_identifier = nil
      end

      it 'returns error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq("Source user identifier can't be blank")
      end
    end

    context 'when source name is nil' do
      let(:new_source_name) { nil }

      it 'does not update placeholder user name' do
        expect { service.execute }.not_to change { placeholder_user.reload.name }
      end

      it 'does not update source_user source name' do
        expect { service.execute }.not_to change { import_source_user.reload.source_name }
      end

      it 'returns success' do
        expect(service.execute).to be_success
      end
    end

    context 'when source username is nil' do
      let(:new_source_username) { nil }

      it 'does not update placeholder username' do
        expect { service.execute }.not_to change { placeholder_user.reload.username }
      end

      it 'does not update source_user source username' do
        expect { service.execute }.not_to change { import_source_user.reload.source_username }
      end

      it 'returns success' do
        expect(service.execute).to be_success
      end
    end

    context 'when placeholder user is nil' do
      let(:import_source_user) do
        create(:import_source_user, :completed, placeholder_user: nil, source_name: nil, source_username: nil)
      end

      it 'does not update placeholder user and still update the source user' do
        expect(Users::UpdateService).not_to receive(:new)

        result = service.execute

        expect(import_source_user.reload.source_name).to eq(new_source_name)
        expect(import_source_user.reload.source_username).to eq(new_source_username)
        expect(result).to be_success
      end
    end

    context 'when placeholder user is an ImportUser' do
      before do
        import_source_user.placeholder_user = import_user
      end

      it 'does not update placeholder user and still update the source user' do
        expect(Users::UpdateService).not_to receive(:new)

        result = service.execute

        expect(import_source_user.reload.source_name).to eq(new_source_name)
        expect(import_source_user.reload.source_username).to eq(new_source_username)
        expect(result).to be_success
      end
    end

    context 'when source user already has a source name set' do
      before do
        import_source_user.update!(source_name: 'Existing source name')
      end

      it 'does not update the source name' do
        service.execute

        expect(import_source_user.reload.source_name).to eq('Existing source name')
      end
    end

    context 'when source user already has a source username set' do
      before do
        import_source_user.update!(source_username: 'existing_source_username')
      end

      it 'does not update the source username' do
        service.execute

        expect(import_source_user.reload.source_username).to eq('existing_source_username')
      end
    end
  end
end
