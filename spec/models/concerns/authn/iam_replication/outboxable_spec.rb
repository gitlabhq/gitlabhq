# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication::Outboxable, feature_category: :system_access do
  describe '.iam_replicable' do
    let(:model_class) { Class.new(ApplicationRecord) { include Authn::IamReplication::Outboxable } }

    it 'rejects a blank entity_type' do
      expect { model_class.iam_replicable(entity_type: '') }.to raise_error(ArgumentError)
    end

    it 'rejects an entity_type outside the allowlist' do
      expect { model_class.iam_replicable(entity_type: 'group_member') }
        .to raise_error(ArgumentError, /unknown entity_type/)
    end

    it 'sets the entity type when given an allowed value' do
      model_class.iam_replicable(entity_type: 'oauth_application')

      expect(model_class.iam_outbox_entity_type).to eq('oauth_application')
    end
  end
end
