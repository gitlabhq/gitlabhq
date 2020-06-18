# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'

require 'gitlab/danger/roulette'

describe Gitlab::Danger::Roulette do
  let(:backend_maintainer) do
    {
      username: 'backend-maintainer',
      name: 'Backend maintainer',
      role: 'Backend engineer',
      projects: { 'gitlab' => 'maintainer backend' }
    }
  end
  let(:frontend_reviewer) do
    {
      username: 'frontend-reviewer',
      name: 'Frontend reviewer',
      role: 'Frontend engineer',
      projects: { 'gitlab' => 'reviewer frontend' }
    }
  end
  let(:frontend_maintainer) do
    {
      username: 'frontend-maintainer',
      name: 'Frontend maintainer',
      role: 'Frontend engineer',
      projects: { 'gitlab' => "maintainer frontend" }
    }
  end
  let(:software_engineer_in_test) do
    {
      username: 'software-engineer-in-test',
      name: 'Software Engineer in Test',
      role: 'Software Engineer in Test, Create:Source Code',
      projects: {
        'gitlab' => 'reviewer qa',
        'gitlab-qa' => 'maintainer'
      }
    }
  end
  let(:engineering_productivity_reviewer) do
    {
      username: 'eng-prod-reviewer',
      name: 'EP engineer',
      role: 'Engineering Productivity',
      projects: { 'gitlab' => 'reviewer backend' }
    }
  end

  let(:teammate_json) do
    [
      backend_maintainer,
      frontend_maintainer,
      frontend_reviewer,
      software_engineer_in_test,
      engineering_productivity_reviewer
    ].to_json
  end

  subject(:roulette) { Object.new.extend(described_class) }

  def matching_teammate(person)
    satisfy do |teammate|
      teammate.username == person[:username] &&
        teammate.name == person[:name] &&
        teammate.role == person[:role] &&
        teammate.projects == person[:projects]
    end
  end

  def matching_spin(category, reviewer: { username: nil }, maintainer: { username: nil }, optional: nil)
    satisfy do |spin|
      spin.category == category &&
        spin.reviewer&.username == reviewer[:username] &&
        spin.maintainer&.username == maintainer[:username] &&
        spin.optional_role == optional
    end
  end

  describe '#spin' do
    let!(:project) { 'gitlab' }
    let!(:branch_name) { 'a-branch' }
    let!(:mr_labels) { ['backend', 'devops::create'] }
    let!(:author) { Gitlab::Danger::Teammate.new('username' => 'filipa') }

    before do
      [
        backend_maintainer,
        frontend_reviewer,
        frontend_maintainer,
        software_engineer_in_test,
        engineering_productivity_reviewer
      ].each do |person|
        stub_person_status(instance_double(Gitlab::Danger::Teammate, username: person[:username]), message: 'making GitLab magic')
      end

      WebMock
        .stub_request(:get, described_class::ROULETTE_DATA_URL)
        .to_return(body: teammate_json)
      allow(subject).to receive_message_chain(:gitlab, :mr_author).and_return(author.username)
      allow(subject).to receive_message_chain(:gitlab, :mr_labels).and_return(mr_labels)
    end

    context 'when change contains backend category' do
      it 'assigns backend reviewer and maintainer' do
        categories = [:backend]
        spins = subject.spin(project, categories, branch_name)

        expect(spins).to contain_exactly(matching_spin(:backend, reviewer: engineering_productivity_reviewer, maintainer: backend_maintainer))
      end
    end

    context 'when change contains frontend category' do
      it 'assigns frontend reviewer and maintainer' do
        categories = [:frontend]
        spins = subject.spin(project, categories, branch_name)

        expect(spins).to contain_exactly(matching_spin(:frontend, reviewer: frontend_reviewer, maintainer: frontend_maintainer))
      end
    end

    context 'when change contains QA category' do
      it 'assigns QA reviewer and sets optional QA maintainer' do
        categories = [:qa]
        spins = subject.spin(project, categories, branch_name)

        expect(spins).to contain_exactly(matching_spin(:qa, reviewer: software_engineer_in_test, optional: :maintainer))
      end
    end

    context 'when change contains Engineering Productivity category' do
      it 'assigns Engineering Productivity reviewer and fallback to backend maintainer' do
        categories = [:engineering_productivity]
        spins = subject.spin(project, categories, branch_name)

        expect(spins).to contain_exactly(matching_spin(:engineering_productivity, reviewer: engineering_productivity_reviewer, maintainer: backend_maintainer))
      end
    end

    context 'when change contains test category' do
      it 'assigns corresponding SET and sets optional test maintainer' do
        categories = [:test]
        spins = subject.spin(project, categories, branch_name)

        expect(spins).to contain_exactly(matching_spin(:test, reviewer: software_engineer_in_test, optional: :maintainer))
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
        expected_teammates = [
          matching_teammate(backend_maintainer),
          matching_teammate(frontend_reviewer),
          matching_teammate(frontend_maintainer),
          matching_teammate(software_engineer_in_test),
          matching_teammate(engineering_productivity_reviewer)
        ]

        is_expected.to contain_exactly(*expected_teammates)
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
      is_expected.to contain_exactly(matching_teammate(software_engineer_in_test))
    end
  end

  describe '#spin_for_person' do
    let(:person1) { Gitlab::Danger::Teammate.new('username' => 'rymai') }
    let(:person2) { Gitlab::Danger::Teammate.new('username' => 'godfat') }
    let(:author) { Gitlab::Danger::Teammate.new('username' => 'filipa') }
    let(:ooo) { Gitlab::Danger::Teammate.new('username' => 'jacopo-beschi') }
    let(:no_capacity) { Gitlab::Danger::Teammate.new('username' => 'uncharged') }

    before do
      stub_person_status(person1, message: 'making GitLab magic')
      stub_person_status(person2, message: 'making GitLab magic')
      stub_person_status(ooo, message: 'OOO till 15th')
      stub_person_status(no_capacity, message: 'At capacity for the next few days', emoji: 'red_circle')
      # we don't stub Filipa, as she is the author and
      # we should not fire request checking for her

      allow(subject).to receive_message_chain(:gitlab, :mr_author).and_return(author.username)
    end

    it 'returns a random person' do
      persons = [person1, person2]

      selected = subject.spin_for_person(persons, random: Random.new)

      expect(selected.username).to be_in(persons.map(&:username))
    end

    it 'excludes OOO persons' do
      expect(subject.spin_for_person([ooo], random: Random.new)).to be_nil
    end

    it 'excludes mr.author' do
      expect(subject.spin_for_person([author], random: Random.new)).to be_nil
    end

    it 'excludes person with no capacity' do
      expect(subject.spin_for_person([no_capacity], random: Random.new)).to be_nil
    end
  end

  private

  def stub_person_status(person, message: 'dummy message', emoji: 'unicorn')
    body = { message: message, emoji: emoji }.to_json

    WebMock
      .stub_request(:get, "https://gitlab.com/api/v4/users/#{person.username}/status")
      .to_return(body: body)
  end
end
