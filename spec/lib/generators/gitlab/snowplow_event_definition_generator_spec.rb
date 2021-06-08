# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SnowplowEventDefinitionGenerator, :silence_stdout do
  let(:ce_temp_dir) { Dir.mktmpdir }
  let(:ee_temp_dir) { Dir.mktmpdir }
  let(:generator_options) { { 'category' => 'Groups::EmailCampaignsController', 'action' => 'click' } }

  before do
    stub_const("#{described_class}::CE_DIR", ce_temp_dir)
    stub_const("#{described_class}::EE_DIR", ee_temp_dir)
  end

  after do
    FileUtils.rm_rf([ce_temp_dir, ee_temp_dir])
  end

  describe 'Creating event definition file' do
    before do
      stub_const('Gitlab::VERSION', '13.11.0-pre')
    end

    let(:sample_event_dir) { 'lib/generators/gitlab/snowplow_event_definition_generator' }

    it 'creates CE event definition file using the template' do
      sample_event = ::Gitlab::Config::Loader::Yaml.new(fixture_file(File.join(sample_event_dir, 'sample_event.yml'))).load_raw!

      described_class.new([], generator_options).invoke_all

      event_definition_path = File.join(ce_temp_dir, 'groups__email_campaigns_controller_click.yml')
      expect(::Gitlab::Config::Loader::Yaml.new(File.read(event_definition_path)).load_raw!).to eq(sample_event)
    end

    context 'event definition already exists' do
      before do
        stub_const('Gitlab::VERSION', '12.11.0-pre')
        described_class.new([], generator_options).invoke_all
      end

      it 'overwrites event definition --force flag set to true' do
        sample_event = ::Gitlab::Config::Loader::Yaml.new(fixture_file(File.join(sample_event_dir, 'sample_event.yml'))).load_raw!

        stub_const('Gitlab::VERSION', '13.11.0-pre')
        described_class.new([], generator_options.merge('force' => true)).invoke_all

        event_definition_path = File.join(ce_temp_dir, 'groups__email_campaigns_controller_click.yml')
        event_data = ::Gitlab::Config::Loader::Yaml.new(File.read(event_definition_path)).load_raw!

        expect(event_data).to eq(sample_event)
      end

      it 'raises error when --force flag set to false' do
        expect { described_class.new([], generator_options.merge('force' => false)).invoke_all }
          .to raise_error(StandardError, /Event definition already exists at/)
      end
    end

    it 'creates EE event definition file using the template' do
      sample_event = ::Gitlab::Config::Loader::Yaml.new(fixture_file(File.join(sample_event_dir, 'sample_event_ee.yml'))).load_raw!

      described_class.new([], generator_options.merge('ee' => true)).invoke_all

      event_definition_path = File.join(ee_temp_dir, 'groups__email_campaigns_controller_click.yml')
      expect(::Gitlab::Config::Loader::Yaml.new(File.read(event_definition_path)).load_raw!).to eq(sample_event)
    end
  end
end
