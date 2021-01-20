# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Faraday::ErrorCallback do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app, {}) }

  describe '#call' do
    let(:env) { { url: 'http://target.url' } }

    subject { middleware.call(env) }

    context 'with no errors' do
      before do
        expect(app).to receive(:call).with(env).and_return('success')
      end

      it { is_expected.to eq('success') }
    end

    context 'with errors' do
      before do
        expect(app).to receive(:call).and_raise(ArgumentError, 'Kaboom!')
      end

      context 'with no callback' do
        it 'uses the default callback' do
          expect { subject }.to raise_error(ArgumentError, 'Kaboom!')
        end
      end

      context 'with a custom callback' do
        let(:options) { { callback: callback } }

        it 'uses the custom callback' do
          count = 0
          target_url = nil
          exception_class = nil

          callback = proc do |env, exception|
            count += 1
            target_url = env[:url].to_s
            exception_class = exception.class.name
          end

          options = { callback: callback }
          middleware = described_class.new(app, options)

          expect(callback).to receive(:call).and_call_original
          expect { middleware.call(env) }.to raise_error(ArgumentError, 'Kaboom!')
          expect(count).to eq(1)
          expect(target_url).to eq('http://target.url')
          expect(exception_class).to eq(ArgumentError.name)
        end
      end
    end
  end
end
