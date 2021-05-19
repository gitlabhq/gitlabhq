# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'pages storage check' do
  let(:main_error_message) { "Please enable at least one of the two Pages storage strategy (local_store or object_store) in your config/gitlab.yml." }

  subject(:initializer) { load Rails.root.join('config/initializers/pages_storage_check.rb') }

  context 'when local store does not exist yet' do
    before do
      stub_config(pages: { enabled: true, local_store: nil })
    end

    it { is_expected.to be_truthy }
  end

  context 'when pages is not enabled' do
    before do
      stub_config(pages: { enabled: false })
    end

    it { is_expected.to be_truthy }
  end

  context 'when pages is enabled' do
    using RSpec::Parameterized::TableSyntax

    where(:local_storage_enabled, :object_storage_enabled, :raises_exception) do
      false | false | true
      false | true  | false
      true  | false | false
      true  | true  | false
      1     | 0     | false
      nil   | nil   | true
    end

    with_them do
      before do
        stub_config(
          pages: {
            enabled: true,
            local_store: { enabled: local_storage_enabled },
            object_store: { enabled: object_storage_enabled }
          }
        )
      end

      it 'validates pages storage configuration' do
        if raises_exception
          expect { subject }.to raise_error(main_error_message)
        else
          expect(subject).to be_truthy
        end
      end
    end
  end
end
