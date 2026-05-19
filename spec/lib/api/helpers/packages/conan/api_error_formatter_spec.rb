# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Helpers::Packages::Conan::ApiErrorFormatter, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let(:object) { klass.new }
  let(:klass) do
    Class.new do
      include ::API::Helpers
      include ::API::Helpers::Packages::Conan::ApiErrorFormatter
    end
  end

  before do
    allow(object).to receive_messages(env: {}, header: {})
    allow(object).to receive(:error!).and_raise(Grape::Exceptions::Base.new(status: 500))
  end

  describe '#render_structured_api_error!' do
    where(:message, :status, :message_key, :expected_message) do
      '403 Forbidden - Package protected.' | 403        | 'message' | 'Forbidden - Package protected.'
      '401 Unauthorized'                   | 401        | 'message' | 'Unauthorized'
      '404 Package Not Found'              | 404        | 'message' | 'Package Not Found'
      '404 Package Not Found'              | :not_found | 'message' | 'Package Not Found'
      '400 Bad request'                    | 400        | :message  | 'Bad request'
      nil                                  | 400        | 'message' | ''
    end

    with_them do
      let(:hash) { { message_key => message } }
      let(:status_code) { Rack::Utils.status_code(status) }

      it 'adds the errors key with the status prefix stripped from the message' do
        expected_body = hash.with_indifferent_access.merge(
          'errors' => [{ 'status' => status_code, 'message' => expected_message }]
        )

        expect(object).to receive(:error!).with(expected_body, anything, {})

        expect { object.render_structured_api_error!(hash, status) }.to raise_error(Grape::Exceptions::Base)
      end
    end

    context 'with a 2xx status code' do
      let(:hash) { { 'message' => 'success' } }

      it 'does not add the errors key' do
        expect(object).to receive(:error!).with(hash, anything, {})

        expect { object.render_structured_api_error!(hash, 200) }.to raise_error(Grape::Exceptions::Base)
      end
    end

    context 'when the feature flag is disabled' do
      let(:hash) { { 'message' => '403 Forbidden' } }

      before do
        stub_feature_flags(conan_structured_error_responses: false)
      end

      it 'does not add the errors key' do
        expect(object).to receive(:error!).with(hash, anything, {})

        expect { object.render_structured_api_error!(hash, 403) }.to raise_error(Grape::Exceptions::Base)
      end
    end
  end
end
