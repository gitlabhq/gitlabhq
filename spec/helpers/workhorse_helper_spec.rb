# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkhorseHelper, feature_category: :source_code_management do
  describe "#content_disposition_for_blob" do
    subject { helper.content_disposition_for_blob(blob, inline) }

    context 'when Content-Disposition is inline' do
      let(:inline) { true }

      context 'when blob is XHTML' do
        let(:blob) { instance_double(Gitlab::Git::Blob, name: 'test.xhtml.xhtml') }

        let(:content_disposition) do
          ActionDispatch::Http::ContentDisposition.format(disposition: 'inline', filename: 'test')
        end

        it { is_expected.to eq(content_disposition) }
      end

      context 'when blob is not XHTML' do
        let(:blob) { instance_double(Gitlab::Git::Blob, name: 'test.xml') }
        let(:content_disposition) { 'inline' }

        it { is_expected.to eq(content_disposition) }
      end
    end

    context 'when Content-Disposition is attachment' do
      let(:inline) { false }
      let(:blob) { instance_double(Gitlab::Git::Blob, name: 'test.pdf') }

      let(:content_disposition) do
        ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: 'test.pdf')
      end

      it { is_expected.to eq(content_disposition) }
    end
  end
end
