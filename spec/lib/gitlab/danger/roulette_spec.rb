# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'

require 'gitlab/danger/roulette'

describe Gitlab::Danger::Roulette do
  let(:teammate_json) do
    <<~JSON
    [
      {
        "username": "in-gitlab-ce",
        "name": "CE maintainer",
        "projects":{ "gitlab-ce": "maintainer backend" }
      },
      {
        "username": "in-gitlab-ee",
        "name": "EE reviewer",
        "projects":{ "gitlab-ee": "reviewer frontend" }
      }
    ]
    JSON
  end

  let(:ce_teammate_matcher) do
    satisfy do |teammate|
      teammate.username == 'in-gitlab-ce' &&
        teammate.name == 'CE maintainer' &&
        teammate.projects == { 'gitlab-ce' => 'maintainer backend' }
    end
  end

  let(:ee_teammate_matcher) do
    satisfy do |teammate|
      teammate.username == 'in-gitlab-ee' &&
        teammate.name == 'EE reviewer' &&
        teammate.projects == { 'gitlab-ee' => 'reviewer frontend' }
    end
  end

  subject(:roulette) { Object.new.extend(described_class) }

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
        is_expected.to contain_exactly(ce_teammate_matcher, ee_teammate_matcher)
      end

      it 'memoizes the result' do
        expect(team.object_id).to eq(roulette.team.object_id)
      end
    end
  end

  describe '#project_team' do
    subject { roulette.project_team('gitlab-ce') }

    before do
      WebMock
        .stub_request(:get, described_class::ROULETTE_DATA_URL)
        .to_return(body: teammate_json)
    end

    it 'filters team by project_name' do
      is_expected.to contain_exactly(ce_teammate_matcher)
    end
  end

  describe '#spin_for_person' do
    let(:person1) { Gitlab::Danger::Teammate.new('username' => 'rymai') }
    let(:person2) { Gitlab::Danger::Teammate.new('username' => 'godfat') }
    let(:author) { Gitlab::Danger::Teammate.new('username' => 'filipa') }
    let(:ooo) { Gitlab::Danger::Teammate.new('username' => 'jacopo-beschi') }

    before do
      stub_person_message(person1, 'making GitLab magic')
      stub_person_message(person2, 'making GitLab magic')
      stub_person_message(ooo, 'OOO till 15th')
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

    private

    def stub_person_message(person, message)
      body = { message: message }.to_json

      WebMock
        .stub_request(:get, "https://gitlab.com/api/v4/users/#{person.username}/status")
        .to_return(body: body)
    end
  end
end
