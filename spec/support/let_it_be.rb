# frozen_string_literal: true

TestProf::LetItBe.configure do |config|
  config.alias_to :let_it_be_with_refind, refind: true
end

TestProf::LetItBe.configure do |config|
  config.alias_to :let_it_be_with_reload, reload: true
end
