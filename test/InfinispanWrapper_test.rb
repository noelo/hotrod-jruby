require "test/unit"
require "java"
require "src/infinispan_wrapper"
require "src/infinispanError"
require "test/CacheValueClass"

class InfinispanWrapper_test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @x = InfinispanWrapper.new
    @x.start
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    @x.stop
  end

  # Fake test
  def test_started
    assert(@x.started?, "Failed to start cache")
  end

  def test_stopped
    @x.stop
    assert(!@x.started?, "Failed to stop cache")
  end

  def test_retrieve_default_cache
    assert(!@x.cache.nil?, "Failed to retrieve default cache")
  end

  def test_retrieve_invalid_cache
    tmp = java.lang.System.currentTimeMillis.to_s
    puts "checking for cache name #{tmp}"
    assert_raise(InfinispanError) { @x.cache(tmp) }
  end

  def test_insert_retrieve_basic
    @x.cache
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    @x.put(tmpKey, tmpVal)
    retVal = @x.get(tmpKey)
    assert((tmpVal.eql? retVal), "Retrieved value #{retVal} not the same as the inserted value #{tmpVal}")
  end

  def test_expired_key
    @x.cache
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    @x.put(tmpKey, tmpVal, 5)
    sleep(6)
    assert_nil(@x.get(tmpKey), "Value was found for key #{tmpKey}, it should have expired and been evicted")
  end

  def test_containsValue
    @x.cache
    tmpKey = java.lang.System.currentTimeMillis.to_s #+ "j"
    tmpVal = java.lang.System.currentTimeMillis.to_s #+ "j"
    begin
      @x.put(tmpKey, tmpVal)

      # assert should have worked but it doesn't
      #assert_raise(java.lang.UnsupportedOperationException) { @x.containsValue?(tmpVal) }
      @x.containsValue?(tmpVal)
      assert(false, " this should have thrown a java.lang.UnsupportedOperationException")
    rescue java.lang.UnsupportedOperationException
      puts "Expected exception caught #{$!}"
    end
  end

  def test_insert_retrieve_class
    @x.cache
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = CacheValueClass.new("aval", "bval")
    @x.put(tmpKey, tmpVal)
    retVal = @x.get(tmpKey)
    assert_equal(tmpVal, retVal, "Retrieved value #{retVal} not the same as the inserted value #{tmpVal}")
    tmpVal2 = CacheValueClass.new("aval2", "bval2")
    @x.put(tmpKey, tmpVal2)
    retVal = @x.get(tmpKey)
    assert_not_equal(tmpVal, retVal, "Retrieved value #{retVal} should not be the same as the initial inserted value #{tmpVal}")
  end

  def test_version
    @x.cache
    assert_not_equal(@x.version, "Unable to retrieve infinispan version")
  end

  def test_remove
    @x.cache
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = CacheValueClass.new("aval", "bval")
    @x.put(tmpKey, tmpVal)
    assert(!@x.get(tmpKey).nil?, "Failed to get inserted object")
    @x.remove(tmpKey)
    assert_nil(@x.get(tmpKey), "Object present when it should have been removed")
  end


  def test_size
    @x.cache
    @x.clear
    10.times do |i|
      @x.put(i, i)
    end
    assert_same(@x.size, 10, "Incorrect cache size returned")
  end

end