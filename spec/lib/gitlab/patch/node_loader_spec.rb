# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::NodeLoader, feature_category: :redis do
  using RSpec::Parameterized::TableSyntax

  describe '#fetch_node_info' do
    let(:redis) { double(:redis) } # rubocop:disable RSpec/VerifiedDoubles

    # rubocop:disable Naming/InclusiveLanguage
    where(:case_name, :args, :value) do
      [
        [
          'when only ip address is present',
          "07c37df 127.0.0.1:30004@31004 slave e7d1eec 0 1426238317239 4 connected
67ed2db 127.0.0.1:30002@31002 master - 0 1426238316232 2 connected 5461-10922
292f8b3 127.0.0.1:30003@31003 master - 0 1426238318243 3 connected 10923-16383
6ec2392 127.0.0.1:30005@31005 slave 67ed2db 0 1426238316232 5 connected
824fe11 127.0.0.1:30006@31006 slave 292f8b3 0 1426238317741 6 connected
e7d1eec 127.0.0.1:30001@31001 myself,master - 0 0 1 connected 0-5460",
          {
            '127.0.0.1:30004' => 'slave', '127.0.0.1:30002' => 'master', '127.0.0.1:30003' => 'master',
            '127.0.0.1:30005' => 'slave', '127.0.0.1:30006' => 'slave', '127.0.0.1:30001' => 'master'
          }
        ],
        [
          'when hostname is present',
          "07c37df 127.0.0.1:30004@31004,host1 slave e7d1eec 0 1426238317239 4 connected
67ed2db 127.0.0.1:30002@31002,host2 master - 0 1426238316232 2 connected 5461-10922
292f8b3 127.0.0.1:30003@31003,host3 master - 0 1426238318243 3 connected 10923-16383
6ec2392 127.0.0.1:30005@31005,host4 slave 67ed2db 0 1426238316232 5 connected
824fe11 127.0.0.1:30006@31006,host5 slave 292f8b3 0 1426238317741 6 connected
e7d1eec 127.0.0.1:30001@31001,host6 myself,master - 0 0 1 connected 0-5460",
          {
            'host1:30004' => 'slave', 'host2:30002' => 'master', 'host3:30003' => 'master',
            'host4:30005' => 'slave', 'host5:30006' => 'slave', 'host6:30001' => 'master'
          }
        ],
        [
          'when auxiliary fields are present',
          "07c37df 127.0.0.1:30004@31004,,shard-id=69bc slave e7d1eec 0 1426238317239 4 connected
67ed2db 127.0.0.1:30002@31002,,shard-id=114f master - 0 1426238316232 2 connected 5461-10922
292f8b3 127.0.0.1:30003@31003,,shard-id=fdb3 master - 0 1426238318243 3 connected 10923-16383
6ec2392 127.0.0.1:30005@31005,,shard-id=114f slave 67ed2db 0 1426238316232 5 connected
824fe11 127.0.0.1:30006@31006,,shard-id=fdb3 slave 292f8b3 0 1426238317741 6 connected
e7d1eec 127.0.0.1:30001@31001,,shard-id=69bc myself,master - 0 0 1 connected 0-5460",
          {
            '127.0.0.1:30004' => 'slave', '127.0.0.1:30002' => 'master', '127.0.0.1:30003' => 'master',
            '127.0.0.1:30005' => 'slave', '127.0.0.1:30006' => 'slave', '127.0.0.1:30001' => 'master'
          }
        ],
        [
          'when hostname and auxiliary fields are present',
          "07c37df 127.0.0.1:30004@31004,host1,shard-id=69bc slave e7d1eec 0 1426238317239 4 connected
67ed2db 127.0.0.1:30002@31002,host2,shard-id=114f master - 0 1426238316232 2 connected 5461-10922
292f8b3 127.0.0.1:30003@31003,host3,shard-id=fdb3 master - 0 1426238318243 3 connected 10923-16383
6ec2392 127.0.0.1:30005@31005,host4,shard-id=114f slave 67ed2db 0 1426238316232 5 connected
824fe11 127.0.0.1:30006@31006,host5,shard-id=fdb3 slave 292f8b3 0 1426238317741 6 connected
e7d1eec 127.0.0.1:30001@31001,host6,shard-id=69bc myself,master - 0 0 1 connected 0-5460",
          {
            'host1:30004' => 'slave', 'host2:30002' => 'master', 'host3:30003' => 'master',
            'host4:30005' => 'slave', 'host5:30006' => 'slave', 'host6:30001' => 'master'
          }
        ]
      ]
    end
    # rubocop:enable Naming/InclusiveLanguage

    with_them do
      before do
        allow(redis).to receive(:call).with([:cluster, :nodes]).and_return(args)
      end

      it do
        expect(Redis::Cluster::NodeLoader.load_flags([redis])).to eq(value)
      end
    end
  end
end
