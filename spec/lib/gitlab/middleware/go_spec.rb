require 'spec_helper'

describe Gitlab::Middleware::Go, lib: true do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    describe 'when go-get=0' do
      it 'skips go-import generation' do
        env = { 'rack.input' => '',
                'QUERY_STRING' => 'go-get=0' }
        expect(app).to receive(:call).with(env).and_return('no-go')
        middleware.call(env)
      end
    end

    describe 'when go-get=1' do
      it 'returns a document' do
        env = { 'rack.input' => '',
                'QUERY_STRING' => 'go-get=1',
                'PATH_INFO' => '/group/project/path' }
        resp = middleware.call(env)
        expect(resp[0]).to eq(200)
        expect(resp[1]['Content-Type']).to eq('text/html')
        expected_body = "<!DOCTYPE html><html><head><meta content='localhost/group/project git http://localhost/group/project.git' name='go-import'></head></html>\n"
        expect(resp[2].body).to eq([expected_body])
      end
    end
  end
end
