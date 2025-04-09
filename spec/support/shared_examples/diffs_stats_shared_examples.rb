# frozen_string_literal: true

RSpec.shared_examples 'diffs stats' do
  it 'returns the correct diffs_stats' do
    send_request

    expect(json_response['diffs_stats']['added_lines']).to eq(expected_stats[:added_lines])
    expect(json_response['diffs_stats']['removed_lines']).to eq(expected_stats[:removed_lines])
    expect(json_response['diffs_stats']['diffs_count']).to eq(expected_stats[:diffs_count])
  end

  it 'returns a json response' do
    send_request

    expect(response).to have_gitlab_http_status(:success)
    expect(json_response['diffs_stats']).to be_an Hash
  end

  context 'when the rapid_diffs feature flag is disabled' do
    before do
      stub_feature_flags(rapid_diffs: false)
    end

    it 'returns a 404 status' do
      send_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'overflow' do
  let(:collapsed_safe_lines) { true }

  before do
    allow_next_instance_of(Gitlab::Git::DiffCollection) do |instance|
      allow(instance).to receive(:collapsed_safe_lines?).and_return(collapsed_safe_lines)
    end
  end

  context 'when diffs overflow' do
    it 'returns the correct overflow data' do
      send_request

      expect(json_response).to have_key('overflow')
      expect(json_response['overflow']['visible_count']).to eq(expected_stats[:visible_count])
      expect(json_response['overflow']['email_path']).to eq(expected_stats[:email_path])
      expect(json_response['overflow']['diff_path']).to eq(expected_stats[:diff_path])
    end
  end

  context 'when diffs do not overflow' do
    let(:collapsed_safe_lines) { false }

    it 'does not return overflow data' do
      send_request

      expect(json_response).not_to have_key('overflow')
    end
  end
end

RSpec.shared_examples 'missing diffs stats' do
  it 'returns a 404 status' do
    send_request

    expect(response).to have_gitlab_http_status(:not_found)
  end
end
