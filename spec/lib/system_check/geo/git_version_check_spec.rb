require 'spec_helper'

describe SystemCheck::Geo::GitVersionCheck do
  describe '#check?' do
    subject { described_class.new.check? }

    where(:git_version, :result) do
      [
        ['2.8.99', false],
        ['2.9.0',  false],
        ['2.9.4',  false],
        ['2.9.5',  true],
        ['2.9.55', true],
        ['10.0.0', true]
      ]
    end

    with_them do
      before do
        stub_git_version(git_version)
      end

      it { is_expected.to eq(result) }
    end
  end

  def stub_git_version(version)
    allow(described_class).to receive(:current_version) { Gitlab::VersionInfo.parse(version) }
  end
end
