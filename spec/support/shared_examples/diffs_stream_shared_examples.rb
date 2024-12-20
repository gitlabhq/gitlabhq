# frozen_string_literal: true

RSpec.shared_examples 'diffs stream tests' do
  it 'streams the response' do
    go

    expect(response).to have_gitlab_http_status(:success)
  end

  context 'when offset is given' do
    context 'when offset is 1' do
      let(:offset) { 1 }

      it 'streams diffs except the offset' do
        go

        diff_files_array = diff_files.to_a
        expect(response.body).not_to include(diff_files_array.first.new_path)
        expect(response.body).to include(diff_files_array.last.new_path)
      end
    end

    context 'when offset is the same as the number of diffs' do
      let(:offset) { diff_files.size }

      it 'no diffs are streamed' do
        go

        expect(response.body).to be_empty
      end
    end
  end

  context 'when an exception occurs' do
    before do
      allow(::RapidDiffs::DiffFileComponent)
        .to receive(:new).and_raise(StandardError.new('something went wrong'))
    end

    it 'prints out error message' do
      go

      expect(response.body).to include('something went wrong')
    end
  end

  context 'when the rapid_diffs feature flag is disabled' do
    before do
      stub_feature_flags(rapid_diffs: false)
    end

    it 'returns a 404 status' do
      go

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
