# frozen_string_literal: true

# Expects usage of 'incident management settings enabled' context.
#
# This shared_example requires the following variables:
# - `alert`, alert for which related incidents should be closed
# - `project`, project of the alert
RSpec.shared_examples 'closes related incident if enabled' do
  context 'with incident' do
    before do
      alert.update!(issue: create(:incident, project: project))
    end

    specify do
      expect { Sidekiq::Testing.inline! { subject } }
        .to change { alert.issue.reload.closed? }.from(false).to(true)
        .and change { ResourceStateEvent.count }.by(1)
    end
  end

  context 'without incident' do
    specify do
      expect(::IncidentManagement::CloseIncidentWorker).not_to receive(:perform_async)

      subject
    end
  end

  context 'with incident setting disabled' do
    let(:auto_close_incident) { false }

    it_behaves_like 'does not close related incident'
  end
end

RSpec.shared_examples 'does not close related incident' do
  context 'with incident' do
    before do
      alert.update!(issue: create(:incident, project: project))
    end

    specify do
      expect { Sidekiq::Testing.inline! { subject } }
        .to not_change { alert.issue.reload.state }
        .and not_change(ResourceStateEvent, :count)
    end
  end

  context 'without incident' do
    specify do
      expect(::IncidentManagement::CloseIncidentWorker).not_to receive(:perform_async)

      subject
    end
  end
end
