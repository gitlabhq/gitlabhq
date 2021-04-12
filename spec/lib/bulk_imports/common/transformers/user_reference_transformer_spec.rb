# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Transformers::UserReferenceTransformer do
  describe '#transform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:bulk_import) { create(:bulk_import) }
    let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }
    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:hash) do
      {
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

    context 'when there is no data to transform' do
      it 'returns' do
        expect(subject.transform(nil, nil)).to be_nil
      end
    end

    context 'when custom reference is provided' do
      shared_examples 'updates provided reference' do |reference|
        let(:hash) do
          {
            'author' => {
              'public_email' => user.email
            }
          }
        end

        it 'updates provided reference' do
          transformer = described_class.new(reference: reference)
          result = transformer.transform(context, hash)

          expect(result['author']).to be_nil
          expect(result['author_id']).to eq(user.id)
        end
      end

      include_examples 'updates provided reference', 'author'
      include_examples 'updates provided reference', :author
    end
  end
end
