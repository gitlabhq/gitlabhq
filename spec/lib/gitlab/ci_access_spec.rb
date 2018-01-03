require 'spec_helper'

describe Gitlab::CiAccess do
  let(:access) { described_class.new }

  describe '#can_do_action?' do
    context 'when action is :build_download_code' do
      it { expect(access.can_do_action?(:build_download_code)).to be_truthy }
    end

    context 'when action is not :build_download_code' do
      it { expect(access.can_do_action?(:download_code)).to be_falsey }
    end
  end
end
