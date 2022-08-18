# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Middleware::SidekiqWebStatic do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }

  describe '#call' do
    before do
      env['HTTP_X_SENDFILE_TYPE'] = 'X-Sendfile'
      env['PATH_INFO'] = path
    end

    context 'with an /admin/sidekiq route' do
      let(:path) { '/admin/sidekiq/javascripts/application.js' }

      it 'deletes the HTTP_X_SENDFILE_TYPE header' do
        expect(app).to receive(:call)

        middleware.call(env)

        expect(env['HTTP_X_SENDFILE_TYPE']).to be_nil
      end
    end

    context 'with some static asset route' do
      let(:path) { '/assets/test.png' }

      it 'keeps the HTTP_X_SENDFILE_TYPE header' do
        expect(app).to receive(:call)

        middleware.call(env)

        expect(env['HTTP_X_SENDFILE_TYPE']).to eq('X-Sendfile')
      end
    end
  end
end
