# frozen_string_literal: true

RSpec.shared_examples 'default board creation allowed on GET' do
  let(:analyzer) { Gitlab::Database::QueryAnalyzers::PreventWritesOnGet }

  before do
    stub_feature_flags(detect_writes_on_get: true)
    allow(Gitlab::Middleware::QueryAnalyzer).to receive(:http_request_method).and_return('GET')
  end

  it 'does not report the default board creation as an unwrapped write on GET' do
    expect(analyzer::Logger).not_to receive(:warn)

    Gitlab::Database::QueryAnalyzer.instance.within([analyzer]) { list_boards }
  end
end

RSpec.shared_examples 'recent board visit allowed on GET' do
  let(:analyzer) { Gitlab::Database::QueryAnalyzers::PreventWritesOnGet }

  before do
    stub_feature_flags(detect_writes_on_get: true)
    allow(Gitlab::Middleware::QueryAnalyzer).to receive(:http_request_method).and_return('GET')
  end

  it 'does not report recording or refreshing the visit as an unwrapped write on GET' do
    expect(analyzer::Logger).not_to receive(:warn)

    Gitlab::Database::QueryAnalyzer.instance.within([analyzer]) do
      read_board(board: board)

      travel_to(ThrottledTouch::TOUCH_INTERVAL.from_now + 1.second) { read_board(board: board) }
    end
  end
end
