# frozen_string_literal: true

require 'spec_helper'

describe UserInteractedProject do
  describe '.track' do
    subject { described_class.track(event) }

    let(:event) { build(:event) }

    Event.actions.each_key do |action|
      context "for all actions (event types)" do
        let(:event) { build(:event, action: action) }

        it 'creates a record' do
          expect { subject }.to change { described_class.count }.from(0).to(1)
        end
      end
    end

    it 'sets project accordingly' do
      subject
      expect(described_class.first.project).to eq(event.project)
    end

    it 'sets user accordingly' do
      subject
      expect(described_class.first.user).to eq(event.author)
    end

    it 'only creates a record once per user/project' do
      expect do
        subject
        described_class.track(event)
      end.to change { described_class.count }.from(0).to(1)
    end

    describe 'with an event without a project' do
      let(:event) { build(:event, project: nil) }

      it 'ignores the event' do
        expect { subject }.not_to change { described_class.count }
      end
    end
  end

  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_presence_of(:user_id) }
end
