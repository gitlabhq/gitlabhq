require 'spec_helper'

describe Gitlab::CrossProjectAccess::CheckInfo do
  let(:dummy_controller) { double }

  before do
    allow(dummy_controller).to receive(:action_name).and_return('index')
  end

  describe '#should_run?' do
    it 'runs when an action is defined' do
      info = described_class.new({ index: true }, nil, nil, false)

      expect(info.should_run?(dummy_controller)).to be_truthy
    end

    it 'runs when the action is missing' do
      info = described_class.new({}, nil, nil, false)

      expect(info.should_run?(dummy_controller)).to be_truthy
    end

    it 'does not run when the action is excluded' do
      info = described_class.new({ index: false }, nil, nil, false)

      expect(info.should_run?(dummy_controller)).to be_falsy
    end

    it 'runs when the `if` conditional is true' do
      info = described_class.new({}, -> { true }, nil, false)

      expect(info.should_run?(dummy_controller)).to be_truthy
    end

    it 'does not run when the if condition is false' do
      info = described_class.new({}, -> { false }, nil, false)

      expect(info.should_run?(dummy_controller)).to be_falsy
    end

    it 'does not run when the `unless` check is true' do
      info = described_class.new({}, nil, -> { true }, false)

      expect(info.should_run?(dummy_controller)).to be_falsy
    end

    it 'runs when the `unless` check is false' do
      info = described_class.new({}, nil, -> { false }, false)

      expect(info.should_run?(dummy_controller)).to be_truthy
    end

    it 'returns the the oposite of #should_skip? when the check is a skip' do
      info = described_class.new({}, nil, nil, true)

      expect(info).to receive(:should_skip?).with(dummy_controller).and_return(false)
      expect(info.should_run?(dummy_controller)).to be_truthy
    end
  end

  describe '#should_skip?' do
    it 'skips when an action is defined' do
      info = described_class.new({ index: true }, nil, nil, true)

      expect(info.should_skip?(dummy_controller)).to be_truthy
    end

    it 'does not skip when the action is not defined' do
      info = described_class.new({}, nil, nil, true)

      expect(info.should_skip?(dummy_controller)).to be_falsy
    end

    it 'does not skip when the action is excluded' do
      info = described_class.new({ index: false }, nil, nil, true)

      expect(info.should_skip?(dummy_controller)).to be_falsy
    end

    it 'skips when the `if` conditional is true' do
      info = described_class.new({ index: true }, -> { true }, nil, true)

      expect(info.should_skip?(dummy_controller)).to be_truthy
    end

    it 'does not skip the `if` conditional is false' do
      info = described_class.new({ index: true }, -> { false }, nil, true)

      expect(info.should_skip?(dummy_controller)).to be_falsy
    end

    it 'does not skip when the `unless` check is true' do
      info = described_class.new({ index: true }, nil, -> { true }, true)

      expect(info.should_skip?(dummy_controller)).to be_falsy
    end

    it 'skips when `unless` check is false' do
      info = described_class.new({ index: true }, nil, -> { false }, true)

      expect(info.should_skip?(dummy_controller)).to be_truthy
    end

    it 'returns the the oposite of #should_run? when the check is not a skip' do
      info = described_class.new({}, nil, nil, false)

      expect(info).to receive(:should_run?).with(dummy_controller).and_return(false)
      expect(info.should_skip?(dummy_controller)).to be_truthy
    end
  end
end
