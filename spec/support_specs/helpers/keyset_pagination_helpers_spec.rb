# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KeysetPaginationHelpers, feature_category: :api do
  include described_class

  let(:headers) { { 'LINK' => %(<#{url}>; rel="#{rel}") } }
  let(:response) { instance_double('HTTParty::Response', headers: headers) }
  let(:rel) { 'next' }
  let(:url) do
    'http://127.0.0.1:3000/api/v4/projects/7/audit_eve' \
      'nts?cursor=eyJpZCI6IjYyMjAiLCJfa2QiOiJuIn0%3D&id=7&o' \
      'rder_by=id&page=1&pagination=keyset&per_page=2'
  end

  describe '#pagination_links' do
    subject { pagination_links(response) }

    let(:expected_result) { [{ url: url, rel: rel }] }

    it { is_expected.to eq expected_result }

    context 'with a partially malformed LINK header' do
      # malformed as the regxe is expecting the url to be surrounded by `<>`
      let(:headers) do
        { 'LINK' => %(<#{url}>; rel="next", GARBAGE, #{url}; rel="prev") }
      end

      it { is_expected.to eq expected_result }
    end

    context 'with a malformed LINK header' do
      # malformed as the regxe is expecting the url to be surrounded by `<>`
      let(:headers) { { 'LINK' => %(rel="next", GARBAGE, #{url}; rel="prev") } }
      let(:expected_result) { [] }

      it { is_expected.to eq expected_result }
    end
  end

  describe '#pagination_params_from_next_url' do
    subject { pagination_params_from_next_url(response) }

    let(:expected_result) do
      {
        'cursor' => 'eyJpZCI6IjYyMjAiLCJfa2QiOiJuIn0=',
        'id' => '7',
        'order_by' => 'id',
        'page' => '1',
        'pagination' => 'keyset',
        'per_page' => '2'
      }
    end

    it { is_expected.to eq expected_result }

    context 'with both prev and next rel links' do
      let(:prev_url) do
        'http://127.0.0.1:3000/api/v4/projects/7/audit_eve' \
          'nts?cursor=foocursor&id=8&o' \
          'rder_by=id&page=0&pagination=keyset&per_page=2'
      end

      let(:headers) do
        { 'LINK' => %(<#{url}>; rel="next", <#{prev_url}>; rel="prev") }
      end

      it { is_expected.to eq expected_result }
    end

    context 'with a partially malformed LINK header' do
      # malformed as the regxe is expecting the url to be surrounded by `<>`
      let(:headers) do
        { 'LINK' => %(<#{url}>; rel="next", GARBAGE, #{url}; rel="prev") }
      end

      it { is_expected.to eq expected_result }
    end

    context 'with a malformed LINK header' do
      # malformed as the regxe is expecting the url to be surrounded by `<>`
      let(:headers) { { 'LINK' => %(rel="next", GARBAGE, #{url}; rel="prev") } }

      it { is_expected.to be nil }
    end
  end
end
