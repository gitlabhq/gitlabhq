# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::APIAuthentication::Builder do
  describe '#build' do
    shared_examples 'builds the correct result' do |token_type:, sent_through:, builds:|
      context "with #{token_type.size} token type(s) and #{sent_through.size} sent through(s)" do
        it 'works when passed together' do
          strategies = described_class.new.build { |allow| allow.token_types(*token_type).sent_through(*sent_through) }

          expect(strategies).to eq(builds)
        end

        it 'works when token types are passed separately' do
          strategies = described_class.new.build { |allow| token_type.each { |t| allow.token_types(t).sent_through(*sent_through) } }

          expect(strategies).to eq(builds)
        end

        it 'works when sent throughs are passed separately' do
          strategies = described_class.new.build { |allow| sent_through.each { |s| allow.token_types(*token_type).sent_through(s) } }

          expect(strategies).to eq(builds)
        end

        it 'works when token types and sent throughs are passed separately' do
          strategies = described_class.new.build { |allow| token_type.each { |t| sent_through.each { |s| allow.token_types(t).sent_through(s) } } }

          expect(strategies).to eq(builds)
        end
      end
    end

    it_behaves_like 'builds the correct result',
      token_type: [:pat],
      sent_through: [:basic],
      builds: { basic: [:pat] }

    it_behaves_like 'builds the correct result',
      token_type: [:pat],
      sent_through: [:basic, :oauth],
      builds: { basic: [:pat], oauth: [:pat] }

    it_behaves_like 'builds the correct result',
      token_type: [:pat, :job],
      sent_through: [:basic],
      builds: { basic: [:pat, :job] }

    it_behaves_like 'builds the correct result',
      token_type: [:pat, :job],
      sent_through: [:basic, :oauth],
      builds: { basic: [:pat, :job], oauth: [:pat, :job] }

    context 'with a complex auth strategy' do
      it 'builds the correct result' do
        strategies = described_class.new.build do |allow|
          allow.token_types(:pat, :job, :deploy).sent_through(:http_basic, :oauth)
          allow.token_types(:pat).sent_through(:http_private, :query_private)
          allow.token_types(:oauth2).sent_through(:http_bearer, :query_access)
        end

        expect(strategies).to eq({
          http_basic: [:pat, :job, :deploy],
          oauth: [:pat, :job, :deploy],

          http_private: [:pat],
          query_private: [:pat],

          http_bearer: [:oauth2],
          query_access: [:oauth2]
        })
      end
    end
  end
end
