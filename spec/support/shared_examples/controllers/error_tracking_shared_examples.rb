# frozen_string_literal: true

RSpec.shared_examples 'sets the polling header' do
  subject { response.headers[Gitlab::PollingInterval::HEADER_NAME] }

  it { is_expected.to eq '1000' }
end
