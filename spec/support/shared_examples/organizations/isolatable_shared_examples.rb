# frozen_string_literal: true

RSpec.shared_examples 'an isolatable' do |isolatable_factory|
  # rubocop:disable Rails/SaveBang -- The key for the factory is passed using a variable, this is flagged as an offense
  let_it_be_with_reload(:isolatable) { create(isolatable_factory) }
  # rubocop:enable Rails/SaveBang
  let(:status) { false }

  def create_isolation_record(isolatable, status)
    create(:namespace_isolation, namespace: isolatable, isolated: status) if isolatable.is_a? Namespace

    return unless isolatable.is_a? ::Organizations::Organization

    create(:organization_isolation, organization: isolatable, isolated: status)
  end

  describe '#isolated?' do
    subject(:isolated?) { isolatable.reload.isolated? }

    context 'when isolatable has no isolation record' do
      it 'returns false' do
        expect(isolated?).to be false
      end
    end

    context 'when isolatable has isolation record with isolated false' do
      before do
        create_isolation_record(isolatable, status)
      end

      it 'returns false' do
        expect(isolated?).to be false
      end
    end

    context 'when isolatable has isolation record with isolated true' do
      let(:status) { true }

      before do
        create_isolation_record(isolatable, status)
      end

      it 'returns true' do
        expect(isolated?).to be true
      end
    end
  end

  describe '#not_isolated?' do
    subject(:not_isolated?) { isolatable.reload.not_isolated? }

    context 'when isolatable has no isolation record' do
      it 'returns true' do
        expect(not_isolated?).to be true
      end
    end

    context 'when isolatable has isolation record with isolated false' do
      before do
        create_isolation_record(isolatable, status)
      end

      it 'returns true' do
        expect(not_isolated?).to be true
      end
    end

    context 'when isolatable has isolation record with isolated true' do
      let(:status) { true }

      before do
        create_isolation_record(isolatable, status)
      end

      it 'returns false' do
        expect(not_isolated?).to be false
      end
    end
  end

  describe '#mark_as_isolated!' do
    subject(:mark_as_isolated) { isolatable.mark_as_isolated! }

    context 'when isolatable has no isolation record' do
      it 'marks the isolatable as isolated' do
        expect { mark_as_isolated }.to change { isolatable.isolated? }.from(false).to(true)
      end
    end

    context 'when isolatable has isolation record' do
      let!(:isolation) { create_isolation_record(isolatable, status) }

      context 'and the record is set to false' do
        let(:status) { false }

        it 'marks the isolatable as isolated' do
          expect { mark_as_isolated }.to change { isolatable.isolated? }.from(false).to(true)
        end
      end

      context 'and the record is set to true' do
        let(:status) { true }

        it 'does nothing' do
          expect { mark_as_isolated }.not_to change { isolatable.isolated? }
        end
      end
    end
  end

  describe '#mark_as_not_isolated!' do
    subject(:mark_as_not_isolated) { isolatable.mark_as_not_isolated! }

    context 'when isolatable has no isolation record' do
      it 'does nothing' do
        expect { mark_as_not_isolated }.not_to change { isolatable.isolated? }
      end
    end

    context 'when isolatable has isolation record' do
      let!(:isolation) { create_isolation_record(isolatable, status) }

      context 'and the record is set to true' do
        let(:status) { true }

        it 'marks the isolatable as not isolated' do
          expect { mark_as_not_isolated }.to change { isolatable.isolated? }.from(true).to(false)
        end
      end

      context 'and the record is set to false' do
        let(:status) { false }

        it 'does nothing' do
          expect { mark_as_not_isolated }.not_to change { isolatable.isolated? }
        end
      end
    end
  end
end
