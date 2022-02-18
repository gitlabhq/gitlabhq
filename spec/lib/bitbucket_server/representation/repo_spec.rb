# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::Repo do
  let(:sample_data) do
    <<~DATA
    {
      "slug": "rouge",
      "id": 1,
      "name": "rouge",
      "description": "Rogue Repo",
      "scmId": "git",
      "state": "AVAILABLE",
      "statusMessage": "Available",
      "forkable": true,
      "project": {
        "key": "TEST",
        "id": 1,
        "name": "test",
        "description": "Test Project",
        "public": false,
        "type": "NORMAL",
        "links": {
          "self": [
            {
              "href": "http://localhost:7990/projects/TEST"
            }
          ]
        }
      },
      "public": false,
      "links": {
        "clone": [
          {
            "href": "http://root@localhost:7990/scm/test/rouge.git",
            "name": "http"
          },
          {
            "href": "ssh://git@localhost:7999/test/rouge.git",
            "name": "ssh"
          }
        ],
        "self": [
          {
            "href": "http://localhost:7990/projects/TEST/repos/rouge/browse"
          }
        ]
      }
    }
    DATA
  end

  subject { described_class.new(Gitlab::Json.parse(sample_data)) }

  describe '#project_key' do
    it { expect(subject.project_key).to eq('TEST') }
  end

  describe '#project_name' do
    it { expect(subject.project_name).to eq('test') }
  end

  describe '#slug' do
    it { expect(subject.slug).to eq('rouge') }
  end

  describe '#browse_url' do
    it { expect(subject.browse_url).to eq('http://localhost:7990/projects/TEST/repos/rouge/browse') }
  end

  describe '#clone_url' do
    it { expect(subject.clone_url).to eq('http://root@localhost:7990/scm/test/rouge.git') }
  end

  describe '#description' do
    it { expect(subject.description).to eq('Rogue Repo') }
  end

  describe '#full_name' do
    it { expect(subject.full_name).to eq('test/rouge') }
  end
end
