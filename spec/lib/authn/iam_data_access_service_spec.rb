# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamDataAccessService, feature_category: :system_access do
  describe '.grpc_address' do
    subject(:grpc_address) { described_class.grpc_address }

    context 'when host and port are configured' do
      before do
        stub_config(iam_data_access_service: {
          grpc: { host: 'iam.example.com', port: 5005 }
        })
      end

      it 'returns tls:// address in non-development environment' do
        allow(Rails.env).to receive(:development?).and_return(false)

        expect(grpc_address).to eq('tls://iam.example.com:5005')
      end

      it 'returns plain address in development environment' do
        allow(Rails.env).to receive(:development?).and_return(true)

        expect(grpc_address).to eq('iam.example.com:5005')
      end
    end

    context 'when host is blank' do
      before do
        stub_config(iam_data_access_service: {
          grpc: { host: '', port: 5005 }
        })
      end

      it 'raises ConfigurationError' do
        expect { grpc_address }.to raise_error(
          described_class::ConfigurationError, 'IAM data access gRPC service is not configured'
        )
      end
    end

    context 'when port is blank' do
      before do
        stub_config(iam_data_access_service: {
          grpc: { host: 'iam.example.com', port: '' }
        })
      end

      it 'raises ConfigurationError' do
        expect { grpc_address }.to raise_error(
          described_class::ConfigurationError, 'IAM data access gRPC service is not configured'
        )
      end
    end

    context 'when both host and port are blank' do
      before do
        stub_config(iam_data_access_service: {
          grpc: { host: '', port: '' }
        })
      end

      it 'raises ConfigurationError' do
        expect { grpc_address }.to raise_error(
          described_class::ConfigurationError, 'IAM data access gRPC service is not configured'
        )
      end
    end
  end

  describe '.secret' do
    after do
      described_class.clear_memoization(:secret)
    end

    context 'when secret_file is not configured' do
      before do
        stub_config(iam_data_access_service: { secret_file: nil, grpc: {} })
      end

      it 'raises ConfigurationError' do
        expect { described_class.secret }
          .to raise_error(described_class::ConfigurationError, 'IAM data access service secret_file is not configured')
      end
    end

    context 'when secret_file is configured' do
      before do
        stub_config(iam_data_access_service: {
          secret_file: '/etc/gitlab/iam-data-access/.gitlab_iam_data_access_secret',
          grpc: {}
        })
      end

      context 'when the file exists and is readable' do
        before do
          stub_file_read('/etc/gitlab/iam-data-access/.gitlab_iam_data_access_secret',
            content: "my-secret-token\n")
        end

        it 'returns the file contents' do
          expect(described_class.secret).to eq('my-secret-token')
        end
      end

      context 'when the file exists but is empty' do
        before do
          stub_file_read('/etc/gitlab/iam-data-access/.gitlab_iam_data_access_secret', content: "\n")
        end

        it 'raises ConfigurationError' do
          expect { described_class.secret }
            .to raise_error(described_class::ConfigurationError, 'IAM data access service secret_file is empty')
        end
      end

      context 'when the file does not exist' do
        before do
          stub_file_read('/etc/gitlab/iam-data-access/.gitlab_iam_data_access_secret', error: Errno::ENOENT)
        end

        it 'raises Errno::ENOENT' do
          expect { described_class.secret }.to raise_error(Errno::ENOENT)
        end
      end

      context 'when the file is not readable' do
        before do
          stub_file_read('/etc/gitlab/iam-data-access/.gitlab_iam_data_access_secret', error: Errno::EACCES)
        end

        it 'raises Errno::EACCES' do
          expect { described_class.secret }.to raise_error(Errno::EACCES)
        end
      end
    end
  end
end
