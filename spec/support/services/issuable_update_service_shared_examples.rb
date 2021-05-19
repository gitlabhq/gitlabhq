# frozen_string_literal: true

RSpec.shared_examples 'issuable update service' do
  def update_issuable(opts)
    described_class.new(project, user, opts).execute(open_issuable)
  end

  context 'changing state' do
    before do
      expect(project).to receive(:execute_hooks).once
    end

    context 'to reopened' do
      it 'executes hooks only once' do
        described_class.new(project: project, current_user: user, params: { state_event: 'reopen' }).execute(closed_issuable)
      end
    end

    context 'to closed' do
      it 'executes hooks only once' do
        described_class.new(project: project, current_user: user, params: { state_event: 'close' }).execute(open_issuable)
      end
    end
  end
end
