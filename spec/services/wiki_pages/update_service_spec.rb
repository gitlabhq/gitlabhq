require 'spec_helper'

describe WikiPages::UpdateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:wiki_page) { create(:wiki_page) }
  let(:opts) do
    {
      content: 'New content for wiki page',
      format: 'markdown',
      message: 'New wiki message'
    }
  end
  let(:service) { described_class.new(project, user, opts) }

  describe '#execute' do
    context "valid params" do
      before do
        allow(service).to receive(:execute_hooks)
        project.add_master(user)
      end

      subject { service.execute(wiki_page) }

      it 'updates the wiki page' do
        is_expected.to be_valid
        expect(subject.content).to eq(opts[:content])
        expect(subject.format).to eq(opts[:format].to_sym)
        expect(subject.message).to eq(opts[:message])
      end

      it 'executes webhooks' do
        expect(service).to have_received(:execute_hooks).once.with(subject, 'update')
      end
    end
  end
end
