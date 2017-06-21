require 'spec_helper'

describe Gitlab::PerformanceBar do
  describe '.enabled?' do
    it 'returns false when given user is nil' do
      expect(described_class.enabled?(nil)).to be_falsy
    end

    it 'returns false when feature is disabled' do
      user = double('user')

      expect(Feature).to receive(:enabled?)
        .with(:gitlab_performance_bar, user).and_return(false)

      expect(described_class.enabled?(user)).to be_falsy
    end

    it 'returns true when feature is enabled' do
      user = double('user')

      expect(Feature).to receive(:enabled?)
        .with(:gitlab_performance_bar, user).and_return(true)

      expect(described_class.enabled?(user)).to be_truthy
    end
  end

  describe '.allowed_actor?' do
    it 'returns false when given actor is not a User' do
      actor = double

      expect(described_class.allowed_actor?(actor)).to be_falsy
    end

    context 'when given actor is a User' do
      let(:actor) { create(:user) }

      before do
        stub_performance_bar_setting(allowed_group: 'my-group')
      end

      context 'when allowed group does not exist' do
        it 'returns false' do
          expect(described_class.allowed_actor?(actor)).to be_falsy
        end
      end

      context 'when allowed group exists' do
        let!(:my_group) { create(:group, path: 'my-group') }

        context 'when user is not a member of the allowed group' do
          it 'returns false' do
            expect(described_class.allowed_actor?(actor)).to be_falsy
          end
        end

        context 'when user is a member of the allowed group' do
          before do
            my_group.add_developer(actor)
          end

          it 'returns true' do
            expect(described_class.allowed_actor?(actor)).to be_truthy
          end
        end
      end
    end
  end

  describe '.allowed_group' do
    before do
      stub_performance_bar_setting(allowed_group: 'my-group')
    end

    context 'when allowed group does not exist' do
      it 'returns false' do
        expect(described_class.allowed_group).to be_falsy
      end
    end

    context 'when allowed group exists' do
      let!(:my_group) { create(:group, path: 'my-group') }

      context 'when user is not a member of the allowed group' do
        it 'returns false' do
          expect(described_class.allowed_group).to eq(my_group)
        end
      end
    end
  end
end
