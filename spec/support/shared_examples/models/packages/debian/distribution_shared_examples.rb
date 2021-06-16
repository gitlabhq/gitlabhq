# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Debian Distribution' do |factory, container, can_freeze|
  let_it_be(:distribution_with_suite, freeze: can_freeze) { create(factory, suite: 'mysuite') }
  let_it_be(:distribution_with_same_container, freeze: can_freeze) { create(factory, container: distribution_with_suite.container ) }
  let_it_be(:distribution_with_same_codename, freeze: can_freeze) { create(factory, codename: distribution_with_suite.codename ) }
  let_it_be(:distribution_with_same_suite, freeze: can_freeze) { create(factory, suite: distribution_with_suite.suite ) }
  let_it_be(:distribution_with_codename_and_suite_flipped, freeze: can_freeze) { create(factory, codename: distribution_with_suite.suite, suite: distribution_with_suite.codename) }

  let_it_be_with_refind(:distribution) { create(factory, container: distribution_with_suite.container ) }

  subject { distribution }

  describe 'relationships' do
    it { is_expected.to belong_to(container) }
    it { is_expected.to belong_to(:creator).class_name('User') }

    it { is_expected.to have_one(:key).class_name("Packages::Debian::#{container.capitalize}DistributionKey").with_foreign_key(:distribution_id).inverse_of(:distribution) }
    it { is_expected.to have_many(:components).class_name("Packages::Debian::#{container.capitalize}Component").inverse_of(:distribution) }
    it { is_expected.to have_many(:architectures).class_name("Packages::Debian::#{container.capitalize}Architecture").inverse_of(:distribution) }
  end

  describe 'validations' do
    describe "##{container}" do
      it { is_expected.to validate_presence_of(container) }
    end

    describe "#creator" do
      it { is_expected.not_to validate_presence_of(:creator) }
    end

    describe '#codename' do
      it { is_expected.to validate_presence_of(:codename) }

      it { is_expected.to allow_value('buster').for(:codename) }
      it { is_expected.to allow_value('buster-updates').for(:codename) }
      it { is_expected.to allow_value('Debian10.5').for(:codename) }
      it { is_expected.not_to allow_value('jessie/updates').for(:codename) }
      it { is_expected.not_to allow_value('hé').for(:codename) }
    end

    describe '#suite' do
      it { is_expected.to allow_value(nil).for(:suite) }
      it { is_expected.to allow_value('testing').for(:suite) }
      it { is_expected.not_to allow_value('hé').for(:suite) }
    end

    describe '#unique_debian_suite_and_codename' do
      using RSpec::Parameterized::TableSyntax

      where(:with_existing_suite, :suite, :codename, :errors) do
        false | nil           | :keep             | nil
        false | 'testing'     | :keep             | nil
        false | nil           | :codename         | ["Codename has already been taken"]
        false | :codename     | :keep             | ["Suite has already been taken as Codename"]
        false | :codename     | :codename         | ["Codename has already been taken", "Suite has already been taken as Codename"]
        true  | nil           | :keep             | nil
        true  | 'testing'     | :keep             | nil
        true  | nil           | :codename         | ["Codename has already been taken"]
        true  | :codename     | :keep             | ["Suite has already been taken as Codename"]
        true  | :codename     | :codename         | ["Codename has already been taken", "Suite has already been taken as Codename"]
        true  | nil           | :suite            | ["Codename has already been taken as Suite"]
        true  | :suite        | :keep             | ["Suite has already been taken"]
        true  | :suite        | :suite            | ["Suite has already been taken", "Codename has already been taken as Suite"]
      end

      with_them do
        context factory do
          let(:new_distribution) { build(factory, container: distribution.container) }

          before do
            distribution.update_column(:suite, 'suite-' + distribution.codename) if with_existing_suite

            if suite.is_a?(Symbol)
              new_distribution.suite = distribution.send suite unless suite == :keep
            else
              new_distribution.suite = suite
            end

            if codename.is_a?(Symbol)
              new_distribution.codename = distribution.send codename unless codename == :keep
            else
              new_distribution.codename = codename
            end
          end

          it do
            if errors
              expect(new_distribution).not_to be_valid
              expect(new_distribution.errors.to_a).to eq(errors)
            else
              expect(new_distribution).to be_valid
            end
          end
        end
      end
    end

    describe '#origin' do
      it { is_expected.to allow_value(nil).for(:origin) }
      it { is_expected.to allow_value('Debian').for(:origin) }
      it { is_expected.not_to allow_value('hé').for(:origin) }
    end

    describe '#label' do
      it { is_expected.to allow_value(nil).for(:label) }
      it { is_expected.to allow_value('Debian').for(:label) }
      it { is_expected.not_to allow_value('hé').for(:label) }
    end

    describe '#version' do
      it { is_expected.to allow_value(nil).for(:version) }
      it { is_expected.to allow_value('10.6').for(:version) }
      it { is_expected.not_to allow_value('hé').for(:version) }
    end

    describe '#description' do
      it { is_expected.to allow_value(nil).for(:description) }
      it { is_expected.to allow_value('Debian 10.6 Released 26 September 2020').for(:description) }
      it { is_expected.to allow_value('Hé !').for(:description) }
    end

    describe '#valid_time_duration_seconds' do
      it { is_expected.to allow_value(nil).for(:valid_time_duration_seconds) }
      it { is_expected.to allow_value(24.hours.to_i).for(:valid_time_duration_seconds) }
      it { is_expected.not_to allow_value(12.hours.to_i).for(:valid_time_duration_seconds) }
    end

    describe '#signing_keys' do
      it { is_expected.to validate_absence_of(:signing_keys) }
    end

    describe '#file' do
      it { is_expected.not_to validate_presence_of(:file) }
    end

    describe '#file_store' do
      it { is_expected.to validate_presence_of(:file_store) }
    end

    describe '#file_signature' do
      it { is_expected.to validate_absence_of(:file_signature) }
    end
  end

  describe 'scopes' do
    describe '.with_container' do
      subject { described_class.with_container(distribution_with_suite.container) }

      it 'does not return other distributions' do
        expect(subject).to match_array([distribution_with_suite, distribution, distribution_with_same_container])
      end
    end

    describe '.with_codename' do
      subject { described_class.with_codename(distribution_with_suite.codename) }

      it 'does not return other distributions' do
        expect(subject).to match_array([distribution_with_suite, distribution_with_same_codename])
      end
    end

    describe '.with_suite' do
      subject { described_class.with_suite(distribution_with_suite.suite) }

      it 'does not return other distributions' do
        expect(subject).to match_array([distribution_with_suite, distribution_with_same_suite])
      end
    end

    describe '.with_codename_or_suite' do
      describe 'passing codename' do
        subject { described_class.with_codename_or_suite(distribution_with_suite.codename) }

        it 'does not return other distributions' do
          expect(subject.to_a).to contain_exactly(distribution_with_suite, distribution_with_same_codename, distribution_with_codename_and_suite_flipped)
        end
      end

      describe 'passing suite' do
        subject { described_class.with_codename_or_suite(distribution_with_suite.suite) }

        it 'does not return other distributions' do
          expect(subject.to_a).to contain_exactly(distribution_with_suite, distribution_with_same_suite, distribution_with_codename_and_suite_flipped)
        end
      end
    end
  end

  describe '#needs_update?' do
    subject { distribution.needs_update? }

    context 'with new distribution' do
      let(:distribution) { create(factory, container: distribution_with_suite.container) }

      it { is_expected.to be_truthy }
    end

    context 'with file' do
      context 'without valid_time_duration_seconds' do
        let(:distribution) { create(factory, :with_file, container: distribution_with_suite.container) }

        it { is_expected.to be_falsey }
      end

      context 'with valid_time_duration_seconds' do
        let(:distribution) { create(factory, :with_file, container: distribution_with_suite.container, valid_time_duration_seconds: 2.days.to_i) }

        context 'when not yet expired' do
          it { is_expected.to be_falsey }
        end

        context 'when expired' do
          it do
            distribution

            travel_to(4.days.from_now) do
              is_expected.to be_truthy
            end
          end
        end
      end
    end
  end

  if container == :project
    describe 'project distribution specifics' do
      describe 'relationships' do
        it { is_expected.to have_many(:publications).class_name('Packages::Debian::Publication').inverse_of(:distribution).with_foreign_key(:distribution_id) }
        it { is_expected.to have_many(:packages).class_name('Packages::Package').through(:publications) }
        it { is_expected.to have_many(:package_files).class_name('Packages::PackageFile').through(:packages) }
      end
    end
  else
    describe 'group distribution specifics' do
      let_it_be(:public_project) { create(:project, :public, group: distribution_with_suite.container)}
      let_it_be(:public_distribution_with_same_codename) { create(:debian_project_distribution, container: public_project, codename: distribution_with_suite.codename) }
      let_it_be(:public_package_with_same_codename) { create(:debian_package, project: public_project, published_in: public_distribution_with_same_codename)}
      let_it_be(:public_distribution_with_same_suite) { create(:debian_project_distribution, container: public_project, suite: distribution_with_suite.suite) }
      let_it_be(:public_package_with_same_suite) { create(:debian_package, project: public_project, published_in: public_distribution_with_same_suite)}

      let_it_be(:private_project) { create(:project, :private, group: distribution_with_suite.container)}
      let_it_be(:private_distribution_with_same_codename) { create(:debian_project_distribution, container: private_project, codename: distribution_with_suite.codename) }
      let_it_be(:private_package_with_same_codename) { create(:debian_package, project: private_project, published_in: private_distribution_with_same_codename)}
      let_it_be(:private_distribution_with_same_suite) { create(:debian_project_distribution, container: private_project, suite: distribution_with_suite.suite) }
      let_it_be(:private_package_with_same_suite) { create(:debian_package, project: private_project, published_in: private_distribution_with_same_codename)}

      describe '#packages' do
        subject { distribution_with_suite.packages }

        it 'returns only public packages with same codename' do
          expect(subject.to_a).to contain_exactly(public_package_with_same_codename)
        end
      end

      describe '#package_files' do
        subject { distribution_with_suite.package_files }

        it 'returns only files from public packages with same codename' do
          expect(subject.to_a).to contain_exactly(*public_package_with_same_codename.package_files)
        end
      end
    end
  end
end
