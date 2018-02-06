require 'rails_helper'

describe WebHookLog do
  it { is_expected.to belong_to(:web_hook) }

  it { is_expected.to serialize(:request_headers).as(Hash) }
  it { is_expected.to serialize(:request_data).as(Hash) }
  it { is_expected.to serialize(:response_headers).as(Hash) }

  it { is_expected.to validate_presence_of(:web_hook) }

  describe '#success?' do
    let(:web_hook_log) { build(:web_hook_log, response_status: status) }

    describe '2xx' do
      let(:status) { '200' }
      it { expect(web_hook_log.success?).to be_truthy }
    end

    describe 'not 2xx' do
      let(:status) { '500' }
      it { expect(web_hook_log.success?).to be_falsey }
    end

    describe 'internal erorr' do
      let(:status) { 'internal error' }
      it { expect(web_hook_log.success?).to be_falsey }
    end
  end
end
