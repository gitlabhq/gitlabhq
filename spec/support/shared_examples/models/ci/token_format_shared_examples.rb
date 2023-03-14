# frozen_string_literal: true

RSpec.shared_examples_for 'ensures runners_token is prefixed' do |factory|
  subject(:record) { FactoryBot.build(factory) }

  describe '#runners_token', feature_category: :system_access do
    let(:runners_prefix) { RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX }

    it 'generates runners_token which starts with runner prefix' do
      expect(record.runners_token).to match(a_string_starting_with(runners_prefix))
    end

    context 'when record has an invalid token' do
      subject(:record) { FactoryBot.build(factory, runners_token: invalid_runners_token) }

      let(:invalid_runners_token) { "not_start_with_runners_prefix" }

      it 'generates runners_token which starts with runner prefix' do
        expect(record.runners_token).to match(a_string_starting_with(runners_prefix))
      end

      it 'changes the attribute values for runners_token and runners_token_encrypted' do
        expect { record.runners_token }
          .to change { record[:runners_token] }.from(invalid_runners_token).to(nil)
          .and change { record[:runners_token_encrypted] }.from(nil)
      end
    end
  end
end
