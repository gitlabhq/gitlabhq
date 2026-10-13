# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::NullAuthor, feature_category: :compliance_management do
  subject { described_class }

  describe '.for' do
    let(:audit_event) { instance_double(AuditEvents::UserAuditEvent) }

    it 'returns an DeletedAuthor' do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('Old Hat')
      allow(audit_event).to receive(:details).and_return({})
      allow(audit_event).to receive(:target_type)

      expect(subject.for(666, audit_event)).to be_a(Gitlab::Audit::DeletedAuthor)
    end

    it 'returns an UnauthenticatedAuthor when id equals -1', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('Frank')
      allow(audit_event).to receive(:details).and_return({})
      allow(audit_event).to receive(:target_type)

      expect(subject.for(-1, audit_event)).to be_a(Gitlab::Audit::UnauthenticatedAuthor)
      expect(subject.for(-1, audit_event)).to have_attributes(id: -1, name: 'Frank')
    end

    it 'returns a CiRunnerTokenAuthor when details contain runner registration token', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('cde456')
      allow(audit_event).to receive_messages(
        entity_type: 'User',
        entity_path: '/a/b',
        target_type: ::Ci::Runner.name,
        details: {
          runner_registration_token: 'cde456',
          author_name: 'cde456',
          entity_type: 'User',
          entity_path: '/a/b'
        }
      )

      expect(subject.for(-1, audit_event)).to be_a(Gitlab::Audit::CiRunnerTokenAuthor)
      expect(subject.for(-1, audit_event)).to have_attributes(id: -1, name: 'Registration token: cde456')
    end

    it 'works with string keys', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('cde456')
      allow(audit_event).to receive_messages(
        entity_type: 'User',
        entity_path: '/a/b',
        target_type: ::Ci::Runner.name,
        details: {
          'runner_registration_token' => 'cde456',
          'author_name' => 'cde456',
          'entity_type' => 'User',
          'entity_path' => '/a/b'
        }.with_indifferent_access
      )

      expect(subject.for(-1, audit_event)).to be_a(Gitlab::Audit::CiRunnerTokenAuthor)
      expect(subject.for(-1, audit_event)).to have_attributes(id: -1, name: 'Registration token: cde456')
    end

    it 'returns a CiRunnerTokenAuthor when details contain runner authentication token', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('cde456')
      allow(audit_event).to receive_messages(
        entity_type: 'User',
        entity_path: '/a/b',
        target_type: ::Ci::Runner.name,
        details: {
          runner_authentication_token: 'cde456',
          author_name: 'cde456',
          entity_type: 'User',
          entity_path: '/a/b'
        }
      )

      expect(subject.for(-1, audit_event)).to be_a(Gitlab::Audit::CiRunnerTokenAuthor)
      expect(subject.for(-1, audit_event)).to have_attributes(id: -1, name: 'Authentication token: cde456')
    end

    it 'returns DeployTokenAuthor when id equals -2', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('Test deploy token')
      allow(audit_event).to receive(:details).and_return({})
      allow(audit_event).to receive(:target_type)

      expect(subject.for(-2, audit_event)).to be_a(Gitlab::Audit::DeployTokenAuthor)
      expect(subject.for(-2, audit_event)).to have_attributes(id: -2, name: 'Test deploy token')
    end

    it 'returns DeployKeyAuthor when id equals -3', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('Test deploy key')
      allow(audit_event).to receive(:details).and_return({})
      allow(audit_event).to receive(:target_type)

      expect(subject.for(-3, audit_event)).to be_a(Gitlab::Audit::DeployKeyAuthor)
      expect(subject.for(-3, audit_event)).to have_attributes(id: -3, name: 'Test deploy key')
    end

    it 'preserves the security policy Unknown User author with id -4', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('Unknown User')
      allow(audit_event).to receive_messages(details: {}, target_type: 'Project')

      author = subject.for(-4, audit_event)

      expect(author).to be_a(Gitlab::Audit::DeletedAuthor)
      expect(author).to have_attributes(id: -4, name: 'Unknown User')
    end

    it 'round-trips the Orbit indexer author with a distinct id', :aggregate_failures do
      indexer = Gitlab::Audit::OrbitIndexerAuthor.new
      allow(audit_event).to receive(:[]).with(:author_name).and_return(indexer.name)
      allow(audit_event).to receive_messages(details: {}, target_type: 'Project')

      author = subject.for(indexer.id, audit_event)

      expect(author).to be_a(Gitlab::Audit::OrbitIndexerAuthor)
      expect(author).to have_attributes(id: indexer.id, name: indexer.name)
      expect(author.id).not_to eq(-4)
    end
  end

  describe '#current_sign_in_ip' do
    it { expect(subject.new(id: 888, name: 'Guest').current_sign_in_ip).to be_nil }
  end

  describe '#impersonated?' do
    it { expect(subject.new(id: 888, name: 'Guest').impersonated?).to be false }
  end

  describe '#to_global_id' do
    subject(:null_author) { described_class.new id: -1, name: 'John Doe' }

    it { expect(null_author.to_global_id).to eq('gid://gitlab/ComplianceManagement::NullAuthor/@id') }
  end
end
