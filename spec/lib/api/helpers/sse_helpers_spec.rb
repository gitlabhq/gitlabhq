# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::SSEHelpers do
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }

  subject { Class.new.include(described_class).new }

  describe '#request_from_sse?' do
    before do
      allow(subject).to receive(:request).and_return(request)
    end

    context 'when referer is nil' do
      let(:request) { double(referer: nil)}

      it 'returns false' do
        expect(URI).not_to receive(:parse)
        expect(subject.request_from_sse?(project)).to eq false
      end
    end

    context 'when referer is not from SSE' do
      let(:request) { double(referer: 'https://gitlab.com')}

      it 'returns false' do
        expect(URI).to receive(:parse).and_call_original
        expect(subject.request_from_sse?(project)).to eq false
      end
    end

    context 'when referer is from SSE' do
      let(:request) { double(referer: project_show_sse_path(project, 'master/README.md'))}

      it 'returns true' do
        expect(URI).to receive(:parse).and_call_original
        expect(subject.request_from_sse?(project)).to eq true
      end
    end
  end
end
