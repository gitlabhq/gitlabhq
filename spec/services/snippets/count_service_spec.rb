# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::CountService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '#new' do
    it 'raises an error if no author or project' do
      expect { described_class.new(user) }.to raise_error(ArgumentError)
    end

    it 'uses the SnippetsFinder to scope snippets by user' do
      expect(SnippetsFinder)
        .to receive(:new)
        .with(user, author: user, project: nil)

      described_class.new(user, author: user)
    end

    it 'allows scoping to project' do
      expect(SnippetsFinder)
        .to receive(:new)
        .with(user, author: nil, project: project)

      described_class.new(user, project: project)
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
