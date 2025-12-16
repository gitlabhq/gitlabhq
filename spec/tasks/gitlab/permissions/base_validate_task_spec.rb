# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::BaseValidateTask, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  describe 'interface methods' do
    let(:test_class) { Class.new(described_class) }

    context 'when not implemented' do
      where(:method) do
        [
          :error_messages,
          :format_all_errors,
          :json_schema_file
        ]
      end

      with_them do
        it 'raises NotImplementedError' do
          expect { test_class.new.send(method) }.to raise_error(NotImplementedError)
        end
      end
    end
  end
end
