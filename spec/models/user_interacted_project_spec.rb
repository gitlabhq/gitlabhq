require 'spec_helper'

describe UserInteractedProject do
  describe '.track' do
    subject { described_class.track(event) }
    let(:event) { build(:event) }

    Event::ACTIONS.each do |action|
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

  describe '.available?' do
    before do
      described_class.instance_variable_set('@available_flag', nil)
    end

    it 'checks schema version and properly caches positive result' do
      expect(ActiveRecord::Migrator).to receive(:current_version).and_return(described_class::REQUIRED_SCHEMA_VERSION - 1 - rand(1000))
      expect(described_class.available?).to be_falsey
      expect(ActiveRecord::Migrator).to receive(:current_version).and_return(described_class::REQUIRED_SCHEMA_VERSION + rand(1000))
      expect(described_class.available?).to be_truthy
      expect(ActiveRecord::Migrator).not_to receive(:current_version)
      expect(described_class.available?).to be_truthy # cached response
    end
  end

  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_presence_of(:user_id) }
end
