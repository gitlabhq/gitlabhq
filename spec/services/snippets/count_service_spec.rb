# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::CountService, :with_current_organization, feature_category: :source_code_management do
  before do
    # Since this doesn't go through a request flow, we need to manually set Current.organization
    Current.organization = current_organization
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '#new' do
    it 'raises an error if no author or project' do
      expect { described_class.new(user) }.to raise_error(ArgumentError)
    end

    it 'uses the SnippetsFinder to scope snippets by user' do
      expect(SnippetsFinder)
        .to receive(:new)
        .with(user, author: user, project: nil, organization_id: current_organization.id)

      described_class.new(user, organization_id: current_organization.id, author: user)
    end

    it 'allows scoping to project' do
      expect(SnippetsFinder)
        .to receive(:new)
        .with(user, author: nil, project: project, organization_id: current_organization.id)

      described_class.new(user, organization_id: current_organization.id, project: project)
    end
  end

  describe '#execute' do
    subject { described_class.new(user, author: user).execute }

    it 'returns a hash of counts' do
      expect(subject).to match({
        are_public: 0,
        are_internal: 0,
        are_private: 0,
        are_public_or_internal: 0,
        total: 0
      })
    end

    it 'only counts snippets the user has access to' do
      create(:personal_snippet, :private, author: user)
      create(:project_snippet, :private, author: user)
      create(:project_snippet, :private, author: create(:user))

      expect(subject).to match({
        are_public: 0,
        are_internal: 0,
        are_private: 1,
        are_public_or_internal: 0,
        total: 1
      })
    end

    it 'returns an empty hash if select returns nil' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:snippet_counts).and_return(nil)
      end

      expect(subject).to match({})
    end
  end
end
