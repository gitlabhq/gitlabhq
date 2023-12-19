# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organization::CurrentOrganization, feature_category: :organization do
  include described_class

  after do
    # Wipe thread variables between specs.
    Thread.current[described_class::CURRENT_ORGANIZATION_THREAD_VAR] = nil
  end

  describe '.current_organization' do
    subject { current_organization }

    context 'when current organization is set' do
      let(:some_organization) { create(:organization) }

      before do
        self.current_organization = some_organization
      end

      it { is_expected.to eq some_organization }
    end

    context 'when organization is not set' do
      it { is_expected.to be_nil }
    end
  end

  describe '.current_organization=' do
    subject(:setter) { self.current_organization = some_organization }

    let(:some_organization) { create(:organization) }

    it 'sets current organization' do
      expect { setter }.to change { current_organization }.from(nil).to(some_organization)
    end
  end

  describe '.with_current_organization' do
    let(:some_organization) { create(:organization) }

    it 'sets current organization within block' do
      expect(current_organization).to be_nil
      with_current_organization(some_organization) do
        expect(current_organization).to eq some_organization
      end
      expect(current_organization).to be_nil
    end

    context 'when an error is raised' do
      it 'resets current organization' do
        begin
          with_current_organization(some_organization) do
            raise StandardError
          end
        rescue StandardError
          nil
        end

        expect(current_organization).to be_nil
      end
    end
  end
end
