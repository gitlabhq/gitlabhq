# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::KeepAsPlaceholderService, feature_category: :importers do
  let(:import_source_user) { create(:import_source_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:service) { described_class.new(import_source_user, current_user: current_user) }
  let(:result) { service.execute }

  describe '#execute' do
    before do
      import_source_user.namespace.add_owner(user)
    end

    context 'when reassignment is successful' do
      it 'returns success' do
        expect { result }
          .to trigger_internal_events('keep_as_placeholder_user')
          .with(
            user: current_user,
            namespace: import_source_user.namespace,
            additional_properties: {
              label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
              property: nil,
              import_type: import_source_user.import_type
            }
          )

        expect(result).to be_success
        expect(result.payload.reload).to eq(import_source_user)
        expect(result.payload.reassign_to_user).to eq(nil)
        expect(result.payload.reassigned_by_user).to eq(current_user)
        expect(result.payload.keep_as_placeholder?).to eq(true)
      end
    end

    context 'when current user does not have permission' do
      let(:current_user) { create(:user) }

      it 'returns error no permissions' do
        expect(result).to be_error
        expect(result.message).to eq('You have insufficient permissions to update the import source user')
      end
    end

    context 'when import source user does not have an reassignable status' do
      before do
        allow(current_user).to receive(:can?).with(:admin_import_source_user, import_source_user).and_return(true)
        allow(import_source_user).to receive(:reassignable_status?).and_return(false)
      end

      it 'returns error invalid status' do
        expect(result).to be_error
        expect(result.message).to eq('Import source user has an invalid status for this operation')
      end
    end

    context 'when an error occurs' do
      before do
        allow(import_source_user).to receive(:keep_as_placeholder).and_return(false)
        allow(import_source_user).to receive(:errors).and_return(instance_double(ActiveModel::Errors,
          full_messages: ['Error']))
      end

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to eq(['Error'])
      end
    end
  end
end
