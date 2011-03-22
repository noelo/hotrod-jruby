require "test/unit"
require "java"
require "src/RemoteCache"
require "src/infinispanError"
require "src/versioned_value"
require "test/CacheValueClass"

class RemoteCache_test < Test::Unit::TestCase
  def test_started
    x = RemoteCache.new
    assert(x.started?, "Failed to start cache")
  end

  def test_stopped
    x = RemoteCache.new
    x.stop
    assert(!x.started?, "Failed to stop cache")
  end

  def test_retrieve_default_cache
    assert_not_nil(RemoteCache.new, "Failed to retrieve default cache")
  end

  def test_retrieve_invalid_cache
    tmp = java.lang.System.currentTimeMillis.to_s
    puts "checking for cache name #{tmp}"
    assert_raise(InfinispanError) { x = RemoteCache.new(tmp) }
  end

  def test_insert_retrieve_basic
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    x.put(tmpKey, tmpVal)
    retVal = x.get(tmpKey)
    assert((tmpVal.eql? retVal), "Retrieved value #{retVal} not the same as the inserted value #{tmpVal}")
  end

  def test_expired_key
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    x.put(tmpKey, tmpVal, 5)
    sleep(6)
    assert_nil(x.get(tmpKey), "Value was found for key #{tmpKey}, it should have expired and been evicted")
  end

  def test_insert_retrieve_class
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = CacheValueClass.new("aval", "bval")
    x.put(tmpKey, tmpVal)
    retVal = x.get(tmpKey)
    assert_equal(tmpVal, retVal, "Retrieved value #{retVal} not the same as the inserted value #{tmpVal}")
    tmpVal2 = CacheValueClass.new("aval2", "bval2")
    x.put(tmpKey, tmpVal2)
    retVal = x.get(tmpKey)
    assert_not_equal(tmpVal, retVal, "Retrieved value #{retVal} should not be the same as the initial inserted value #{tmpVal}")
  end

  def test_version
    x = RemoteCache.new
    assert_not_equal(x.version, "Unable to retrieve infinispan version")
  end

  def test_remove
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = CacheValueClass.new("aval", "bval")
    x.put(tmpKey, tmpVal)
    assert(!x.get(tmpKey).nil?, "Failed to get inserted object")
    x.remove(tmpKey)
    assert_nil(x.get(tmpKey), "Object present when it should have been removed")
  end

  def test_size
    x = RemoteCache.new
    x.clear
    10.times do |i|
      x.put(i, i)
    end
    assert_same(x.size, 10, "Incorrect cache size returned")
  end

  def test_putAll
    x = RemoteCache.new
    x.clear
    mapIN = Hash.new
    100.times do |i|
      mapIN.store(i, i*10)
    end
    puts "Num elements being added #{mapIN.size}"
    x.putAll(mapIN)
    assert_same(x.size, 100, "Incorrect cache entry count")
  end

  def test_get_VersionedValue
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    x.put(tmpKey, tmpVal)
    retVal = x.getVersioned(tmpKey)
    puts retVal
    assert((tmpVal.eql? retVal.value), "Retrieved value #{retVal} not the same as the inserted value #{tmpVal}")
  end

  def test_replace
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = CacheValueClass.new("aval", "bval")
    x.replace(tmpKey, tmpVal)
    retVal = x.get(tmpKey)
    assert_nil(retVal, "Replace should not insert a value if not already present")

    x.put(tmpKey, tmpVal)
    retVal = x.get(tmpKey)
    assert_not_nil(retVal, "Put should have inserted a value")

    val2 = CacheValueClass.new("cval", "dval")
    x.replace(tmpKey, val2)
    retVal = x.get(tmpKey)
    assert_equal(retVal, val2, "Value should have been replaced")
  end

  def test_get_VersionedValue_replace
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    x.put(tmpKey, tmpVal)
    retVal = x.getVersioned(tmpKey)
    puts retVal

    newVal = tmpVal+"fff"
    x.replaceWithVersion(tmpKey, newVal, retVal.version)
    retVal2 = x.getVersioned(tmpKey)

    assert_not_equal(retVal.version, retVal2.version, "Version values should differ")
  end

  def test_get_VersionedValue_remove
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    x.put(tmpKey, tmpVal)
    retVal = x.getVersioned(tmpKey)
    puts retVal

    x.removeWithVersion(tmpKey, retVal.version)
    retVal2 = x.getVersioned(tmpKey)
    assert_nil(retVal2, "Value shouldn't exist in cache")
  end


  def test_putIfAbsent
    x = RemoteCache.new
    tmpKey = java.lang.System.currentTimeMillis.to_s
    tmpVal = java.lang.System.currentTimeMillis.to_s
    x.put(tmpKey, tmpVal)
    retVal = x.get(tmpKey)

    newVal = tmpVal+"FFF"
    x.putIfAbsent(tmpKey, newVal)
    retVal2 = x.get(tmpKey)

    assert_equal(retVal,retVal2,"New value inserted into cache")
  end
end