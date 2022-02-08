# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'setting sec analyzer prefix dynamically' do |builds: [], files: { 'README.md' => '' }, variables: {}, namespace: ''|
  using RSpec::Parameterized::TableSyntax

  let(:default_analyzer_prefix) { 'registry.gitlab.com/security-products' }

  where(:builds, :files, :analyzer_prefix, :expected_prefix) do
    builds | files | nil                     | "$DEFAULT_SECURE_ANALYZERS_PREFIX#{namespace.present? ? "/#{namespace}" : nil}"
    builds | files | 'registry.example.com'  | 'registry.example.com'
  end

  with_them do
    before do
      if analyzer_prefix
        if analyzer_prefix != default_analyzer_prefix
          create(:ci_variable, project: project, key: 'SECURE_ANALYZERS_PREFIX', value: analyzer_prefix)
        end
      end

      variables.each do |(key, value)|
        create(:ci_variable, project: project, key: key, value: value)
      end
    end

    it 'creates a build with the expected tag' do
      expect(build_names).to include(*builds)

      prefixes = pipeline.builds.map { |build| build.variables["SECURE_ANALYZERS_PREFIX"].value }
      expect(prefixes.uniq).to match_array(expected_prefix)
    end
  end
end
