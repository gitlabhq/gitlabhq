require 'rails_helper'

describe 'projects/diffs/_content' do
  context 'unsupported blobs' do
    it 'renders nothing' do
      allow(view).to receive(:blob).and_return(double)

      expect(rendered).to eq ''
    end
  end

  context 'supported blobs' do
    def stub_blob(overrides = {})
      messages = overrides.reverse_merge(text?: true)

      allow(view).to receive(:blob).and_return(double(messages))
    end

    context 'diff is too large' do
      it 'displays the correct message' do
        stub_blob
        allow(view).to receive(:diff_file).and_return(double(too_large?: true))

        render

        expect(rendered)
          .to include("This diff could not be displayed because it is too large.")
      end
    end

    context 'blob is too large' do
      it 'displays the correct message' do
        stub_blob(only_display_raw?: true)
        allow(view).to receive(:diff_file).and_return(double(too_large?: false))

        render

        expect(rendered)
          .to include("This file is too large to display.")
      end
    end

    context 'blob text viewable' do
      before do
        allow(view).to receive(:blob_text_viewable?).and_return(true)
      end
    end

    context 'blob text unviewable'
  end
end
