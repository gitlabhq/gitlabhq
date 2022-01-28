# frozen_string_literal: true

RSpec.shared_examples 'clusterable policies' do
  describe '#add_cluster?' do
    let(:current_user) { create(:user) }

    subject { described_class.new(current_user, clusterable) }

    context 'with a reporter' do
      before do
        clusterable.add_reporter(current_user)
      end

      it { expect_disallowed(:read_cluster) }
      it { expect_disallowed(:add_cluster) }
      it { expect_disallowed(:create_cluster) }
      it { expect_disallowed(:update_cluster) }
      it { expect_disallowed(:admin_cluster) }
    end

    context 'with a developer' do
      before do
        clusterable.add_developer(current_user)
      end

      it { expect_allowed(:read_cluster) }
      it { expect_disallowed(:add_cluster) }
      it { expect_disallowed(:create_cluster) }
      it { expect_disallowed(:update_cluster) }
      it { expect_disallowed(:admin_cluster) }
    end

    context 'with a maintainer' do
      before do
        clusterable.add_maintainer(current_user)
      end

      context 'with no clusters' do
        it { expect_allowed(:read_cluster) }
        it { expect_allowed(:add_cluster) }
        it { expect_allowed(:create_cluster) }
        it { expect_allowed(:update_cluster) }
        it { expect_allowed(:admin_cluster) }
      end
    end
  end
end
