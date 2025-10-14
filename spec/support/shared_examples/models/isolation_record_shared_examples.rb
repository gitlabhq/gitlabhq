# frozen_string_literal: true

RSpec.shared_examples 'an IsolationRecord model' do
  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:isolated).in_array([true, false]) }
  end

  describe '#not_isolated?' do
    context 'when isolated is true' do
      let(:record) { build(factory_name, isolated: true) }

      it 'returns false' do
        expect(record.not_isolated?).to be false
      end
    end

    context 'when isolated is false' do
      let(:record) { build(factory_name, isolated: false) }

      it 'returns true' do
        expect(record.not_isolated?).to be true
      end
    end
  end

  describe 'timestamps' do
    # rubocop:disable Rails/SaveBang -- rubocop assumes this is a ActiveRecord create but it is not
    let(:record) { create(factory_name) }
    # rubocop:enable Rails/SaveBang

    it 'sets created_at and updated_at on creation' do
      expect(record.created_at).to be_present
      expect(record.updated_at).to be_present
    end

    it 'updates updated_at when isolation state changes' do
      original_updated_at = record.updated_at

      travel_to(1.minute.from_now) do
        record.update!(isolated: true)
        expect(record.updated_at).to be > original_updated_at
      end
    end
  end
end
