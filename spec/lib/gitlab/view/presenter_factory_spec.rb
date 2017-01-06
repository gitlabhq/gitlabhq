require 'spec_helper'

describe Gitlab::View::PresenterFactory do
  let(:appearance) { build(:appearance) }
  let(:broadcast_message) { build(:broadcast_message) }

  before do
    class AppearancePresenter
      include Gitlab::View::Presenter
    end

    class BroadcastMessagePresenter < SimpleDelegator
      include Gitlab::View::Presenter
    end
  end

  describe '#initialize' do
    subject do
      described_class.new(appearance)
    end

    it 'takes a subject and optional params' do
      expect { subject }.not_to raise_error
    end
  end

  describe '#fabricate!' do
    context 'without delegation' do
      subject do
        described_class.new(appearance).fabricate!
      end

      it 'does not forward missing methods to subject' do
        expect { subject.title }.to raise_error(NoMethodError)
      end
    end

    context 'with delegation' do
      subject do
        described_class.new(broadcast_message).fabricate!
      end

      it 'forwards missing methods to subject' do
        expect(subject.message).to eq(broadcast_message.message)
      end
    end
  end
end
