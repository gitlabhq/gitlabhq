# frozen_string_literal: true
require 'spec_helper'

describe Milestones::UpdateService do
  let(:project) { create(:project) }
  let(:user) { build(:user) }
  let(:milestone) { create(:milestone, project: project) }

  describe '#execute' do
    context "valid params" do
      let(:inner_service) { double(:service) }

      before do
        project.add_maintainer(user)
      end

      subject { described_class.new(project, user, { title: 'new_title' }).execute(milestone) }

      it { expect(subject).to be_valid }
      it { expect(subject.title).to eq('new_title') }

      context 'state_event is activate' do
        it 'calls ReopenService' do
          expect(Milestones::ReopenService).to receive(:new).with(project, user, {}).and_return(inner_service)
          expect(inner_service).to receive(:execute).with(milestone)

          described_class.new(project, user, { state_event: 'activate' }).execute(milestone)
        end
      end

      context 'state_event is close' do
        it 'calls ReopenService' do
          expect(Milestones::CloseService).to receive(:new).with(project, user, {}).and_return(inner_service)
          expect(inner_service).to receive(:execute).with(milestone)

          described_class.new(project, user, { state_event: 'close' }).execute(milestone)
        end
      end
    end
  end
end
