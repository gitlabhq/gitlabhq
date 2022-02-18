# frozen_string_literal: true

require 'spec_helper'

# Main user namespace functionality it still in `Namespace`, so most
# of the specs are in `namespace_spec.rb`.
# UserNamespace specific specs will end up being migrated here.
RSpec.describe Namespaces::UserNamespace, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:owner) }
  end

  describe '#owners' do
    let(:owner) { build(:user) }
    let(:namespace) { build(:namespace, owner: owner) }

    specify do
      expect(namespace.owners).to match_array([owner])
    end
  end
end
