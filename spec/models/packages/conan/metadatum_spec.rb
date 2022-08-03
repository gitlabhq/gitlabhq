# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::Metadatum, type: :model do
  using RSpec::Parameterized::TableSyntax

  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    let(:fifty_one_characters) { 'f_a' * 17 }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:package_username) }
    it { is_expected.to validate_presence_of(:package_channel) }

    describe '#package_username' do
      it { is_expected.to allow_value("my-package+username").for(:package_username) }
      it { is_expected.to allow_value("my_package.username").for(:package_username) }
      it { is_expected.to allow_value("_my-package.username123").for(:package_username) }
      it { is_expected.to allow_value("my").for(:package_username) }
      it { is_expected.not_to allow_value('+my_package').for(:package_username) }
      it { is_expected.not_to allow_value('.my_package').for(:package_username) }
      it { is_expected.not_to allow_value('-my_package').for(:package_username) }
      it { is_expected.not_to allow_value('m').for(:package_username) }
      it { is_expected.not_to allow_value(fifty_one_characters).for(:package_username) }
      it { is_expected.not_to allow_value("my/package").for(:package_username) }
      it { is_expected.not_to allow_value("my(package)").for(:package_username) }
      it { is_expected.not_to allow_value("my@package").for(:package_username) }
    end

    describe '#package_channel' do
      it { is_expected.to allow_value("beta").for(:package_channel) }
      it { is_expected.to allow_value("stable+1.0").for(:package_channel) }
      it { is_expected.to allow_value("my").for(:package_channel) }
      it { is_expected.to allow_value("my_channel.beta").for(:package_channel) }
      it { is_expected.to allow_value("_my-channel.beta123").for(:package_channel) }
      it { is_expected.not_to allow_value('+my_channel').for(:package_channel) }
      it { is_expected.not_to allow_value('.my_channel').for(:package_channel) }
      it { is_expected.not_to allow_value('-my_channel').for(:package_channel) }
      it { is_expected.not_to allow_value('m').for(:package_channel) }
      it { is_expected.not_to allow_value(fifty_one_characters).for(:package_channel) }
      it { is_expected.not_to allow_value("my/channel").for(:package_channel) }
      it { is_expected.not_to allow_value("my(channel)").for(:package_channel) }
      it { is_expected.not_to allow_value("my@channel").for(:package_channel) }
    end

    describe '#username_channel_none_values' do
      let_it_be(:package) { create(:conan_package) }

      let(:metadatum) { package.conan_metadatum }

      subject { metadatum.valid? }

      where(:username, :channel, :valid) do
        'username' | 'channel' | true
        'username' | '_'       | false
        '_'        | 'channel' | false
        '_'        | '_'       | true
      end

      with_them do
        before do
          metadatum.package_username = username
          metadatum.package_channel = channel
        end

        it { is_expected.to eq(valid) }
      end
    end

    describe '#conan_package_type' do
      it 'will not allow a package with a different package_type' do
        package = build('package')
        conan_metadatum = build('conan_metadatum', package: package)

        expect(conan_metadatum).not_to be_valid
        expect(conan_metadatum.errors.to_a).to include('Package type must be Conan')
      end
    end
  end

  describe '#recipe' do
    let(:package) { create(:conan_package) }

    it 'returns the recipe' do
      expect(package.conan_recipe).to eq("#{package.name}/#{package.version}@#{package.conan_metadatum.package_username}/#{package.conan_metadatum.package_channel}")
    end
  end

  describe '#recipe_url' do
    let(:package) { create(:conan_package) }

    it 'returns the recipe url' do
      expect(package.conan_recipe_path).to eq("#{package.name}/#{package.version}/#{package.conan_metadatum.package_username}/#{package.conan_metadatum.package_channel}")
    end
  end

  describe '.package_username_from' do
    let(:full_path) { 'foo/bar/baz-buz' }

    it 'returns the username formatted package path' do
      expect(described_class.package_username_from(full_path: full_path)).to eq('foo+bar+baz-buz')
    end
  end

  describe '.full_path_from' do
    let(:username) { 'foo+bar+baz-buz' }

    it 'returns the username formatted package path' do
      expect(described_class.full_path_from(package_username: username)).to eq('foo/bar/baz-buz')
    end
  end

  describe '.validate_username_and_channel' do
    where(:username, :channel, :error_field) do
      'username' | 'channel' | nil
      'username' | '_'       | :channel
      '_'        | 'channel' | :username
      '_'        | '_'       | nil
    end

    with_them do
      if params[:error_field]
        it 'yields the block when there is an error' do
          described_class.validate_username_and_channel(username, channel) do |none_field|
            expect(none_field).to eq(error_field)
          end
        end
      else
        it 'does not yield the block when there is no error' do
          expect { |b| described_class.validate_username_and_channel(username, channel, &b) }.not_to yield_control
        end
      end
    end
  end
end
