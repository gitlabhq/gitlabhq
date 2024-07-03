# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Helpers::Packages::Conan, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, namespace: group) }

  let(:params) { {} }
  let(:object) { klass.new(params) }
  let(:klass) do
    Struct.new(:params) do
      include ::API::Helpers
      include ::API::Helpers::Packages::Conan::ApiHelpers
    end
  end

  before do
    allow(object).to receive(:current_user).and_return(user)
    allow(object).to receive(:bad_request!).and_raise(StandardError.new('bad request'))
  end

  describe '#file_names' do
    let(:file_names) { object.file_names }

    context 'when the request body is valid JSON' do
      let(:request_body) { { 'file1' => 100, 'file2' => 100 }.to_json }

      before do
        allow(object).to receive_message_chain(:request, :body, :read).and_return(request_body)
      end

      it 'returns the keys of the JSON payload' do
        expect(file_names).to eq(%w[file1 file2])
      end
    end

    context 'when the request body is invalid JSON' do
      let(:invalid_request_body) { 'invalid_json' }

      before do
        allow(object).to receive_message_chain(:request, :body, :read).and_return(invalid_request_body)
      end

      it 'returns nil' do
        expect(file_names).to be_nil
      end
    end

    context 'when the request body raises Encoding::UndefinedConversionError' do
      before do
        allow(object).to receive_message_chain(:request, :body, :read).and_raise(Encoding::UndefinedConversionError)
      end

      it 'returns nil' do
        expect(file_names).to be_nil
      end
    end

    context 'when the request body raises Encoding::InvalidByteSequenceError' do
      before do
        allow(object).to receive_message_chain(:request, :body, :read).and_raise(Encoding::InvalidByteSequenceError)
      end

      it 'returns nil' do
        expect(file_names).to be_nil
      end
    end

    context 'when the request body raises Encoding::CompatibilityError' do
      before do
        allow(object).to receive_message_chain(:request, :body, :read).and_raise(Encoding::CompatibilityError)
      end

      it 'returns nil' do
        expect(file_names).to be_nil
      end
    end

    context 'when the request body raises StandardError' do
      let(:standard_error) { StandardError.new('some error') }

      before do
        allow(object).to receive_message_chain(:request, :body, :read).and_raise(standard_error)
      end

      it 'tracks the exception and raises bad_request!' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(standard_error)
        expect { file_names }.to raise_error(StandardError, 'bad request')
      end
    end
  end
end
