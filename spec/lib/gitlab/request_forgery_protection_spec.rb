# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RequestForgeryProtection, :allow_forgery_protection do
  let(:csrf_token) { 'YAYvO6dOQJGvIp/7DnZSa42h8AjB5mp0cXGIBgciby8=' }

  let(:env) do
    {
      'rack.input' => '',
      'rack.session' => {
        _csrf_token: csrf_token
      }
    }
  end

  before do
    allow(env['rack.session']).to receive(:enabled?).and_return(true)
    allow(env['rack.session']).to receive(:loaded?).and_return(true)
  end

  it 'logs to /dev/null' do
    expect(ActiveSupport::Logger).to receive(:new).with(File::NULL)

    described_class::Controller.new.logger
  end

  describe '.call' do
    context 'when the request method is GET' do
      before do
        env['REQUEST_METHOD'] = 'GET'
      end

      it 'does not raise an exception' do
        expect { described_class.call(env) }.not_to raise_exception
      end
    end

    context 'when the request method is POST' do
      before do
        env['REQUEST_METHOD'] = 'POST'
      end

      context 'when the CSRF token is valid' do
        before do
          env['HTTP_X_CSRF_TOKEN'] = csrf_token
        end

        it 'does not raise an exception' do
          expect { described_class.call(env) }.not_to raise_exception
        end
      end

      context 'when the CSRF token is invalid' do
        before do
          env['HTTP_X_CSRF_TOKEN'] = 'foo'
        end

        it 'raises an ActionController::InvalidAuthenticityToken exception' do
          expect { described_class.call(env) }.to raise_exception(ActionController::InvalidAuthenticityToken)
        end
      end
    end
  end

  describe '.verified?' do
    it 'does not modify the env' do
      env['REQUEST_METHOD'] = "GET"
      expect { described_class.verified?(env) }.not_to change { env }
    end

    context 'when the request method is GET' do
      before do
        env['REQUEST_METHOD'] = 'GET'
      end

      it 'returns true' do
        expect(described_class.verified?(env)).to be_truthy
      end
    end

    context 'when the request method is POST' do
      before do
        env['REQUEST_METHOD'] = 'POST'
      end

      context 'when the CSRF token is valid' do
        before do
          env['HTTP_X_CSRF_TOKEN'] = csrf_token
        end

        it 'returns true' do
          expect(described_class.verified?(env)).to be_truthy
        end
      end

      context 'when the CSRF token is valid and in the body' do
        before do
          env['rack.input'] = StringIO.new("authenticity_token=#{csrf_token}")
        end

        it 'returns true' do
          expect(described_class.verified?(env)).to be_truthy
        end
      end

      context 'when the CSRF token is invalid' do
        before do
          env['HTTP_X_CSRF_TOKEN'] = 'foo'
        end

        it 'returns false' do
          expect(described_class.verified?(env)).to be_falsey
        end
      end
    end
  end
end
