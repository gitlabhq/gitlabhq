# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'tmpdir'
require 'open3'
require_relative '../../../scripts/lint/check_deprecated_files'

RSpec.describe CheckDeprecatedFiles, feature_category: :tooling do
  RSpec::Matchers.define_negated_matcher :exclude, :include

  let(:root) { Dir.mktmpdir }
  let(:registry) { File.join(root, 'deprecations.yml') }
  let(:registry_content) { '' }
  let(:modified_files) { [] }

  subject(:execute) { described_class.new(deprecation_registry: registry).execute!(modified_files) }

  before do
    File.write(registry, registry_content)
  end

  after do
    FileUtils.rm_rf(root)
  end

  context 'when deprecation registry does not exist' do
    it 'exits with error message' do
      FileUtils.rm_rf(root)

      expect { execute }.to raise_error(SystemExit)
        .and output(match(/Error: #{registry} not found/)).to_stderr
    end
  end

  context 'when deprecation registry is malformed' do
    let(:registry_content) { YAML.dump({ 'invalid' => [] }) }
    let(:modified_files) { ['test.rb'] }

    it 'exits with error message about parsing failure' do
      expect { execute }.to raise_error(SystemExit)
        .and output(match(/Error: Failed to parse #{registry}: key not found: "files"/)).to_stderr
    end
  end

  context 'when deprecation registry exists' do
    let(:registry_content) do
      YAML.dump({ 'files' => [
        { 'paths' => %w[app/views/admin/groups/_group.html.haml app/assets/javascripts/admin/groups/index.js] }
      ] })
    end

    context 'when no deprecated files are modified' do
      let(:modified_files) { %w[app/models/new_model.rb] }

      it 'exits with status 0' do
        expect { execute }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context 'when deprecated files are modified' do
      let(:modified_files) { %w[app/views/admin/groups/_group.html.haml app/models/new_model.rb] }

      it 'prints warning with modified deprecated files' do
        expect { execute }
          .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
            .and output(include('app/views/admin/groups/_group.html.haml')).to_stdout
      end

      it 'does not print non-deprecated modified files' do
        expect { execute }
          .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
            .and output(exclude('app/models/new_model.rb')).to_stdout
      end

      it 'does not print non-modified deprecated files' do
        expect { execute }
          .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
            .and output(exclude('app/assets/javascripts/admin/groups/index.js')).to_stdout
      end
    end
  end

  context 'when deprecation registry is empty' do
    let(:registry_content) { '' }
    let(:modified_files) { ['test.rb'] }

    it 'exits with status 0' do
      expect { execute }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
    end
  end

  context 'when files key is empty' do
    let(:registry_content) { YAML.dump({ 'files' => [] }) }
    let(:modified_files) { ['test.rb'] }

    it 'exits with status 0' do
      expect { execute }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
    end
  end
end
