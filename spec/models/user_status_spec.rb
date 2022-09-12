# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserStatus do
  it { is_expected.to validate_presence_of(:user) }

  it { is_expected.to allow_value('smirk').for(:emoji) }
  it { is_expected.not_to allow_value('hello world').for(:emoji) }
  it { is_expected.not_to allow_value('').for(:emoji) }

  it { is_expected.to validate_length_of(:message).is_at_most(100) }
  it { is_expected.to allow_value('').for(:message) }

  it 'is expected to be deleted when the user is deleted' do
    status = create(:user_status)

    expect { status.user.destroy! }.to change { described_class.count }.from(1).to(0)
  end

  describe '#clear_status_after' do
    it 'is an alias of #clear_status_at', :freeze_time do
      status = build(:user_status, clear_status_at: 8.hours.from_now)

      expect(status.clear_status_after).to be_like_time(8.hours.from_now)
    end
  end

  describe '#clear_status_after=' do
    it 'sets clear_status_at' do
      status = build(:user_status)

      freeze_time do
        status.clear_status_after = '8_hours'

        expect(status.clear_status_at).to be_like_time(8.hours.from_now)
      end
    end

    it 'unsets clear_status_at' do
      status = build(:user_status, clear_status_at: 8.hours.from_now)

      status.clear_status_after = nil

      expect(status.clear_status_at).to be_nil
    end

    context 'when unknown clear status is given' do
      it 'unsets clear_status_at' do
        status = build(:user_status, clear_status_at: 8.hours.from_now)

        status.clear_status_after = 'unknown'

        expect(status.clear_status_at).to be_nil
      end
    end
  end

  describe '#customized?' do
    it 'is customized when message text is present' do
      subject.message = 'My custom status'

      expect(subject).to be_customized
    end

    it 'is not customized when message text is absent' do
      subject.message = nil

      expect(subject).not_to be_customized
    end

    it 'is customized without message but with custom emoji' do
      subject.emoji = 'bow'

      expect(subject).to be_customized
    end

    it 'is not customized without message but with default custom emoji' do
      subject.emoji = 'speech_balloon'

      expect(subject).not_to be_customized
    end
  end
end
