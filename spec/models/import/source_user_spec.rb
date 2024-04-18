# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUser, type: :model, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:placeholder_user).class_name('User') }
    it { is_expected.to belong_to(:reassign_to_user).class_name('User') }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:import_type) }
  end

  describe 'scopes' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:source_user_1) { create(:import_source_user, namespace: namespace) }
    let_it_be(:source_user_2) { create(:import_source_user, namespace: namespace) }
    let_it_be(:source_user_3) { create(:import_source_user) }

    describe '.for_namespace' do
      it 'only returns source users for the given namespace_id' do
        expect(described_class.for_namespace(namespace.id).to_a).to match_array(
          [source_user_1, source_user_2]
        )
      end
    end
  end

  describe 'state machine' do
    it 'begins in pending state' do
      expect(described_class.new.pending_assignment?).to eq(true)
    end
  end

  describe '.find_source_user' do
    let_it_be(:namespace_1) { create(:namespace) }
    let_it_be(:namespace_2) { create(:namespace) }
    let_it_be(:source_user_1) { create(:import_source_user, source_user_identifier: '1', namespace: namespace_1) }
    let_it_be(:source_user_2) { create(:import_source_user, source_user_identifier: '2', namespace: namespace_1) }
    let_it_be(:source_user_3) { create(:import_source_user, source_user_identifier: '1', namespace: namespace_2) }
    let_it_be(:source_user_4) do
      create(:import_source_user,
        source_user_identifier: '1',
        namespace: namespace_1,
        import_type: 'bitbucket',
        source_hostname: 'bitbucket.org'
      )
    end

    let_it_be(:source_user_5) do
      create(:import_source_user,
        source_user_identifier: '1',
        namespace: namespace_1,
        source_hostname: 'bitbucket-server-domain.com',
        import_type: 'bitbucket_server'
      )
    end

    it 'returns the first source_user that matches the source_user_identifier for the import source attributes' do
      expect(described_class.find_source_user(
        source_user_identifier: '1',
        namespace: namespace_1,
        source_hostname: 'github.com',
        import_type: 'github'
      )).to eq(source_user_1)
    end

    it 'does not throw an error when any attributes are nil' do
      expect do
        described_class.find_source_user(
          source_user_identifier: nil,
          namespace: nil,
          source_hostname: nil,
          import_type: nil
        )
      end.not_to raise_error
    end

    it 'returns nil if no namespace is provided' do
      expect(described_class.find_source_user(
        source_user_identifier: '1',
        namespace: nil,
        source_hostname: 'github.com',
        import_type: 'github'
      )).to be_nil
    end
  end
end
