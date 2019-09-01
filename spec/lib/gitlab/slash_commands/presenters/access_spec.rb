# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SlashCommands::Presenters::Access do
  describe '#access_denied' do
    let(:project) { build(:project) }

    subject { described_class.new.access_denied(project) }

    it { is_expected.to be_a(Hash) }

    it 'displays an error message' do
      expect(subject[:text]).to match('are not allowed')
      expect(subject[:response_type]).to be(:ephemeral)
    end
  end

  describe '#not_found' do
    subject { described_class.new.not_found }

    it { is_expected.to be_a(Hash) }

    it 'tells the user the resource was not found' do
      expect(subject[:text]).to match("not found!")
      expect(subject[:response_type]).to be(:ephemeral)
    end
  end

  describe '#authorize' do
    context 'with an authorization URL' do
      subject { described_class.new('http://authorize.me').authorize }

      it { is_expected.to be_a(Hash) }

      it 'tells the user to authorize' do
        expect(subject[:text]).to match("connect your GitLab account")
        expect(subject[:response_type]).to be(:ephemeral)
      end
    end

    context 'without authorization url' do
      subject { described_class.new.authorize }

      it { is_expected.to be_a(Hash) }

      it 'tells the user to authorize' do
        expect(subject[:text]).to match("Couldn't identify you")
        expect(subject[:response_type]).to be(:ephemeral)
      end
    end
  end
end
