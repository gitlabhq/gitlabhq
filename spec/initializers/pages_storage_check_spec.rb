# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'pages storage check' do
  let(:main_error_message) { "Please enable at least one of the two Pages storage strategy (local_store or object_store) in your config/gitlab.yml." }

  subject(:initializer) { load Rails.root.join('config/initializers/pages_storage_check.rb') }

  context 'when local store does not exist yet' do
    before do
      Settings.pages['local_store'] = nil
    end

    it { is_expected.to be_truthy }
  end

  context 'when pages is not enabled' do
    before do
      Settings.pages['enabled'] = false
    end

    it { is_expected.to be_truthy }
  end

  context 'when pages is enabled' do
    before do
      Settings.pages['enabled'] = true
      Settings.pages['local_store'] = Settingslogic.new({})
    end

    context 'when pages object storage is not enabled' do
      before do
        Settings.pages['object_store']['enabled'] = false
      end

      context 'when pages local storage is not enabled' do
        it 'raises an exception' do
          Settings.pages['local_store']['enabled'] = false

          expect { subject }.to raise_error(main_error_message)
        end
      end

      context 'when pages local storage is enabled' do
        it 'is true' do
          Settings.pages['local_store']['enabled'] = true

          expect(subject).to be_truthy
        end
      end
    end

    context 'when pages object storage is enabled' do
      before do
        Settings.pages['object_store']['enabled'] = true
      end

      context 'when pages local storage is not enabled' do
        it 'is true' do
          Settings.pages['local_store']['enabled'] = false

          expect(subject).to be_truthy
        end
      end

      context 'when pages local storage is enabled' do
        it 'is true' do
          Settings.pages['local_store']['enabled'] = true

          expect(subject).to be_truthy
        end
      end
    end

    context 'when using integers instead of booleans' do
      it 'is true' do
        Settings.pages['local_store']['enabled'] = 1
        Settings.pages['object_store']['enabled'] = 0

        expect(subject).to be_truthy
      end
    end

    context 'when both enabled attributes are not set' do
      it 'raises an exception' do
        Settings.pages['local_store']['enabled'] = nil
        Settings.pages['object_store']['enabled'] = nil

        expect { subject }.to raise_error(main_error_message)
      end
    end
  end
end
