# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::NullAuthor do
  subject { described_class }

  describe '.for' do
    let(:audit_event) { instance_double(AuditEvent) }

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
      allow(audit_event).to receive(:entity_type).and_return('User')
      allow(audit_event).to receive(:entity_path).and_return('/a/b')
      allow(audit_event).to receive(:target_type).and_return(::Ci::Runner.name)
      allow(audit_event).to receive(:details)
        .and_return({ runner_registration_token: 'cde456', author_name: 'cde456', entity_type: 'User', entity_path: '/a/b' })

      expect(subject.for(-1, audit_event)).to be_a(Gitlab::Audit::CiRunnerTokenAuthor)
      expect(subject.for(-1, audit_event)).to have_attributes(id: -1, name: 'Registration token: cde456')
    end

    it 'works with string keys', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('cde456')
      allow(audit_event).to receive(:entity_type).and_return('User')
      allow(audit_event).to receive(:entity_path).and_return('/a/b')
      allow(audit_event).to receive(:target_type).and_return(::Ci::Runner.name)
      allow(audit_event).to receive(:details)
        .and_return({ 'runner_registration_token' => 'cde456', 'author_name' => 'cde456', 'entity_type' => 'User', 'entity_path' => '/a/b' }.with_indifferent_access)

      expect(subject.for(-1, audit_event)).to be_a(Gitlab::Audit::CiRunnerTokenAuthor)
      expect(subject.for(-1, audit_event)).to have_attributes(id: -1, name: 'Registration token: cde456')
    end

    it 'returns a CiRunnerTokenAuthor when details contain runner authentication token', :aggregate_failures do
      allow(audit_event).to receive(:[]).with(:author_name).and_return('cde456')
      allow(audit_event).to receive(:entity_type).and_return('User')
      allow(audit_event).to receive(:entity_path).and_return('/a/b')
      allow(audit_event).to receive(:target_type).and_return(::Ci::Runner.name)
      allow(audit_event).to receive(:details)
        .and_return({ runner_authentication_token: 'cde456', author_name: 'cde456', entity_type: 'User', entity_path: '/a/b' })

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
  end

  describe '#current_sign_in_ip' do
    it { expect(subject.new(id: 888, name: 'Guest').current_sign_in_ip).to be_nil }
  end

  describe '#impersonated?' do
    it { expect(subject.new(id: 888, name: 'Guest').impersonated?).to be false }
  end
end
