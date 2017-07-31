require 'spec_helper'

describe Gitlab::RequestForgeryProtection, :allow_forgery_protection do
  let(:csrf_token) { SecureRandom.base64(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH) }
  let(:env) do
    {
      'rack.input' => '',
      'rack.session' => {
        _csrf_token: csrf_token
      }
    }
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
