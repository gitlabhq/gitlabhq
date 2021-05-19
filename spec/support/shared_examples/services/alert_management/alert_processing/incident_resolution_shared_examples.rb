# frozen_string_literal: true

# Expects usage of 'incident settings enabled' context.
#
# This shared_example requires the following variables:
# - `alert`, alert for which related incidents should be closed
# - `project`, project of the alert
RSpec.shared_examples 'closes related incident if enabled' do
  context 'with issue' do
    before do
      alert.update!(issue: create(:issue, project: project))
    end

    it { expect { subject }.to change { alert.issue.reload.closed? }.from(false).to(true) }
    it { expect { subject }.to change(ResourceStateEvent, :count).by(1) }
  end

  context 'without issue' do
    it { expect { subject }.not_to change { alert.reload.issue } }
    it { expect { subject }.not_to change(ResourceStateEvent, :count) }
  end

  context 'with incident setting disabled' do
    let(:auto_close_incident) { false }

    it_behaves_like 'does not close related incident'
  end
end

RSpec.shared_examples 'does not close related incident' do
  context 'with issue' do
    before do
      alert.update!(issue: create(:issue, project: project))
    end

    it { expect { subject }.not_to change { alert.issue.reload.state } }
    it { expect { subject }.not_to change(ResourceStateEvent, :count) }
  end

  context 'without issue' do
    it { expect { subject }.not_to change { alert.reload.issue } }
    it { expect { subject }.not_to change(ResourceStateEvent, :count) }
  end
end
