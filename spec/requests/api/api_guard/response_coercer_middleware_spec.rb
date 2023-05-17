# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::APIGuard::ResponseCoercerMiddleware, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  it 'is loaded' do
    expect(API::API.middleware).to include([:use, described_class])
  end

  describe '#call' do
    let(:app) do
      Class.new(API::API)
    end

    [
      nil, 201, 10.5, "test"
    ].each do |val|
      it 'returns a String body' do
        app.get 'bodytest' do
          status 200
          env['api.format'] = :binary
          body val
        end

        unless val.is_a?(String)
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(instance_of(ArgumentError))
        end

        get api('/bodytest')

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(val.to_s)
      end
    end

    [100, 204, 304].each do |status|
      it 'allows nil body' do
        app.get 'statustest' do
          status status
          env['api.format'] = :binary
          body nil
        end

        expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

        get api('/statustest')

        expect(response.status).to eq(status)
        expect(response.body).to eq('')
      end
    end
  end
end
