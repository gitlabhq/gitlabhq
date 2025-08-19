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
  end

  context 'with loose foreign key on namespace_details.creator_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) do
        namespace = create(:namespace)
        namespace.namespace_details.creator = parent
        namespace.namespace_details.save!
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

  describe '#add_creator' do
    let(:namespace) { create(:namespace) }
    let_it_be(:user) { create(:user) }

    it 'adds the creator' do
      namespace.namespace_details.add_creator(user)

      expect(namespace.namespace_details.creator).to eq(user)
    end
  end
end
