# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::Access do
  shared_examples_for 'displays an error message' do
    it do
      expect(subject[:text]).to match(error_message)
      expect(subject[:response_type]).to be(:ephemeral)
    end
  end

  describe '#access_denied' do
    let(:project) { build(:project) }

    subject { described_class.new.access_denied(project) }

    it { is_expected.to be_a(Hash) }

    it_behaves_like 'displays an error message' do
      let(:error_message) { 'you do not have access to the GitLab project' }
    end
  end

  describe '#generic_access_denied' do
    subject { described_class.new.generic_access_denied }

    it { is_expected.to be_a(Hash) }

    it_behaves_like 'displays an error message' do
      let(:error_message) { 'You are not allowed to perform the given chatops command.' }
    end
  end

  describe '#deactivated' do
    subject { described_class.new.deactivated }

    it { is_expected.to be_a(Hash) }

    it_behaves_like 'displays an error message' do
      let(:error_message) { "your #{Gitlab.config.gitlab.url} account needs to be reactivated" }
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

  describe '#confirm' do
    let(:url) { 'https://example.com/api' }

    subject { described_class.new.confirm(url) }

    it { is_expected.to be_a(Hash) }

    it 'tells the user to confirm the request' do
      expect(subject[:response_type]).to be(:ephemeral)
      expect(subject[:text]).to match(
        "Please confirm the request by accessing <#{url}|this link> through a web browser"
      )
    end
  end
end
