# frozen_string_literal: true

require 'spec_helper'

VITE_GDK_CONFIG_FILEPATH = "config/vite.gdk.json"

RSpec.describe ViteGdk, feature_category: :tooling do
  before do
    allow(ViteRuby).to receive(:configure)
    allow(ViteRuby.env).to receive(:[]=)
    allow(YAML).to receive(:safe_load_file)
  end

  describe '#load_gdk_vite_config' do
    context 'when not in production environment' do
      before do
        stub_env('RAILS_ENV', nil)
      end

      context 'when it loads file successfully' do
        it 'configures ViteRuby' do
          expect(File).to receive(:exist?) do |file_path|
            expect(file_path).to end_with(VITE_GDK_CONFIG_FILEPATH)
          end.and_return(true)
          expect(YAML).to receive(:safe_load_file) do |file_path|
            expect(file_path).to end_with(VITE_GDK_CONFIG_FILEPATH)
          end.and_return('enabled' => true, 'port' => 3038, 'host' => '127.0.0.1', 'public_host' => 'gdk.test')
          expect(ViteRuby).to receive(:configure).with(host: 'gdk.test', https: false, port: 3038)
          expect(ViteRuby.env).to receive(:[]=).with('VITE_ENABLED', 'true')
          expect(ViteRuby.env).to receive(:[]=).with('VITE_HMR_HOST', 'gdk.test')

          described_class.load_gdk_vite_config
        end

        context 'when HMR config is present' do
          let(:hmr_config) do
            {
              'host' => 'hmr.gdk.test',
              'clientPort' => 9999,
              'protocol' => 'wss'
            }
          end

          it 'ViteRuby uses same host for hmr' do
            expect(File).to receive(:exist?) do |file_path|
              expect(file_path).to end_with(VITE_GDK_CONFIG_FILEPATH)
            end.and_return(true)
            expect(YAML).to receive(:safe_load_file) do |file_path|
              expect(file_path).to end_with(VITE_GDK_CONFIG_FILEPATH)
            end.and_return(
              'enabled' => true,
              'port' => 3038,
              'host' => '127.0.0.1',
              'public_host' => 'gdk.test',
              'hmr' => hmr_config)
            expect(ViteRuby).to receive(:configure).with(host: 'gdk.test', https: false, port: 3038)
            expect(ViteRuby.env).to receive(:[]=).with('VITE_ENABLED', 'true')
            expect(ViteRuby.env).to receive(:[]=).with('VITE_HMR_HOST', 'gdk.test')

            described_class.load_gdk_vite_config
          end
        end

        context 'when HTTPS config is present' do
          let(:https_config) do
            {
              'enabled' => true,
              'key' => 'key',
              'certificate' => 'certificate'
            }
          end

          it 'enables HTTPS' do
            expect(File).to receive(:exist?) do |file_path|
              expect(file_path).to end_with(VITE_GDK_CONFIG_FILEPATH)
            end.and_return(true)
            expect(YAML).to receive(:safe_load_file) do |file_path|
              expect(file_path).to end_with(VITE_GDK_CONFIG_FILEPATH)
            end.and_return(
              'enabled' => true,
              'port' => 3038,
              'host' => '127.0.0.1',
              'public_host' => 'gdk.test',
              'https' => https_config)
            expect(ViteRuby).to receive(:configure).with(host: 'gdk.test', https: true, port: 3038)
            expect(ViteRuby.env).to receive(:[]=).with('VITE_ENABLED', 'true')
            expect(ViteRuby.env).to receive(:[]=).with('VITE_HMR_HOST', 'gdk.test')

            described_class.load_gdk_vite_config
          end
        end
      end

      context 'when config file is missing and no Vite env vars are set' do
        it 'does nothing' do
          expect(File).to receive(:exist?) do |file_path|
            expect(file_path).to end_with(VITE_GDK_CONFIG_FILEPATH)
          end.and_return(false)
          expect(ViteRuby).not_to receive(:configure)
          expect(ViteRuby.env).not_to receive(:[]=).with('VITE_ENABLED', 'false')
          expect(ViteRuby.env).not_to receive(:[]=).with('VITE_ENABLED', 'true')

          described_class.load_gdk_vite_config
        end
      end

      context 'when config file is missing but Vite is enabled via env vars' do
        before do
          allow(File).to receive(:exist?).and_return(false)
        end

        context 'when VITE_ENABLED is true' do
          before do
            stub_env('VITE_ENABLED', 'true')
            stub_env('VITE_HMR_HOST', 'gitlab.caproni.test')
          end

          it 'configures ViteRuby from env vars', :aggregate_failures do
            expect(ViteRuby.env).to receive(:[]=).with('VITE_ENABLED', 'true')
            expect(ViteRuby.env).to receive(:[]=).with('VITE_HMR_HOST', 'gitlab.caproni.test')
            expect(ViteRuby).to receive(:configure).with(host: 'gitlab.caproni.test')

            described_class.load_gdk_vite_config
          end

          context 'when VITE_HMR_HOST is not set' do
            before do
              stub_env('VITE_HMR_HOST', nil)
            end

            it 'defaults the HMR host to localhost', :aggregate_failures do
              expect(ViteRuby.env).to receive(:[]=).with('VITE_ENABLED', 'true')
              expect(ViteRuby.env).to receive(:[]=).with('VITE_HMR_HOST', 'localhost')
              expect(ViteRuby).to receive(:configure).with(host: 'localhost')

              described_class.load_gdk_vite_config
            end
          end
        end

        context 'when VITE_ENABLED is not "true"' do
          before do
            stub_env('VITE_ENABLED', 'false')
          end

          it 'marks Vite disabled and does not configure ViteRuby', :aggregate_failures do
            expect(ViteRuby.env).to receive(:[]=).with('VITE_ENABLED', 'false')
            expect(ViteRuby.env).not_to receive(:[]=).with('VITE_HMR_HOST', anything)
            expect(ViteRuby).not_to receive(:configure)

            described_class.load_gdk_vite_config
          end
        end
      end

      context 'when the config file exists and Vite env vars are also set' do
        before do
          stub_env('VITE_ENABLED', 'true')
          stub_env('VITE_HMR_HOST', 'gitlab.caproni.test')
          allow(File).to receive(:exist?).and_return(true)
          allow(YAML).to receive(:safe_load_file).and_return('enabled' => true, 'public_host' => 'gdk.test')
        end

        it 'loads from the file and ignores the env vars', :aggregate_failures do
          expect(described_class).not_to receive(:load_config_from_env)
          expect(ViteRuby).to receive(:configure).with(host: 'gdk.test', https: false, port: 3808)

          described_class.load_gdk_vite_config
        end
      end
    end

    context 'when in production environment' do
      before do
        stub_env('RAILS_ENV', 'production')
      end

      it 'does not load and configure ViteRuby' do
        expect(YAML).not_to receive(:safe_load_file)
        expect(ViteRuby).not_to receive(:configure)
        expect(ViteRuby.env).not_to receive(:[]=).with('VITE_ENABLED')

        described_class.load_gdk_vite_config
      end
    end
  end
end
