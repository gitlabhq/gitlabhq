# frozen_string_literal: true

RSpec.shared_examples 'namespace visits tracking worker' do
  let_it_be(:base_time) { DateTime.now }

  context 'when params are provided' do
    before do
      worker.perform(entity_type, entity.id, user.id, base_time)
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { [entity_type, entity.id, user.id, base_time] }

      it 'tracks the entity visit' do
        latest_visit = model.last

        expect(model.count).to be(1)
        expect(latest_visit[:entity_id]).to be(entity.id)
        expect(latest_visit.user_id).to be(user.id)
      end
    end

    context 'when a visit occurs within 15 minutes of a previously tracked one' do
      [-15.minutes, 15.minutes].each do |time_diff|
        it 'does not track the visit' do
          worker.perform(entity_type, entity.id, user.id, base_time + time_diff)

          expect(model.count).to be(1)
        end
      end
    end

    context 'when a visit occurs more than 15 minutes away from a previously tracked one' do
      [-16.minutes, 16.minutes].each do |time_diff|
        it 'tracks the visit' do
          worker.perform(entity_type, entity.id, user.id, base_time + time_diff)

          expect(model.count).to be > 1
        end
      end
    end
  end

  context 'when user is missing' do
    before do
      worker.perform(entity_type, entity.id, nil, base_time)
    end

    it 'does not do anything' do
      expect(model.count).to be(0)
    end
  end

  context 'when entity is missing' do
    before do
      worker.perform(entity_type, nil, user.id, base_time)
    end

    it 'does not do anything' do
      expect(model.count).to be(0)
    end
  end
end
