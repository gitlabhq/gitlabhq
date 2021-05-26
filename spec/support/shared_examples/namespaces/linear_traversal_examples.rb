# frozen_string_literal: true

# Traversal examples common to linear and recursive methods are in
# spec/support/shared_examples/namespaces/traversal_examples.rb

RSpec.shared_examples 'linear namespace traversal' do
  context 'when use_traversal_ids feature flag is enabled' do
    before do
      stub_feature_flags(use_traversal_ids: true)
    end

    context 'scopes' do
      describe '.as_ids' do
        let_it_be(:namespace1) { create(:group) }
        let_it_be(:namespace2) { create(:group) }

        subject { Namespace.where(id: [namespace1, namespace2]).as_ids.pluck(:id) }

        it { is_expected.to contain_exactly(namespace1.id, namespace2.id) }
      end
    end
  end
end
