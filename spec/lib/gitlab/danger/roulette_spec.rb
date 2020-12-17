# frozen_string_literal: true

require 'webmock/rspec'
require 'timecop'

require 'gitlab/danger/roulette'
require 'active_support/testing/time_helpers'

RSpec.describe Gitlab::Danger::Roulette do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.utc(2020, 06, 22, 10)) { example.run }
  end

  let(:backend_available) { true }
  let(:backend_tz_offset_hours) { 2.0 }
  let(:backend_maintainer) do
    Gitlab::Danger::Teammate.new(
      'username' => 'backend-maintainer',
      'name' => 'Backend maintainer',
      'role' => 'Backend engineer',
      'projects' => { 'gitlab' => 'maintainer backend' },
      'available' => backend_available,
      'tz_offset_hours' => backend_tz_offset_hours
    )
  end

  let(:frontend_reviewer) do
    Gitlab::Danger::Teammate.new(
      'username' => 'frontend-reviewer',
      'name' => 'Frontend reviewer',
      'role' => 'Frontend engineer',
      'projects' => { 'gitlab' => 'reviewer frontend' },
      'available' => true,
      'tz_offset_hours' => 2.0
    )
  end

  let(:frontend_maintainer) do
    Gitlab::Danger::Teammate.new(
      'username' => 'frontend-maintainer',
      'name' => 'Frontend maintainer',
      'role' => 'Frontend engineer',
      'projects' => { 'gitlab' => "maintainer frontend" },
      'available' => true,
      'tz_offset_hours' => 2.0
    )
  end

  let(:software_engineer_in_test) do
    Gitlab::Danger::Teammate.new(
      'username' => 'software-engineer-in-test',
      'name' => 'Software Engineer in Test',
      'role' => 'Software Engineer in Test, Create:Source Code',
      'projects' => { 'gitlab' => 'reviewer qa', 'gitlab-qa' => 'maintainer' },
      'available' => true,
      'tz_offset_hours' => 2.0
    )
  end

  let(:engineering_productivity_reviewer) do
    Gitlab::Danger::Teammate.new(
      'username' => 'eng-prod-reviewer',
      'name' => 'EP engineer',
      'role' => 'Engineering Productivity',
      'projects' => { 'gitlab' => 'reviewer backend' },
      'available' => true,
      'tz_offset_hours' => 2.0
    )
  end

  let(:ci_template_reviewer) do
    Gitlab::Danger::Teammate.new(
      'username' => 'ci-template-maintainer',
      'name' => 'CI Template engineer',
      'role' => '~"ci::templates"',
      'projects' => { 'gitlab' => 'reviewer ci_template' },
      'available' => true,
      'tz_offset_hours' => 2.0
    )
  end

  let(:teammates) do
    [
      backend_maintainer.to_h,
      frontend_maintainer.to_h,
      frontend_reviewer.to_h,
      software_engineer_in_test.to_h,
      engineering_productivity_reviewer.to_h,
      ci_template_reviewer.to_h
    ]
  end

  let(:teammate_json) do
    teammates.to_json
  end

  subject(:roulette) { Object.new.extend(described_class) }

  describe 'Spin#==' do
    it 'compares Spin attributes' do
      spin1 = described_class::Spin.new(:backend, frontend_reviewer, frontend_maintainer, false, false)
      spin2 = described_class::Spin.new(:backend, frontend_reviewer, frontend_maintainer, false, false)
      spin3 = described_class::Spin.new(:backend, frontend_reviewer, frontend_maintainer, false, true)
      spin4 = described_class::Spin.new(:backend, frontend_reviewer, frontend_maintainer, true, false)
      spin5 = described_class::Spin.new(:backend, frontend_reviewer, backend_maintainer, false, false)
      spin6 = described_class::Spin.new(:backend, backend_maintainer, frontend_maintainer, false, false)
      spin7 = described_class::Spin.new(:frontend, frontend_reviewer, frontend_maintainer, false, false)

      expect(spin1).to eq(spin2)
      expect(spin1).not_to eq(spin3)
      expect(spin1).not_to eq(spin4)
      expect(spin1).not_to eq(spin5)
      expect(spin1).not_to eq(spin6)
      expect(spin1).not_to eq(spin7)
    end
  end

  describe '#spin' do
    let!(:project) { 'gitlab' }
    let!(:mr_source_branch) { 'a-branch' }
    let!(:mr_labels) { ['backend', 'devops::create'] }
    let!(:author) { Gitlab::Danger::Teammate.new('username' => 'johndoe') }
    let(:timezone_experiment) { false }
    let(:spins) do
      # Stub the request at the latest time so that we can modify the raw data, e.g. available fields.
      WebMock
        .stub_request(:get, described_class::ROULETTE_DATA_URL)
        .to_return(body: teammate_json)

      subject.spin(project, categories, timezone_experiment: timezone_experiment)
    end

    before do
      allow(subject).to receive(:mr_author_username).and_return(author.username)
      allow(subject).to receive(:mr_labels).and_return(mr_labels)
      allow(subject).to receive(:mr_source_branch).and_return(mr_source_branch)
    end

    context 'when timezone_experiment == false' do
      context 'when change contains backend category' do
        let(:categories) { [:backend] }

        it 'assigns backend reviewer and maintainer' do
          expect(spins[0].reviewer).to eq(engineering_productivity_reviewer)
          expect(spins[0].maintainer).to eq(backend_maintainer)
          expect(spins).to eq([described_class::Spin.new(:backend, engineering_productivity_reviewer, backend_maintainer, false, false)])
        end

        context 'when teammate is not available' do
          let(:backend_available) { false }

          it 'assigns backend reviewer and no maintainer' do
            expect(spins).to eq([described_class::Spin.new(:backend, engineering_productivity_reviewer, nil, false, false)])
          end
        end
      end

      context 'when change contains frontend category' do
        let(:categories) { [:frontend] }

        it 'assigns frontend reviewer and maintainer' do
          expect(spins).to eq([described_class::Spin.new(:frontend, frontend_reviewer, frontend_maintainer, false, false)])
        end
      end

      context 'when change contains many categories' do
        let(:categories) { [:frontend, :test, :qa, :engineering_productivity, :ci_template, :backend] }

        it 'has a deterministic sorting order' do
          expect(spins.map(&:category)).to eq categories.sort
        end
      end

      context 'when change contains QA category' do
        let(:categories) { [:qa] }

        it 'assigns QA reviewer' do
          expect(spins).to eq([described_class::Spin.new(:qa, software_engineer_in_test, nil, false, false)])
        end
      end

      context 'when change contains Engineering Productivity category' do
        let(:categories) { [:engineering_productivity] }

        it 'assigns Engineering Productivity reviewer and fallback to backend maintainer' do
          expect(spins).to eq([described_class::Spin.new(:engineering_productivity, engineering_productivity_reviewer, backend_maintainer, false, false)])
        end
      end

      context 'when change contains CI/CD Template category' do
        let(:categories) { [:ci_template] }

        it 'assigns CI/CD Template reviewer and fallback to backend maintainer' do
          expect(spins).to eq([described_class::Spin.new(:ci_template, ci_template_reviewer, backend_maintainer, false, false)])
        end
      end

      context 'when change contains test category' do
        let(:categories) { [:test] }

        it 'assigns corresponding SET' do
          expect(spins).to eq([described_class::Spin.new(:test, software_engineer_in_test, nil, :maintainer, false)])
        end
      end
    end

    context 'when timezone_experiment == true' do
      let(:timezone_experiment) { true }

      context 'when change contains backend category' do
        let(:categories) { [:backend] }

        it 'assigns backend reviewer and maintainer' do
          expect(spins).to eq([described_class::Spin.new(:backend, engineering_productivity_reviewer, backend_maintainer, false, true)])
        end

        context 'when teammate is not in a good timezone' do
          let(:backend_tz_offset_hours) { 5.0 }

          it 'assigns backend reviewer and no maintainer' do
            expect(spins).to eq([described_class::Spin.new(:backend, engineering_productivity_reviewer, nil, false, true)])
          end
        end
      end

      context 'when change includes a category with timezone disabled' do
        let(:categories) { [:backend] }

        before do
          stub_const("#{described_class}::INCLUDE_TIMEZONE_FOR_CATEGORY", backend: false)
        end

        it 'assigns backend reviewer and maintainer' do
          expect(spins).to eq([described_class::Spin.new(:backend, engineering_productivity_reviewer, backend_maintainer, false, false)])
        end

        context 'when teammate is not in a good timezone' do
          let(:backend_tz_offset_hours) { 5.0 }

          it 'assigns backend reviewer and maintainer' do
            expect(spins).to eq([described_class::Spin.new(:backend, engineering_productivity_reviewer, backend_maintainer, false, false)])
          end
        end
      end
    end

    describe 'reviewer suggestion probability' do
      let(:reviewer) { teammate_with_capability('reviewer', 'reviewer backend') }
      let(:hungry_reviewer) { teammate_with_capability('hungry_reviewer', 'reviewer backend', hungry: true) }
      let(:traintainer) { teammate_with_capability('traintainer', 'trainee_maintainer backend') }
      let(:hungry_traintainer) { teammate_with_capability('hungry_traintainer', 'trainee_maintainer backend', hungry: true) }
      let(:teammates) do
        [
          reviewer.to_h,
          hungry_reviewer.to_h,
          traintainer.to_h,
          hungry_traintainer.to_h
        ]
      end

      let(:categories) { [:backend] }

      # This test is testing probability with inherent randomness.
      # The variance is inversely related to sample size
      # Given large enough sample size, the variance would be smaller,
      # but the test would take longer.
      # Given smaller sample size, the variance would be larger,
      # but the test would take less time.
      let!(:sample_size) { 500 }
      let!(:variance) { 0.1 }

      before do
        # This test needs actual randomness to simulate probabilities
        allow(subject).to receive(:new_random).and_return(Random.new)
        WebMock
          .stub_request(:get, described_class::ROULETTE_DATA_URL)
          .to_return(body: teammate_json)
      end

      it 'has 1:2:3:4 probability of picking reviewer, hungry_reviewer, traintainer, hungry_traintainer' do
        picks = Array.new(sample_size).map do
          spins = subject.spin(project, categories, timezone_experiment: timezone_experiment)
          spins.first.reviewer.name
        end

        expect(probability(picks, 'reviewer')).to be_within(variance).of(0.1)
        expect(probability(picks, 'hungry_reviewer')).to be_within(variance).of(0.2)
        expect(probability(picks, 'traintainer')).to be_within(variance).of(0.3)
        expect(probability(picks, 'hungry_traintainer')).to be_within(variance).of(0.4)
      end

      def probability(picks, role)
        picks.count(role).to_f / picks.length
      end

      def teammate_with_capability(name, capability, hungry: false)
        Gitlab::Danger::Teammate.new(
          {
            'name' => name,
            'projects' => {
              'gitlab' => capability
            },
            'available' => true,
            'hungry' => hungry
          }
        )
      end
    end
  end

  RSpec::Matchers.define :match_teammates do |expected|
    match do |actual|
      expected.each do |expected_person|
        actual_person_found = actual.find { |actual_person| actual_person.name == expected_person.username }

        actual_person_found &&
        actual_person_found.name == expected_person.name &&
        actual_person_found.role == expected_person.role &&
        actual_person_found.projects == expected_person.projects
      end
    end
  end

  describe '#team' do
    subject(:team) { roulette.team }

    context 'HTTP failure' do
      before do
        WebMock
          .stub_request(:get, described_class::ROULETTE_DATA_URL)
          .to_return(status: 404)
      end

      it 'raises a pretty error' do
        expect { team }.to raise_error(/Failed to read/)
      end
    end

    context 'JSON failure' do
      before do
        WebMock
          .stub_request(:get, described_class::ROULETTE_DATA_URL)
          .to_return(body: 'INVALID JSON')
      end

      it 'raises a pretty error' do
        expect { team }.to raise_error(/Failed to parse/)
      end
    end

    context 'success' do
      before do
        WebMock
          .stub_request(:get, described_class::ROULETTE_DATA_URL)
          .to_return(body: teammate_json)
      end

      it 'returns an array of teammates' do
        is_expected.to match_teammates([
          backend_maintainer,
          frontend_reviewer,
          frontend_maintainer,
          software_engineer_in_test,
          engineering_productivity_reviewer,
          ci_template_reviewer
        ])
      end

      it 'memoizes the result' do
        expect(team.object_id).to eq(roulette.team.object_id)
      end
    end
  end

  describe '#project_team' do
    subject { roulette.project_team('gitlab-qa') }

    before do
      WebMock
        .stub_request(:get, described_class::ROULETTE_DATA_URL)
        .to_return(body: teammate_json)
    end

    it 'filters team by project_name' do
      is_expected.to match_teammates([
        software_engineer_in_test
      ])
    end
  end

  describe '#spin_for_person' do
    let(:person_tz_offset_hours) { 0.0 }
    let(:person1) do
      Gitlab::Danger::Teammate.new(
        'username' => 'user1',
        'available' => true,
        'tz_offset_hours' => person_tz_offset_hours
      )
    end

    let(:person2) do
      Gitlab::Danger::Teammate.new(
        'username' => 'user2',
        'available' => true,
        'tz_offset_hours' => person_tz_offset_hours)
    end

    let(:author) do
      Gitlab::Danger::Teammate.new(
        'username' => 'johndoe',
        'available' => true,
        'tz_offset_hours' => 0.0)
    end

    let(:unavailable) do
      Gitlab::Danger::Teammate.new(
        'username' => 'janedoe',
        'available' => false,
        'tz_offset_hours' => 0.0)
    end

    before do
      allow(subject).to receive(:mr_author_username).and_return(author.username)
    end

    (-4..4).each do |utc_offset|
      context "when local hour for person is #{10 + utc_offset} (offset: #{utc_offset})" do
        let(:person_tz_offset_hours) { utc_offset }

        [false, true].each do |timezone_experiment|
          context "with timezone_experiment == #{timezone_experiment}" do
            it 'returns a random person' do
              persons = [person1, person2]

              selected = subject.spin_for_person(persons, random: Random.new, timezone_experiment: timezone_experiment)

              expect(persons.map(&:username)).to include(selected.username)
            end
          end
        end
      end
    end

    ((-12..-5).to_a + (5..12).to_a).each do |utc_offset|
      context "when local hour for person is #{10 + utc_offset} (offset: #{utc_offset})" do
        let(:person_tz_offset_hours) { utc_offset }

        [false, true].each do |timezone_experiment|
          context "with timezone_experiment == #{timezone_experiment}" do
            it 'returns a random person or nil' do
              persons = [person1, person2]

              selected = subject.spin_for_person(persons, random: Random.new, timezone_experiment: timezone_experiment)

              if timezone_experiment
                expect(selected).to be_nil
              else
                expect(persons.map(&:username)).to include(selected.username)
              end
            end
          end
        end
      end
    end

    it 'excludes unavailable persons' do
      expect(subject.spin_for_person([unavailable], random: Random.new)).to be_nil
    end

    it 'excludes mr.author' do
      expect(subject.spin_for_person([author], random: Random.new)).to be_nil
    end
  end
end
