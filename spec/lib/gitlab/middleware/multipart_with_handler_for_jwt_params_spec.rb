# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::Multipart do
  include MultipartHelpers

  describe '#call' do
    let(:app) { double(:app) }
    let(:middleware) { described_class.new(app) }
    let(:secret) { Gitlab::Workhorse.secret }
    let(:issuer) { 'gitlab-workhorse' }

    subject do
      env = post_env(
        rewritten_fields: rewritten_fields,
        params: params,
        secret: secret,
        issuer: issuer
      )
      middleware.call(env)
    end

    before do
      stub_feature_flags(upload_middleware_jwt_params_handler: true)
    end

    context 'remote file mode' do
      let(:mode) { :remote }

      it_behaves_like 'handling all upload parameters conditions'

      context 'and a path set' do
        include_context 'with one temporary file for multipart'

        let(:rewritten_fields) { rewritten_fields_hash('file' => uploaded_filepath) }
        let(:params) { upload_parameters_for(key: 'file', filename: filename, remote_id: remote_id).merge('file.path' => '/should/not/be/read') }

        it 'builds an UploadedFile' do
          expect_uploaded_files(original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(file))

          subject
        end
      end
    end

    context 'local file mode' do
      let(:mode) { :local }

      it_behaves_like 'handling all upload parameters conditions'

      context 'when file is' do
        include_context 'with one temporary file for multipart'

        let(:allowed_paths) { [Dir.tmpdir] }

        before do
          expect_next_instance_of(::Gitlab::Middleware::Multipart::HandlerForJWTParams) do |handler|
            expect(handler).to receive(:allowed_paths).and_return(allowed_paths)
          end
        end

        context 'in allowed paths' do
          let(:rewritten_fields) { rewritten_fields_hash('file' => uploaded_filepath) }
          let(:params) { upload_parameters_for(filepath: uploaded_filepath, key: 'file', filename: filename) }

          it 'builds an UploadedFile' do
            expect_uploaded_files(filepath: uploaded_filepath, original_filename: filename, size: uploaded_file.size, params_path: %w(file))

            subject
          end
        end

        context 'not in allowed paths' do
          let(:allowed_paths) { [] }

          let(:rewritten_fields) { rewritten_fields_hash('file' => uploaded_filepath) }
          let(:params) { upload_parameters_for(filepath: uploaded_filepath, key: 'file') }

          it 'returns an error' do
            result = subject

            expect(result[0]).to eq(400)
            expect(result[2]).to include('insecure path used')
          end
        end
      end
    end

    context 'with dummy params in remote mode' do
      let(:rewritten_fields) { { 'file' => 'should/not/be/read' } }
      let(:params) { upload_parameters_for(key: 'file') }
      let(:mode) { :remote }

      context 'with an invalid secret' do
        let(:secret) { 'INVALID_SECRET' }

        it { expect { subject }.to raise_error(JWT::VerificationError) }
      end

      context 'with an invalid issuer' do
        let(:issuer) { 'INVALID_ISSUER' }

        it { expect { subject }.to raise_error(JWT::InvalidIssuerError) }
      end

      context 'with invalid rewritten field key' do
        invalid_keys = [
          '[file]',
          ';file',
          'file]',
          ';file]',
          'file]]',
          'file;;'
        ]

        invalid_keys.each do |invalid_key|
          context invalid_key do
            let(:rewritten_fields) { { invalid_key => 'should/not/be/read' } }

            it { expect { subject }.to raise_error(RuntimeError, "invalid field: \"#{invalid_key}\"") }
          end
        end
      end

      context 'with invalid key in parameters' do
        include_context 'with one temporary file for multipart'

        let(:rewritten_fields) { rewritten_fields_hash('file' => uploaded_filepath) }
        let(:params) { upload_parameters_for(filepath: uploaded_filepath, key: 'wrong_key', filename: filename, remote_id: remote_id) }

        it 'raises an error' do
          expect { subject }.to raise_error(RuntimeError, 'Empty JWT param: file.gitlab-workhorse-upload')
        end
      end

      context 'with a modified JWT payload' do
        include_context 'with one temporary file for multipart'

        let(:rewritten_fields) { rewritten_fields_hash('file' => uploaded_filepath) }
        let(:crafted_payload) { Base64.urlsafe_encode64({ 'path' => 'test' }.to_json) }
        let(:params) do
          upload_parameters_for(filepath: uploaded_filepath, key: 'file', filename: filename, remote_id: remote_id).tap do |params|
            header, _, sig = params['file.gitlab-workhorse-upload'].split('.')
            params['file.gitlab-workhorse-upload'] = [header, crafted_payload, sig].join('.')
          end
        end

        it 'raises an error' do
          expect { subject }.to raise_error(JWT::VerificationError, 'Signature verification raised')
        end
      end

      context 'with a modified JWT sig' do
        include_context 'with one temporary file for multipart'

        let(:rewritten_fields) { rewritten_fields_hash('file' => uploaded_filepath) }
        let(:params) do
          upload_parameters_for(filepath: uploaded_filepath, key: 'file', filename: filename, remote_id: remote_id).tap do |params|
            header, payload, sig = params['file.gitlab-workhorse-upload'].split('.')
            params['file.gitlab-workhorse-upload'] = [header, payload, "#{sig}modified"].join('.')
          end
        end

        it 'raises an error' do
          expect { subject }.to raise_error(JWT::VerificationError, 'Signature verification raised')
        end
      end
    end
  end
end
