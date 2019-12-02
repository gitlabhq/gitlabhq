# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/helpers/fixture_helpers'

describe Sentry::PaginationParser do
  include FixtureHelpers

  describe '.parse' do
    subject { described_class.parse(headers) }

    context 'when headers do not have "link" param' do
      let(:headers) { {} }

      it 'returns empty hash' do
        is_expected.to eq({})
      end
    end

    context 'when headers.link has previous and next pages' do
      let(:headers) do
        {
          'link' => '<https://sentrytest.gitlab.com>; rel="previous"; results="true"; cursor="1573556671000:0:1", <https://sentrytest.gitlab.com>; rel="next"; results="true"; cursor="1572959139000:0:0"'
        }
      end

      it 'returns info about both pages' do
        is_expected.to eq(
          'previous' => { 'cursor' => '1573556671000:0:1' },
          'next' => { 'cursor' => '1572959139000:0:0' }
        )
      end
    end

    context 'when headers.link has only next page' do
      let(:headers) do
        {
          'link' => '<https://sentrytest.gitlab.com>; rel="previous"; results="false"; cursor="1573556671000:0:1", <https://sentrytest.gitlab.com>; rel="next"; results="true"; cursor="1572959139000:0:0"'
        }
      end

      it 'returns only info about the next page' do
        is_expected.to eq(
          'next' => { 'cursor' => '1572959139000:0:0' }
        )
      end
    end

    context 'when headers.link has only previous page' do
      let(:headers) do
        {
          'link' => '<https://sentrytest.gitlab.com>; rel="previous"; results="true"; cursor="1573556671000:0:1", <https://sentrytest.gitlab.com>; rel="next"; results="false"; cursor="1572959139000:0:0"'
        }
      end

      it 'returns only info about the previous page' do
        is_expected.to eq(
          'previous' => { 'cursor' => '1573556671000:0:1' }
        )
      end
    end
  end
end
