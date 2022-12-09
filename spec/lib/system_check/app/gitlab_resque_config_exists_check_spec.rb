# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::App::GitlabResqueConfigExistsCheck, feature_category: :redis do
  subject(:system_check) { described_class.new }

  describe '#check?' do
    subject { system_check.check? }

    context 'when config/resque.yml exists' do
      before do
        allow(File).to receive(:exist?).and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when config/resque.yml does not exist' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
