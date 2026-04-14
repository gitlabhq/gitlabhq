# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamAuthService, feature_category: :system_access do
  describe '.enabled?' do
    it 'returns the enabled setting from config' do
      stub_config(iam_auth_service: { enabled: false, http: {}, grpc: {}, jwt_audience: 'gitlab-rails' })

      expect(described_class.enabled?).to be(false)
    end
  end

  describe '.url' do
    context 'when host and port are configured' do
      before do
        stub_config(iam_auth_service: {
          enabled: true,
          http: { host: 'iam.example.com', port: 443 },
          grpc: {},
          jwt_audience: 'gitlab-rails'
        })
      end

      it 'returns https URL in non-development environment' do
        allow(Rails.env).to receive(:development?).and_return(false)

        expect(described_class.url).to eq('https://iam.example.com:443')
      end

      it 'returns http URL in development environment' do
        allow(Rails.env).to receive(:development?).and_return(true)

        expect(described_class.url).to eq('http://iam.example.com:443')
      end
    end

    context 'when host is blank' do
      before do
        stub_config(iam_auth_service: {
          enabled: true,
          http: { host: '', port: 443 },
          grpc: {},
          jwt_audience: 'gitlab-rails'
        })
      end

      it 'raises ConfigurationError' do
        expect { described_class.url }
          .to raise_error(described_class::ConfigurationError, 'IAM service is not configured')
      end
    end

    context 'when port is blank' do
      before do
        stub_config(iam_auth_service: {
          enabled: true,
          http: { host: 'iam.example.com', port: '' },
          grpc: {},
          jwt_audience: 'gitlab-rails'
        })
      end

      it 'raises ConfigurationError' do
        expect { described_class.url }
          .to raise_error(described_class::ConfigurationError, 'IAM service is not configured')
      end
    end
  end

  describe '.jwt_audience' do
    it 'returns the jwt_audience from config' do
      stub_config(iam_auth_service: { enabled: false, http: {}, grpc: {}, jwt_audience: 'custom-audience' })

      expect(described_class.jwt_audience).to eq('custom-audience')
    end
  end

  describe '.secret' do
    after do
      described_class.clear_memoization(:secret)
    end

    context 'when secret_file is not configured' do
      before do
        stub_config(iam_auth_service: { enabled: false, secret_file: nil, http: {}, grpc: {},
                                        jwt_audience: 'gitlab-rails' })
      end

      it 'raises ConfigurationError' do
        expect { described_class.secret }
          .to raise_error(described_class::ConfigurationError, 'IAM auth service secret_file is not configured')
      end
    end

    context 'when secret_file is configured' do
      before do
        stub_config(iam_auth_service: {
          enabled: false,
          secret_file: '/etc/gitlab/iam-auth/.gitlab_iam_auth_secret',
          http: {},
          grpc: {},
          jwt_audience: 'gitlab-rails'
        })
      end

      context 'when the file exists and is readable' do
        before do
          stub_file_read('/etc/gitlab/iam-auth/.gitlab_iam_auth_secret',
            content: "my-secret-token\n")
        end

        it 'returns the file contents' do
          expect(described_class.secret).to eq('my-secret-token')
        end
      end

      context 'when the file does not exist' do
        before do
          stub_file_read('/etc/gitlab/iam-auth/.gitlab_iam_auth_secret', error: Errno::ENOENT)
        end

        it 'raises Errno::ENOENT' do
          expect { described_class.secret }.to raise_error(Errno::ENOENT)
        end
      end

      context 'when the file is not readable' do
        before do
          stub_file_read('/etc/gitlab/iam-auth/.gitlab_iam_auth_secret', error: Errno::EACCES)
        end

        it 'raises Errno::EACCES' do
          expect { described_class.secret }.to raise_error(Errno::EACCES)
        end
      end
    end
  end
end
