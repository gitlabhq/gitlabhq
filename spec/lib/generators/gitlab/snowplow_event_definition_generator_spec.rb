# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SnowplowEventDefinitionGenerator, :silence_stdout, feature_category: :product_analytics do
  let(:ce_temp_dir) { Dir.mktmpdir }
  let(:ee_temp_dir) { Dir.mktmpdir }
  let(:timestamp) { Time.now.utc.strftime('%Y%m%d%H%M%S') }
  let(:generator_options) { { 'category' => 'Groups::EmailCampaignsController', 'action' => 'click' } }

  before do
    stub_const("#{described_class}::CE_DIR", ce_temp_dir)
    stub_const("#{described_class}::EE_DIR", ee_temp_dir)
  end

  around do |example|
    freeze_time { example.run }
  end

  after do
    FileUtils.rm_rf([ce_temp_dir, ee_temp_dir])
  end

  describe 'Creating event definition file' do
    before do
      stub_const('Gitlab::VERSION', '13.11.0-pre')
    end

    let(:sample_event_dir) { 'lib/generators/gitlab/snowplow_event_definition_generator' }
    let(:file_name) { Dir.children(ce_temp_dir).first }

    it 'creates CE event definition file using the template' do
      sample_event = ::Gitlab::Config::Loader::Yaml
                       .new(fixture_file(File.join(sample_event_dir, 'sample_event.yml'))).load_raw!

      described_class.new([], generator_options).invoke_all

      event_definition_path = File.join(ce_temp_dir, file_name)
      expect(::Gitlab::Config::Loader::Yaml.new(File.read(event_definition_path)).load_raw!).to eq(sample_event)
    end

    describe 'generated filename' do
      it 'includes timestamp' do
        described_class.new([], generator_options).invoke_all

        expect(file_name).to include(timestamp.to_s)
      end

      it 'removes special characters' do
        generator_options = { 'category' => '"`ui:[mavenpackages | t5%348()-=@ ]`"', 'action' => 'click' }

        described_class.new([], generator_options).invoke_all

        expect(file_name).to include('uimavenpackagest')
      end

      it 'cuts name if longer than 100 characters' do
        generator_options = { 'category' => 'a' * 100, 'action' => 'click' }

        described_class.new([], generator_options).invoke_all

        expect(file_name.length).to eq(100)
      end
    end

    context 'when event definition with same file name already exists' do
      before do
        stub_const('Gitlab::VERSION', '12.11.0-pre')
        described_class.new([], generator_options).invoke_all
      end

      it 'raises error' do
        expect { described_class.new([], generator_options.merge('force' => false)).invoke_all }
          .to raise_error(StandardError, /Event definition already exists at/)
      end
    end

    describe 'EE' do
      let(:file_name) { Dir.children(ee_temp_dir).first }

      it 'creates EE event definition file using the template' do
        sample_event = ::Gitlab::Config::Loader::Yaml
                         .new(fixture_file(File.join(sample_event_dir, 'sample_event_ee.yml'))).load_raw!

        described_class.new([], generator_options.merge('ee' => true)).invoke_all

        event_definition_path = File.join(ee_temp_dir, file_name)
        expect(::Gitlab::Config::Loader::Yaml.new(File.read(event_definition_path)).load_raw!).to eq(sample_event)
      end
    end
  end
end
