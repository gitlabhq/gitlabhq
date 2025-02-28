# frozen_string_literal: true

require 'rubocop'
require 'tmpdir'
require_relative '../../rubocop/cops_documentation_generator'

RSpec.describe RuboCop::CopsDocumentationGenerator, feature_category: :tooling do
  around do |example|
    new_global = RuboCop::Cop::Registry.new([RuboCop::Cop::Style::HashSyntax])
    RuboCop::Cop::Registry.with_temporary_global(new_global) { example.run }
  end

  context 'when using default Asciidoc formatter' do
    it 'generates docs without errors' do
      Dir.mktmpdir do |tmpdir|
        generator = described_class.new(departments: %w[Style], base_dir: tmpdir)

        expect do
          generator.call
        end.to output(%r{generated .*docs/modules/ROOT/pages/cops_style.adoc}).to_stdout
      end
    end
  end

  context 'when using Markdown formatter' do
    it 'generates docs without errors' do
      Dir.mktmpdir do |tmpdir|
        generator = described_class.new(
          formatter: RuboCop::CopsDocumentationGenerator::Formatters::Markdown.new, departments: %w[Style],
          base_dir: tmpdir
        )
        expect do
          generator.call
        end.to output(%r{generated .*docs/modules/ROOT/pages/cops_style.md}).to_stdout
      end
    end
  end
end
