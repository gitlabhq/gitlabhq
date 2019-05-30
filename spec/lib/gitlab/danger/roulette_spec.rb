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
end
