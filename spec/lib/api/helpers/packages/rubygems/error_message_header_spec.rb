# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Packages::Rubygems::ErrorMessageHeader, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let(:base_helper_module) do
    Module.new do
      attr_reader :fallback_args

      def render_structured_api_error!(hash, status)
        @fallback_args = { hash: hash, status: status }
      end

      def header
        @header ||= {}
      end
    end
  end

  let(:helper_class) do
    base = base_helper_module
    Class.new do
      include base
      include API::Helpers::Packages::Rubygems::ErrorMessageHeader
    end
  end

  let(:helper) { helper_class.new }

  describe '#render_structured_api_error!' do
    subject(:render_error) { helper.render_structured_api_error!({ 'message' => message }, status) }

    where(:message, :status, :expected_header) do
      '403 Forbidden - Package protected.'  | :forbidden     | 'Package protected.'
      '400 Bad request - File is too large' | :bad_request   | 'File is too large'
      'forbidden'                           | :forbidden     | 'forbidden'
      'mygem not found'                     | :not_found     | 'mygem not found'
      "with\r\nnewline"                     | :bad_request   | 'with  newline'
      '403 Forbidden'                       | :forbidden     | nil
      '404 Not Found'                       | :not_found     | nil
      '401 Unauthorized'                    | :unauthorized  | nil
      '201 Created'                         | :created       | nil
      nil                                   | :bad_request   | nil
      ''                                    | :bad_request   | nil
    end

    with_them do
      before do
        render_error
      end

      it 'sets the X-Error-Message header only when a meaningful detail exists' do
        if expected_header
          expect(helper.header['X-Error-Message']).to eq(expected_header)
        else
          expect(helper.header).not_to have_key('X-Error-Message')
        end
      end

      it 'forwards the unchanged hash and status through super' do
        expect(helper.fallback_args).to eq(hash: { 'message' => message }, status: status)
      end
    end

    context 'when the feature flag is disabled' do
      let(:message) { '403 Forbidden - Package protected.' }
      let(:status) { :forbidden }

      before do
        stub_feature_flags(rubygems_error_message_header: false)
      end

      it 'does not set the header and calls super with the unchanged hash', :aggregate_failures do
        render_error

        expect(helper.header).not_to have_key('X-Error-Message')
        expect(helper.fallback_args).to eq(hash: { 'message' => message }, status: status)
      end
    end
  end
end
