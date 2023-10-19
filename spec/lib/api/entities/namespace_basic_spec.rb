# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::NamespaceBasic, feature_category: :groups_and_projects do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }

  let(:options) { { current_user: current_user } }

  let(:entity) do
    described_class.new(namespace, options)
  end

  subject(:json) { entity.as_json }

  shared_examples 'returns a response' do
    it 'returns required fields' do
      expect(json[:id]).to be_present
      expect(json[:name]).to be_present
      expect(json[:path]).to be_present
      expect(json[:kind]).to be_present
      expect(json[:full_path]).to be_present
      expect(json[:web_url]).to be_present
    end
  end

  include_examples 'returns a response'

  context 'for a user namespace' do
    let_it_be(:namespace) { create(:user_namespace) }

    include_examples 'returns a response'

    context 'when user namespece owner is missing' do
      before do
        namespace.update_column(:owner_id, non_existing_record_id)
      end

      include_examples 'returns a response'

      it 'returns correct web_url' do
        expect(json[:web_url]).to include(namespace.path)
      end
    end
  end
end
