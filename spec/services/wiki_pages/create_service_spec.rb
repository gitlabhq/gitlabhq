require 'spec_helper'

describe WikiPages::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:opts) do
    {
      title: 'Title',
      content: 'Content for wiki page',
      format: 'markdown'
    }
  end
  let(:service) { described_class.new(project, user, opts) }

  describe '#execute' do
    context "valid params" do
      before do
        allow(service).to receive(:execute_hooks)
        project.add_master(user)
      end

      subject { service.execute }

      it 'creates a valid wiki page' do
        is_expected.to be_valid
        expect(subject.title).to eq(opts[:title])
        expect(subject.content).to eq(opts[:content])
        expect(subject.format).to eq(opts[:format].to_sym)
      end

      it 'executes webhooks' do
        expect(service).to have_received(:execute_hooks).once.with(subject, 'create')
      end
    end
  end
end
