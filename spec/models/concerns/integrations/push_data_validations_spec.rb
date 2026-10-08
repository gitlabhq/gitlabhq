# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::PushDataValidations, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  subject(:integration) { Class.new { include Integrations::PushDataValidations }.new }

  describe '#merge_request_valid?' do
    let(:data) { { object_attributes: { state: state, action: action, oldrev: oldrev } } }

    where(:state, :action, :oldrev, :valid) do
      'opened' | 'open'     | nil      | true
      'opened' | 'reopen'   | nil      | true
      'opened' | 'update'   | 'abc123' | true
      'opened' | 'update'   | nil      | false
      'opened' | 'update'   | ''       | false
      'opened' | 'approved' | nil      | false
      'closed' | 'open'     | nil      | false
    end

    with_them do
      it { expect(integration.merge_request_valid?(data)).to be(valid) }
    end

    it 'returns false when object_attributes is missing' do
      expect(integration.merge_request_valid?({})).to be(false)
    end
  end
end
