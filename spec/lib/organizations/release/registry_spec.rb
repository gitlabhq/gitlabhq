# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'

RSpec.describe Organizations::Release::Registry, feature_category: :organization do
  let(:tempfiles) { [] }
  let(:valid_config) do
    config_file(<<~YAML)
      flags:
        - name: ui_for_organizations
          description: Browse organizations.
          stage: beta
    YAML
  end

  after do
    tempfiles.each(&:close!)
  end

  def config_file(content)
    file = Tempfile.new(['organizations_release', '.yml'])
    tempfiles << file
    file.write(content)
    file.flush
    file
  end

  describe '#flags' do
    it 'builds organization flags from the config file', :aggregate_failures do
      flag = described_class.new(valid_config.path).flags.first

      expect(flag.name).to eq('ui_for_organizations')
      expect(flag.description).to eq('Browse organizations.')
      expect(flag.stage.key).to eq(:beta)
    end

    it 'raises for an unknown stage' do
      file = config_file(<<~YAML)
        flags:
          - name: bad
            description: Bad.
            stage: not_a_stage
      YAML

      expect { described_class.new(file.path).flags }
        .to raise_error(Organizations::Release::UnknownStageError, /not_a_stage/)
    end
  end

  describe '#find' do
    subject(:registry) { described_class.new(valid_config.path) }

    it 'returns the organization flag' do
      expect(registry.find(:ui_for_organizations).stage.key).to eq(:beta)
    end

    it 'raises for an unregistered flag' do
      expect { registry.find(:missing) }
        .to raise_error(Organizations::Release::UnknownFlagError)
    end
  end

  describe 'the committed config file' do
    it 'is valid' do
      expect { described_class.new.flags }.not_to raise_error
    end
  end
end
