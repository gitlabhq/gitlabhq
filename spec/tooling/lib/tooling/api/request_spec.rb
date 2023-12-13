# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/api/request'

require 'webmock/rspec'

RSpec.describe Tooling::API::Request, feature_category: :tooling do
  let(:base_url) { 'https://gitlab.com/api/v4/projects/project_id/pipelines/pipeline_id/jobs' }

  describe '.get' do
    let(:body) { 'body' }

    subject(:response) { described_class.get('api_token', URI(base_url)) }

    context 'when the response is successful' do
      before do
        stub_request(:get, base_url).to_return(status: 200, body: body)
      end

      it { expect(response.body).to eq(body) }
    end

    context 'when the response is not successful' do
      before do
        stub_request(:get, base_url).to_return(status: 500)
      end

      it { expect(response.body).to be_empty }
    end

    context 'when there are multiple pages' do
      let(:body1) { 'body1' }
      let(:body2) { 'body2' }

      before do
        stub_request(:get, base_url).to_return(
          status: 200, body: body1, headers: { 'Link' => %(<#{base_url}&page=2>; rel="next") }
        )
        stub_request(:get, "#{base_url}&page=2").to_return(status: 200, body: body2, headers: { 'Link' => '' })
      end

      it 'yields each page' do
        expected = [body1, body2]

        expected_yield = proc do |response|
          expect(response.body).to eq(expected.shift)
        end

        described_class.get('api_token', URI(base_url), &expected_yield)
      end
    end
  end
end
