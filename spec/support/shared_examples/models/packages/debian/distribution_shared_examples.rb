# frozen_string_literal: true

RSpec.shared_examples 'Debian Distribution for common behavior' do
  subject { distribution }

  describe 'relationships' do
    it { is_expected.to belong_to(:creator).class_name('User') }
  end

  describe 'validations' do
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

    describe '#file' do
      it { is_expected.not_to validate_presence_of(:file) }
    end

    describe '#file_store' do
      it { is_expected.to validate_presence_of(:file_store) }
    end

    describe '#file_signature' do
      it { is_expected.not_to validate_absence_of(:file_signature) }
    end

    describe '#signed_file' do
      it { is_expected.not_to validate_presence_of(:signed_file) }
    end

    describe '#signed_file_store' do
      it { is_expected.to validate_presence_of(:signed_file_store) }
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
          expect(subject.to_a)
            .to contain_exactly(
              distribution_with_suite,
              distribution_with_same_codename,
              distribution_with_codename_and_suite_flipped)
        end
      end

      describe 'passing suite' do
        subject { described_class.with_codename_or_suite(distribution_with_suite.suite) }

        it 'does not return other distributions' do
          expect(subject.to_a)
            .to contain_exactly(
              distribution_with_suite,
              distribution_with_same_suite,
              distribution_with_codename_and_suite_flipped)
        end
      end
    end
  end
end

RSpec.shared_examples 'Debian Distribution for specific behavior' do |factory|
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
          distribution.update_column(:suite, "suite-#{distribution.codename}") if with_existing_suite

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
end

RSpec.shared_examples 'Debian Distribution with project container' do
  it_behaves_like 'Debian Distribution for specific behavior', :debian_project_distribution

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }

    it { is_expected.to have_one(:key).class_name("Packages::Debian::ProjectDistributionKey").with_foreign_key(:distribution_id).inverse_of(:distribution) }
    it { is_expected.to have_many(:components).class_name("Packages::Debian::ProjectComponent").inverse_of(:distribution) }
    it { is_expected.to have_many(:architectures).class_name("Packages::Debian::ProjectArchitecture").inverse_of(:distribution) }
  end

  describe "#project" do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe 'project distribution specifics' do
    describe 'relationships' do
      it do
        is_expected.to have_many(:publications).class_name('Packages::Debian::Publication').inverse_of(:distribution)
          .with_foreign_key(:distribution_id)
      end

      it { is_expected.to have_many(:packages).class_name('Packages::Debian::Package').through(:publications) }
    end
  end
end

RSpec.shared_examples 'Debian Distribution with group container' do
  it_behaves_like 'Debian Distribution for specific behavior', :debian_group_distribution

  describe 'relationships' do
    it { is_expected.to belong_to(:group) }

    it { is_expected.to have_one(:key).class_name("Packages::Debian::GroupDistributionKey").with_foreign_key(:distribution_id).inverse_of(:distribution) }
    it { is_expected.to have_many(:components).class_name("Packages::Debian::GroupComponent").inverse_of(:distribution) }
    it { is_expected.to have_many(:architectures).class_name("Packages::Debian::GroupArchitecture").inverse_of(:distribution) }
  end

  describe "#group" do
    it { is_expected.to validate_presence_of(:group) }
  end

  describe 'group distribution specifics' do
    let_it_be(:public_project) { create(:project, :public, group: distribution_with_suite.container) }
    let_it_be(:public_distribution_with_same_codename) do
      create(:debian_project_distribution, container: public_project, codename: distribution_with_suite.codename)
    end

    let_it_be(:public_package_with_same_codename) do
      create(:debian_package, project: public_project, published_in: public_distribution_with_same_codename)
    end

    let_it_be(:public_distribution_with_same_suite) do
      create(:debian_project_distribution, container: public_project, suite: distribution_with_suite.suite)
    end

    let_it_be(:public_package_with_same_suite) do
      create(:debian_package, project: public_project, published_in: public_distribution_with_same_suite)
    end

    let_it_be(:private_project) { create(:project, :private, group: distribution_with_suite.container) }
    let_it_be(:private_distribution_with_same_codename) do
      create(:debian_project_distribution, container: private_project, codename: distribution_with_suite.codename)
    end

    let_it_be(:private_package_with_same_codename) do
      create(:debian_package, project: private_project, published_in: private_distribution_with_same_codename)
    end

    let_it_be(:private_distribution_with_same_suite) do
      create(:debian_project_distribution, container: private_project, suite: distribution_with_suite.suite)
    end

    let_it_be(:private_package_with_same_suite) do
      create(:debian_package, project: private_project, published_in: private_distribution_with_same_codename)
    end

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

      context 'with pending destruction package files' do
        let_it_be(:package_file_pending_destruction) do
          create(:package_file, :pending_destruction, package: public_package_with_same_codename)
        end

        it 'does not return them' do
          expect(subject.to_a).not_to include(package_file_pending_destruction)
        end
      end
    end
  end
end
