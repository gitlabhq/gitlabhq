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
    it { is_expected.to validate_presence_of(:placeholder_user_id) }
    it { is_expected.to validate_presence_of(:source_hostname) }
    it { is_expected.to validate_presence_of(:source_user_identifier) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_absence_of(:reassignment_token) }
    it { is_expected.not_to validate_presence_of(:reassign_to_user_id) }

    it 'validates source_hostname has port and scheme' do
      create(:import_source_user)

      is_expected.to allow_value("http://example.com:8080", "http://example.com").for(:source_hostname)
      is_expected.not_to allow_values("http://", "example.com", "http://example.com/dir").for(:source_hostname)
    end

    it 'validates uniqueness of reassign_to_user_id' do
      create(:import_source_user, :reassignment_in_progress)

      is_expected.to validate_uniqueness_of(:reassign_to_user_id)
        .scoped_to(:namespace_id, :source_hostname, :import_type)
        .with_message('already assigned to another placeholder')
    end

    it 'validates uniqueness of source_user_identifier' do
      create(:import_source_user)

      is_expected.to validate_uniqueness_of(:source_user_identifier)
        .scoped_to(:namespace_id, :source_hostname, :import_type)
    end

    context 'when completed' do
      subject { build(:import_source_user, :completed) }

      it { is_expected.not_to validate_presence_of(:placeholder_user_id) }
      it { is_expected.to validate_presence_of(:reassign_to_user_id) }
    end

    context 'when awaiting_approval' do
      subject { build(:import_source_user, :awaiting_approval) }

      it { is_expected.to validate_presence_of(:reassign_to_user_id) }
      it { is_expected.to validate_length_of(:reassignment_token).is_equal_to(32) }
      it { is_expected.to validate_presence_of(:reassignment_token).with_message(/is the wrong length/) }
    end

    context 'when reassignment_in_progress' do
      subject { build(:import_source_user, :reassignment_in_progress) }

      it { is_expected.to validate_presence_of(:reassign_to_user_id) }
    end

    context 'when rejected' do
      subject { build(:import_source_user, :rejected) }

      it { is_expected.not_to validate_absence_of(:reassign_to_user_id) }
    end

    context 'when pending_reassignment' do
      subject { build(:import_source_user, :pending_reassignment) }

      it { is_expected.to validate_absence_of(:reassign_to_user_id) }
    end

    context 'when keep_as_placeholder' do
      subject { build(:import_source_user, :keep_as_placeholder) }

      it { is_expected.to validate_absence_of(:reassign_to_user_id) }
    end
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

    describe '.awaiting_reassignment' do
      it 'only returns source users that await reassignment' do
        namespace = create(:namespace)
        pending_reassignment_user = create(:import_source_user, :pending_reassignment, namespace: namespace)
        awaiting_approval_user = create(:import_source_user, :awaiting_approval, namespace: namespace)

        expect(namespace.import_source_users.awaiting_reassignment)
          .to match_array([pending_reassignment_user, awaiting_approval_user])
      end
    end

    describe '.reassigned' do
      it 'only returns source users with status completed' do
        namespace = create(:namespace)
        completed_assignment_user = create(:import_source_user, :completed, namespace: namespace)
        placeholder_user = create(:import_source_user, :keep_as_placeholder, namespace: namespace)

        expect(described_class.for_namespace(namespace.id).to_a)
          .to match_array([completed_assignment_user, placeholder_user])
      end
    end
  end

  describe 'state machine' do
    it 'begins in pending state' do
      expect(described_class.new.pending_reassignment?).to eq(true)
    end

    context 'when switching to awaiting_approval' do
      subject(:source_user) { create(:import_source_user, :pending_reassignment) }

      it 'assigns a reassignment_token' do
        expect { source_user.reassign }.to change { source_user.reassignment_token }.from(nil)
      end
    end

    context 'when switching from awaiting_approval' do
      subject(:source_user) { create(:import_source_user, :awaiting_approval) }

      it 'removes the reassignment_token' do
        expect { source_user.cancel_reassignment }.to change { source_user.reassignment_token }.to(nil)
      end
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
        source_hostname: 'https://bitbucket.org'
      )
    end

    let_it_be(:source_user_5) do
      create(:import_source_user,
        source_user_identifier: '1',
        namespace: namespace_1,
        source_hostname: 'https://bitbucket-server-domain.com',
        import_type: 'bitbucket_server'
      )
    end

    it 'returns the first source_user that matches the source_user_identifier for the import source attributes' do
      expect(described_class.find_source_user(
        source_user_identifier: '1',
        namespace: namespace_1,
        source_hostname: 'https://github.com',
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
        source_hostname: 'https://github.com',
        import_type: 'github'
      )).to be_nil
    end
  end

  describe '.search' do
    let!(:source_user) do
      create(:import_source_user, source_name: 'Source Name', source_username: 'Username')
    end

    it 'searches by source_name or source_username' do
      expect(described_class.search('name')).to eq([source_user])
      expect(described_class.search('username')).to eq([source_user])
      expect(described_class.search('source')).to eq([source_user])
      expect(described_class.search('inexistent')).to eq([])
    end
  end

  describe '.sort_by_attribute' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:source_user_1) { create(:import_source_user, namespace: namespace, status: 4, source_name: 'd') }
    let_it_be(:source_user_2) { create(:import_source_user, namespace: namespace, status: 3, source_name: 'c') }
    let_it_be(:source_user_3) do
      create(
        :import_source_user, :with_reassign_to_user,
        namespace: namespace, status: 1, source_name: 'a', reassignment_token: SecureRandom.hex
      )
    end

    let_it_be(:source_user_4) do
      create(:import_source_user, :with_reassign_to_user, namespace: namespace, status: 2, source_name: 'b')
    end

    let(:sort_by_attribute) { described_class.sort_by_attribute(method).pluck(attribute) }

    context 'with method status_asc' do
      let(:method) { 'status_asc' }
      let(:attribute) { :status }

      it 'order by status_desc ascending' do
        expect(sort_by_attribute).to eq([1, 2, 3, 4])
      end
    end

    context 'with method status_desc' do
      let(:method) { 'status_desc' }
      let(:attribute) { :status }

      it 'order by status_desc descending' do
        expect(sort_by_attribute).to eq([4, 3, 2, 1])
      end
    end

    context 'with method source_name_asc' do
      let(:method) { 'source_name_asc' }
      let(:attribute) { :source_name }

      it 'order by source_name_asc ascending' do
        expect(sort_by_attribute).to eq(%w[a b c d])
      end
    end

    context 'with method source_name_desc' do
      let(:method) { 'source_name_desc' }
      let(:attribute) { :source_name }

      it 'order by source_name_desc descending' do
        expect(sort_by_attribute).to eq(%w[d c b a])
      end
    end

    context 'with an unexpected method' do
      let(:method) { 'id_asc' }
      let(:attribute) { :source_name }

      it 'order by source_name_asc ascending' do
        expect(sort_by_attribute).to eq(%w[a b c d])
      end
    end
  end

  describe '.namespace_placeholder_user_count' do
    let_it_be_with_refind(:namespace) { create(:namespace) }

    subject(:namespace_placeholder_user_count) do
      described_class.namespace_placeholder_user_count(namespace, limit: 100)
    end

    before_all do
      placeholder_user = create(:import_source_user, namespace: namespace).placeholder_user
      create_list(:import_source_user, 2, placeholder_user: placeholder_user, namespace: namespace)
      create(:import_source_user, :completed, placeholder_user: nil, namespace: namespace)
      create(:import_source_user)
    end

    it 'returns the count of records with unique placeholder users for the namespace' do
      expect(namespace_placeholder_user_count).to eq(1)
    end

    it 'does not count the import user type' do
      import_user = create(:namespace_import_user, namespace: namespace).import_user
      create(:import_source_user, placeholder_user: import_user, namespace: namespace)

      expect(namespace_placeholder_user_count).to eq(1)
    end

    it 'can limit the count to optimize the query' do
      create(:import_source_user, namespace: namespace)

      expect(described_class.namespace_placeholder_user_count(namespace, limit: 1)).to eq(1)
      expect(described_class.namespace_placeholder_user_count(namespace, limit: 2)).to eq(2)
      expect(described_class.namespace_placeholder_user_count(namespace, limit: 3)).to eq(2)
    end
  end

  describe '.source_users_with_missing_information' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:import_type) { 'github' }
    let_it_be(:source_hostname) { 'https://github.com' }

    let_it_be(:source_user_1) do
      create(:import_source_user, namespace: namespace, source_username: nil, source_name: nil,
        import_type: import_type, source_hostname: source_hostname)
    end

    let_it_be(:source_user_2) do
      create(:import_source_user, namespace: namespace, source_username: 'a', source_name: nil,
        import_type: import_type, source_hostname: source_hostname)
    end

    let_it_be(:source_user_3) do
      create(:import_source_user, namespace: namespace, source_username: nil, source_name: 'b',
        import_type: import_type, source_hostname: source_hostname)
    end

    before_all do
      create(:import_source_user, namespace: namespace, source_username: 'a', source_name: 'b',
        import_type: import_type, source_hostname: source_hostname)
      create(:import_source_user, source_username: nil, source_name: nil, import_type: import_type,
        source_hostname: source_hostname)
      create(:import_source_user, namespace: namespace, source_username: nil, source_name: nil,
        import_type: 'gitlab_importer', source_hostname: source_hostname)
      create(:import_source_user, namespace: namespace, source_username: nil, source_name: nil,
        import_type: import_type, source_hostname: 'http://source_hostname')
    end

    it 'returns the count of records with unique placeholder users for the namespace' do
      results = described_class.source_users_with_missing_information(namespace: namespace, import_type: import_type,
        source_hostname: source_hostname)

      expect(results).to match_array([source_user_1, source_user_2, source_user_3])
    end
  end

  describe '#mapped_user' do
    let_it_be(:source_user) { build(:import_source_user, :with_reassign_to_user) }

    subject(:mapped_user) { source_user.mapped_user }

    before do
      allow(source_user).to receive(:accepted_status?).and_return(accepted)
    end

    context 'when accepted' do
      let(:accepted) { true }

      it { is_expected.to eq(source_user.reassign_to_user) }
    end

    context 'when not accepted' do
      let(:accepted) { false }

      it { is_expected.to eq(source_user.placeholder_user) }
    end
  end

  describe '#mapped_user_id' do
    let_it_be(:source_user) { build(:import_source_user, :with_reassign_to_user) }

    subject(:mapped_user_id) { source_user.mapped_user_id }

    before do
      allow(source_user).to receive(:accepted_status?).and_return(accepted)
    end

    context 'when accepted' do
      let(:accepted) { true }

      it { is_expected.to eq(source_user.reassign_to_user_id) }
    end

    context 'when not accepted' do
      let(:accepted) { false }

      it { is_expected.to eq(source_user.placeholder_user_id) }
    end
  end

  describe '#reassignable_status?' do
    reassignable_statuses = [:pending_reassignment, :rejected]
    all_states = described_class.state_machines[:status].states

    all_states.reject { |state| reassignable_statuses.include?(state.name) }.each do |state|
      it "returns false for #{state.name}" do
        expect(described_class.new(status: state.value)).not_to be_reassignable_status
      end
    end

    all_states.select { |state| reassignable_statuses.include?(state.name) }.each do |state|
      it "returns true for #{state.name}" do
        expect(described_class.new(status: state.value)).to be_reassignable_status
      end
    end
  end

  describe '#cancelable_status?' do
    cancelable_statuses = [:awaiting_approval, :rejected]
    all_states = described_class.state_machines[:status].states

    all_states.reject { |state| cancelable_statuses.include?(state.name) }.each do |state|
      it "returns false for #{state.name}" do
        expect(described_class.new(status: state.value)).not_to be_cancelable_status
      end
    end

    all_states.select { |state| cancelable_statuses.include?(state.name) }.each do |state|
      it "returns true for #{state.name}" do
        expect(described_class.new(status: state.value)).to be_cancelable_status
      end
    end
  end

  describe '#accepted_status?' do
    accepted_statuses = [:reassignment_in_progress, :completed, :failed]
    all_states = described_class.state_machines[:status].states

    all_states.reject { |state| accepted_statuses.include?(state.name) }.each do |state|
      it "returns false for #{state.name}" do
        expect(described_class.new(status: state.value)).not_to be_accepted_status
      end
    end

    all_states.select { |state| accepted_statuses.include?(state.name) }.each do |state|
      it "returns true for #{state.name}" do
        expect(described_class.new(status: state.value)).to be_accepted_status
      end
    end
  end
end
