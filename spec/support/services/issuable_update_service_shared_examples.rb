shared_examples 'issuable update service' do
  context 'changing state' do
    before { expect(project).to receive(:execute_hooks).once }

    context 'to reopened' do
      it 'executes hooks only once' do
        described_class.new(project, user, state_event: 'reopen').execute(closed_issuable)
      end
    end

    context 'to closed' do
      it 'executes hooks only once' do
        described_class.new(project, user, state_event: 'close').execute(open_issuable)
      end
    end
  end
end
