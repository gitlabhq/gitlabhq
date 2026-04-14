# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::APIAuthentication::TokenLocator, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:ci_job) { create(:ci_build, project: project, user: user, status: :running) }
  let_it_be(:ci_job_done) { create(:ci_build, project: project, user: user, status: :success) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }

  describe '.new' do
    context 'with a valid type' do
      it 'creates a new instance' do
        expect(described_class.new(:http_basic_auth)).to be_a(described_class)
      end
    end

    context 'with an invalid type' do
      it 'raises ActiveModel::ValidationError' do
        expect { described_class.new(:not_a_real_locator) }.to raise_error(ActiveModel::ValidationError)
      end
    end
  end

  describe '#extract' do
    let(:locator) { described_class.new(type) }

    subject { locator.extract(request) }

    context 'with :http_basic_auth' do
      let(:type) { :http_basic_auth }

      context 'without credentials' do
        let(:request) { double(authorization: nil) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with basic auth credentials' do
        let(:username) { 'foo' }
        let(:password) { 'bar' }
        let(:request) { double(authorization: "Basic #{::Base64.strict_encode64("#{username}:#{password}")}") }

        it 'returns the credentials' do
          expect(subject.username).to eq(username)
          expect(subject.password).to eq(password)
        end
      end

      context 'with bearer auth credentials' do
        context 'with a plain token' do
          let(:request) { double(authorization: "Bearer foo") }

          it 'returns nil' do
            expect(subject).to be_nil
          end
        end

        context 'when the token decodes to a string containing a colon' do
          let(:request) { double(authorization: "Bearer e68d6f1ee0a8da27bb71b2ddb54700aeb07546f58c06a3") }

          it 'does not misidentify it as basic auth credentials' do
            expect(subject).to be_nil
          end
        end
      end
    end

    context 'with :http_token' do
      let(:type) { :http_token }

      context 'without credentials' do
        let(:request) { double(headers: {}) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with credentials' do
        let(:password) { 'bar' }
        let(:request) { double(headers: { "Authorization" => password }) }

        it 'returns the credentials' do
          expect(subject.password).to eq(password)
        end
      end
    end

    context 'with :http_bearer_token' do
      let(:type) { :http_bearer_token }

      context 'without credentials' do
        let(:request) { double(headers: {}) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with credentials' do
        where(:description, :authorization_header, :expected_password) do
          'Bearer credentials'             | "Bearer bar"                                     | 'bar'
          'case-insensitive Bearer scheme' | "bearer bar"                                     | 'bar'
          'Bearer with no token'           | "Bearer"                                         | nil
          'Bearer with space and no token' | "Bearer "                                        | nil
          'Basic auth credentials'         | "Basic #{::Base64.strict_encode64('user:pass')}" | nil
          'Token credentials'              | "Token sometoken"                                | nil
          'empty authorization header'     | ""                                               | nil
        end

        with_them do
          let(:request) { double(headers: { "Authorization" => authorization_header }) }

          it "returns the expected result for #{params[:description]}" do
            if expected_password
              expect(subject.password).to eq(expected_password)
            else
              expect(subject).to be_nil
            end
          end
        end
      end
    end

    context 'with :http_deploy_token_header' do
      let(:type) { :http_deploy_token_header }

      context 'without credentials' do
        let(:request) { double(headers: {}) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with credentials' do
        let(:password) { 'bar' }
        let(:request) { double(headers: { 'Deploy-Token' => password }) }

        it 'returns the credentials' do
          expect(subject.password).to eq(password)
        end
      end
    end

    context 'with :http_job_token_header' do
      let(:type) { :http_job_token_header }

      context 'without credentials' do
        let(:request) { double(headers: {}) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with credentials' do
        let(:password) { 'bar' }
        let(:request) { double(headers: { 'Job-Token' => password }) }

        it 'returns the credentials' do
          expect(subject.password).to eq(password)
        end
      end
    end

    context 'with :http_private_token_header' do
      let(:type) { :http_private_token_header }

      context 'without credentials' do
        let(:request) { double(headers: {}) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with credentials' do
        let(:password) { 'bar' }
        let(:request) { double(headers: { 'Private-Token' => password }) }

        it 'returns the credentials' do
          expect(subject.password).to eq(password)
        end
      end
    end

    context 'with :http_header' do
      let(:type) { { http_header: 'Api-Key' } }

      context 'without credentials' do
        let(:request) { double(headers: {}) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with credentials' do
        let(:password) { 'bar' }
        let(:request) { double(headers: { 'Api-Key' => password }) }

        it 'returns the credentials' do
          expect(subject.password).to eq(password)
        end
      end
    end

    %i[
      token
      private_token
      job_token
      access_token
    ].each do |token_type|
      context "with :#{token_type}_param" do
        let(:type) { :"#{token_type}_param" }

        context 'without credentials' do
          let(:request) { double(query_parameters: {}) }

          it 'returns nil' do
            expect(subject).to be_nil
          end
        end

        context 'with credentials' do
          let(:password) { 'bar' }
          let(:request) { double(query_parameters: { token_type.to_s => password }) }

          it 'returns the credentials' do
            expect(subject.password).to eq(password)
          end
        end
      end
    end
  end
end
