require 'non-stupid-digest-assets'
require 'minitest/autorun'
require 'mocha/test_unit'

class MiniTest::Test
  def teardown
    NonStupidDigestAssets.whitelist = []
    Mocha::Mockery.instance.teardown
    Mocha::Mockery.reset_instance
  end
end
