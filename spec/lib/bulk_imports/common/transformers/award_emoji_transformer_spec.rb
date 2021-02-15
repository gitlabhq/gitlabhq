# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Transformers::AwardEmojiTransformer do
  describe '#transform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:bulk_import) { create(:bulk_import) }
    let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(entity) }

    let(:hash) do
      {
        'name' => 'thumbs up',
        'user' => {
          'public_email' => email
        }
      }
    end

    before do
      group.add_developer(user)
    end

    shared_examples 'sets user_id and removes user key' do
      it 'sets found user_id and removes user key' do
        transformed_hash = subject.transform(context, hash)

        expect(transformed_hash['user']).to be_nil
        expect(transformed_hash['user_id']).to eq(user.id)
      end
    end

    context 'when user can be found by email' do
      let(:email) { user.email }

      include_examples 'sets user_id and removes user key'
    end

    context 'when user cannot be found by email' do
      let(:user) { bulk_import.user }
      let(:email) { nil }

      include_examples 'sets user_id and removes user key'
    end
  end
end
