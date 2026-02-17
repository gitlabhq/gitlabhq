# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::Detail, type: :model, feature_category: :groups_and_projects do
  describe 'associations' do
    it { is_expected.to belong_to :namespace }
    it { is_expected.to belong_to(:creator).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }

    describe 'state_metadata' do
      let(:namespace_detail) { create(:namespace).namespace_details }

      it 'validates json_schema when state_metadata changes' do
        namespace_detail.state_metadata = { invalid_key: 'value' }

        expect(namespace_detail).not_to be_valid
        expect(namespace_detail.errors[:state_metadata]).to be_present
      end

      it 'does not validate json_schema when state_metadata is unchanged' do
        # Simulate invalid data already in the database
        namespace_detail.update_column(:state_metadata, { invalid_key: 'value' })
        namespace_detail.reload

        # Update a different attribute
        namespace_detail.description = 'New description'

        expect(namespace_detail).to be_valid
      end
    end
  end

  context 'with loose foreign key on namespace_details.creator_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) do
        namespace = create(:namespace, creator: parent)
        namespace.namespace_details
      end
    end
  end

  describe '#description_html' do
    let_it_be(:namespace_details) { create(:namespace, description: '### Foo **Bar**').namespace_details }
    let(:expected_description) { ' Foo <strong>Bar</strong> ' }

    subject { namespace_details.description_html }

    it { is_expected.to eq_no_sourcepos(expected_description) }
  end
end
