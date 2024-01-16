# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "redis_new_instance_shared_examples" do |name, fallback_class|
  include TmpdirHelper

  let(:instance_specific_config_file) { "config/redis.#{name}.yml" }
  let(:fallback_config_file) { nil }
  let(:rails_root) { mktmpdir }

  before do
    allow(fallback_class).to receive(:config_file_name).and_return(fallback_config_file)
  end

  it_behaves_like "redis_shared_examples"

  describe '.pool' do
    before do
      allow(described_class).to receive(:config_file_name).and_call_original
      allow(fallback_class).to receive(:params).and_return({})

      clear_class_pool(described_class)
      clear_class_pool(fallback_class)
    end

    after do
      clear_class_pool(described_class)
      clear_class_pool(fallback_class)
    end

    context 'when not using fallback config' do
      it 'creates its own connection pool' do
        expect(fallback_class.pool == described_class.pool).to eq(false)
      end
    end

    context 'when using fallback config' do
      before do
        allow(described_class).to receive(:params).and_return({})
      end

      it 'uses the fallback class connection pool' do
        expect(fallback_class.pool == described_class.pool).to eq(true)
      end
    end
  end

  describe '#fetch_config' do
    subject { described_class.new('test').send(:fetch_config) }

    before do
      FileUtils.mkdir_p(File.join(rails_root, 'config'))

      allow(described_class).to receive(:rails_root).and_return(rails_root)
    end

    context 'when redis.yml exists' do
      before do
        allow(described_class).to receive(:config_file_name).and_call_original
        allow(described_class).to receive(:redis_yml_path).and_call_original
      end

      context 'when the fallback has a redis.yml entry' do
        before do
          File.write(File.join(rails_root, 'config/redis.yml'), {
            'test' => {
              described_class.config_fallback.store_name.underscore => { 'fallback redis.yml' => 123 }
            }
          }.to_json)
        end

        it { expect(subject).to eq({ 'fallback redis.yml' => 123 }) }

        context 'and an instance config file exists' do
          before do
            File.write(File.join(rails_root, instance_specific_config_file), {
              'test' => { 'instance specific file' => 456 }
            }.to_json)
          end

          it { expect(subject).to eq({ 'instance specific file' => 456 }) }

          context 'and the instance has a redis.yml entry' do
            before do
              File.write(File.join(rails_root, 'config/redis.yml'), {
                'test' => { name => { 'instance redis.yml' => 789 } }
              }.to_json)
            end

            it { expect(subject).to eq({ 'instance redis.yml' => 789 }) }
          end
        end
      end
    end

    context 'when no redis config file exsits' do
      it 'returns nil' do
        expect(subject).to eq(nil)
      end

      context 'when resque.yml exists' do
        before do
          File.write(File.join(rails_root, 'config/resque.yml'), {
            'test' => { 'foobar' => 123 }
          }.to_json)
        end

        it 'returns the config from resque.yml' do
          expect(subject).to eq({ 'foobar' => 123 })
        end
      end
    end
  end

  def clear_class_pool(klass)
    klass.remove_instance_variable(:@pool)
  rescue NameError
    # raised if @pool was not set; ignore
  end
end
