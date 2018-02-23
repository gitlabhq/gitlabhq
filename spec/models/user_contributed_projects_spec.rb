require 'spec_helper'

describe UserContributedProjects do

  describe '.track' do
    subject { described_class.track(event) }
    let(:event) { build(:event) }

    Event::ACTIONS.each do |action|
      context "for all actions (event types)" do
        let(:event) { build(:event, action: action) }
        it 'creates a record' do
          expect { subject }.to change { UserContributedProjects.count }.from(0).to(1)
        end
      end
    end

    it 'sets project accordingly' do
      subject
      expect(UserContributedProjects.first.project).to eq(event.project)
    end

    it 'sets user accordingly' do
      subject
      expect(UserContributedProjects.first.user).to eq(event.author)
    end

    it 'only creates a record once per user/project' do
      expect do
        subject
        described_class.track(event)
      end.to change { UserContributedProjects.count }.from(0).to(1)
    end

    describe 'with an event without a project' do
      let(:event) { build(:event, project: nil) }

      it 'ignores the event' do
        expect { subject }.not_to change { UserContributedProjects.count }
      end
    end
  end

  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:user) }
end
