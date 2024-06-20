# frozen_string_literal: true

RSpec.shared_examples 'protected ref access allowed_access_levels' do |excludes: []|
  describe '::allowed_access_levels' do
    subject { described_class.allowed_access_levels }

    let(:all_levels) do
      [
        Gitlab::Access::DEVELOPER,
        Gitlab::Access::MAINTAINER,
        Gitlab::Access::ADMIN,
        Gitlab::Access::NO_ACCESS
      ]
    end

    context 'when running on Gitlab.com?' do
      let(:levels) { all_levels.excluding(Gitlab::Access::ADMIN, *excludes) }

      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it { is_expected.to match_array(levels) }
    end

    context 'when self hosted?' do
      let(:levels) { all_levels.excluding(*excludes) }

      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to match_array(levels) }
    end
  end
end
