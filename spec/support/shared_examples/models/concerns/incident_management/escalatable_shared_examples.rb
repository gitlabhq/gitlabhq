# frozen_string_literal: true

RSpec.shared_examples 'a model including Escalatable' do
  let_it_be(:escalatable_factory) { factory_from_class(described_class) }
  let_it_be(:triggered_escalatable, reload: true) { create(escalatable_factory, :triggered) }
  let_it_be(:acknowledged_escalatable, reload: true) { create(escalatable_factory, :acknowledged) }
  let_it_be(:resolved_escalatable, reload: true) { create(escalatable_factory, :resolved) }
  let_it_be(:ignored_escalatable, reload: true) { create(escalatable_factory, :ignored) }

  context 'validations' do
    it { is_expected.to validate_presence_of(:status) }

    context 'when status is triggered' do
      subject { triggered_escalatable }

      context 'when resolved_at is blank' do
        it { is_expected.to be_valid }
      end

      context 'when resolved_at is present' do
        before do
          triggered_escalatable.resolved_at = Time.current
        end

        it { is_expected.to be_invalid }
      end
    end

    context 'when status is acknowledged' do
      subject { acknowledged_escalatable }

      context 'when resolved_at is blank' do
        it { is_expected.to be_valid }
      end

      context 'when resolved_at is present' do
        before do
          acknowledged_escalatable.resolved_at = Time.current
        end

        it { is_expected.to be_invalid }
      end
    end

    context 'when status is resolved' do
      subject { resolved_escalatable }

      context 'when resolved_at is blank' do
        before do
          resolved_escalatable.resolved_at = nil
        end

        it { is_expected.to be_invalid }
      end

      context 'when resolved_at is present' do
        it { is_expected.to be_valid }
      end
    end

    context 'when status is ignored' do
      subject { ignored_escalatable }

      context 'when resolved_at is blank' do
        it { is_expected.to be_valid }
      end

      context 'when resolved_at is present' do
        before do
          ignored_escalatable.resolved_at = Time.current
        end

        it { is_expected.to be_invalid }
      end
    end
  end

  context 'scopes' do
    let(:all_escalatables) { described_class.where(id: [triggered_escalatable, acknowledged_escalatable, ignored_escalatable, resolved_escalatable]) }

    describe '.order_status' do
      subject { all_escalatables.order_status(order) }

      context 'descending' do
        let(:order) { :desc }

        # Downward arrow in UI always corresponds to default sort
        it { is_expected.to eq([triggered_escalatable, acknowledged_escalatable, resolved_escalatable, ignored_escalatable]) }
      end

      context 'ascending' do
        let(:order) { :asc }

        it { is_expected.to eq([ignored_escalatable, resolved_escalatable, acknowledged_escalatable, triggered_escalatable]) }
      end
    end

    describe '.open' do
      subject { all_escalatables.open }

      it { is_expected.to contain_exactly(acknowledged_escalatable, triggered_escalatable) }
    end
  end

  describe '.status_value' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :status_value) do
      :triggered    | 0
      :acknowledged | 1
      :resolved     | 2
      :ignored      | 3
      :unknown      | nil
    end

    with_them do
      it 'returns status value by its name' do
        expect(described_class.status_value(status)).to eq(status_value)
      end
    end
  end

  describe '.status_name' do
    using RSpec::Parameterized::TableSyntax

    where(:raw_status, :status) do
      0  | :triggered
      1  | :acknowledged
      2  | :resolved
      3  | :ignored
      -1 | nil
    end

    with_them do
      it 'returns status name by its values' do
        expect(described_class.status_name(raw_status)).to eq(status)
      end
    end
  end

  describe '.open_status?' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :is_open_status) do
      :triggered    | true
      :acknowledged | true
      :resolved     | false
      :ignored      | false
      nil           | false
    end

    with_them do
      it 'returns true when the status is open status' do
        expect(described_class.open_status?(status)).to eq(is_open_status)
      end
    end
  end

  describe '#trigger' do
    subject { escalatable.trigger }

    context 'when escalatable is in triggered state' do
      let(:escalatable) { triggered_escalatable }

      it 'does not change the escalatable status' do
        expect { subject }.not_to change { escalatable.reload.status }
      end
    end

    context 'when escalatable is not in triggered state' do
      let(:escalatable) { resolved_escalatable }

      it 'changes the escalatable status to triggered' do
        expect { subject }.to change { escalatable.triggered? }.to(true)
      end

      it 'resets resolved at' do
        expect { subject }.to change { escalatable.reload.resolved_at }.to nil
      end
    end
  end

  describe '#acknowledge' do
    subject { escalatable.acknowledge }

    let(:escalatable) { resolved_escalatable }

    it 'changes the escalatable status to acknowledged' do
      expect { subject }.to change { escalatable.acknowledged? }.to(true)
    end

    it 'resets ended at' do
      expect { subject }.to change { escalatable.reload.resolved_at }.to nil
    end
  end

  describe '#resolve' do
    let!(:resolved_at) { Time.current }

    subject do
      escalatable.resolved_at = resolved_at
      escalatable.resolve
    end

    context 'when escalatable is already resolved' do
      let(:escalatable) { resolved_escalatable }

      it 'does not change the escalatable status' do
        expect { subject }.not_to change { resolved_escalatable.reload.status }
      end
    end

    context 'when escalatable is not resolved' do
      let(:escalatable) { triggered_escalatable }

      it 'changes escalatable status to "resolved"' do
        expect { subject }.to change { escalatable.resolved? }.to(true)
      end
    end
  end

  describe '#ignore' do
    subject { escalatable.ignore }

    let(:escalatable) { resolved_escalatable }

    it 'changes the escalatable status to ignored' do
      expect { subject }.to change { escalatable.ignored? }.to(true)
    end

    it 'resets ended at' do
      expect { subject }.to change { escalatable.reload.resolved_at }.to nil
    end
  end

  describe '#status_event_for' do
    using RSpec::Parameterized::TableSyntax

    where(:for_status, :event) do
      :triggered     | :trigger
      'triggered'    | :trigger
      :acknowledged  | :acknowledge
      'acknowledged' | :acknowledge
      :resolved      | :resolve
      'resolved'     | :resolve
      :ignored       | :ignore
      'ignored'      | :ignore
      :unknown       | nil
      nil            | nil
      ''             | nil
      1              | nil
    end

    with_them do
      let(:escalatable) { build(escalatable_factory) }

      it 'returns event by status name' do
        expect(escalatable.status_event_for(for_status)).to eq(event)
      end
    end
  end

  describe '#open?' do
    it 'returns true when the status is open status' do
      expect(triggered_escalatable.open?).to be true
      expect(acknowledged_escalatable.open?).to be true
      expect(resolved_escalatable.open?).to be false
      expect(ignored_escalatable.open?).to be false
    end
  end

  private

  def factory_from_class(klass)
    klass.name.underscore.tr('/', '_')
  end
end
