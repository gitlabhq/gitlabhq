# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::GlRepository do
  describe '.parse' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:snippet) { create(:personal_snippet) }

    it 'parses a project gl_repository' do
      expect(described_class.parse("project-#{project.id}")).to eq([project, project, Gitlab::GlRepository::PROJECT])
    end

    it 'parses a wiki gl_repository' do
      expect(described_class.parse("wiki-#{project.id}")).to eq([project, project, Gitlab::GlRepository::WIKI])
    end

    it 'parses a snippet gl_repository' do
      expect(described_class.parse("snippet-#{snippet.id}")).to eq([snippet, nil, Gitlab::GlRepository::SNIPPET])
    end

    it 'parses a design gl_repository' do
      expect(described_class.parse("design-#{project.id}")).to eq([project, project, Gitlab::GlRepository::DESIGN])
    end

    it 'throws an argument error on an invalid gl_repository type' do
      expect { described_class.parse("badformat-#{project.id}") }.to raise_error(ArgumentError)
    end

    it 'throws an argument error on an invalid gl_repository id' do
      expect { described_class.parse("project-foo") }.to raise_error(ArgumentError)
    end
  end

  describe 'DESIGN' do
    it 'uses the design access checker' do
      expect(described_class::DESIGN.access_checker_class).to eq(::Gitlab::GitAccessDesign)
    end

    it 'builds a design repository' do
      expect(described_class::DESIGN.repository_resolver.call(create(:project)))
        .to be_a(::DesignManagement::Repository)
    end
  end
end
