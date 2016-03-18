require 'spec_helper'

describe "Indexer" do
  it "runs commands" do
    expect(Gitlab::Popen).to receive(:popen).with(
      [File.join(Rails.root, 'bin/elastic_repo_indexer'), '1', 'full_repo_path'],
      nil,
      hash_including(
        'ELASTIC_CONNECTION_INFO' => {
                                       host: Gitlab.config.elasticsearch.host,
                                       port: Gitlab.config.elasticsearch.port
                                     }.to_json,
        'RAILS_ENV'               => Rails.env,
        'FROM_SHA' => '000000',
        'TO_SHA' => '1d1f2d'
      )
    ).and_return([[''], 0])

    Elastic::Indexer.new.run(1, 'full_repo_path', '000000', '1d1f2d')
  end
end
