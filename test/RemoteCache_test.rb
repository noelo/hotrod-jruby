require "test/unit"
require 'rubygems'
require 'shoulda'
require "java"
require "lib/RemoteCache"
require "lib/infinispanError"
require "lib/versioned_value"
require "test/CacheValueClass"

class RemoteCache_test < Test::Unit::TestCase
  context "Constructor testing" do
    setup do
      puts "Ensure that the name localTestDNS can be resolved by DNS so that the client can connect to it"
    end

    should "Support constructor properties" do
      ctor_prop = {"infinispan.client.hotrod.server_list" => "localTestDNS:11222",
                   "infinispan.client.hotrod.force_return_values"=>"true"}
      x = RemoteCache.new("", ctor_prop)
      assert_not_nil(x, "Failed to retrieve default cache")

      @tmpKey = java.lang.System.currentTimeMillis.to_s
      @tmpVal = java.lang.System.currentTimeMillis.to_s
      x.put(@tmpKey, @tmpVal)

      retVal = x.remove(@tmpKey)
      assert_equal(@tmpVal, retVal, "Return value should have been returned")
    end
  end


  context "Cache initialization" do
    setup do
      @x = RemoteCache.new
    end

    should "Get default cache when no cache name supplied" do
      assert_not_nil(@x, "Failed to retrieve default cache")
    end

    should "Cache started when created" do
      assert(@x.started?, "Failed to start cache")
    end

    should "Cache stopped when told to" do
      @x.stop
      assert(!@x.started?, "Failed to stop cache")
    end

    should "Throw an exception when named cache is not defined on the server" do
      tmp = java.lang.System.currentTimeMillis.to_s
      puts "checking for cache name #{tmp}"
      assert_raise(InfinispanError) { RemoteCache.new(tmp) }
    end

    should "Return a version string" do
      assert_not_nil(@x.version, "Unable to retrieve infinispan version")
    end
  end


  context "Cache Insertion" do
    setup do
      @x = RemoteCache.new
      @tmpKey = java.lang.System.currentTimeMillis.to_s
      @tmpVal = java.lang.System.currentTimeMillis.to_s
    end

    should "Store and retrieve basic values correctly" do
      @x.put(@tmpKey, @tmpVal)
      retVal = @x.get(@tmpKey)
      assert((@tmpVal.eql? retVal), "Retrieved value #{retVal} not the same as the inserted value #{@tmpVal}")
    end

    should "Honor time to live eviction " do
      @x.put(@tmpKey, @tmpVal, false, 5)
      sleep(6)
      assert_nil(@x.get(@tmpKey), "Value was found for key #{@tmpKey}, it should have expired and been evicted")
    end

    should "Handle serialization of complex objects " do
      tmpVal2 = CacheValueClass.new("aval", "bval")
      @x.put(@tmpKey, tmpVal2)
      retVal = @x.get(@tmpKey)
      assert_equal(tmpVal2, retVal, "Retrieved value #{retVal} not the same as the inserted value #{tmpVal2}")
      tmpVal3 = CacheValueClass.new("aval2", "bval2")
      @x.put(@tmpKey, tmpVal3)
      retVal = @x.get(@tmpKey)
      assert_not_equal(tmpVal2, retVal, "Retrieved value #{retVal} should not be the same as the initial inserted value #{tmpVal2}")
    end

    should "putIfAbsent should only insert values if not already present in the cache" do
      @x.put(@tmpKey, @tmpVal)
      retVal = @x.get(@tmpKey)

      newVal = @tmpVal+"FFF"
      @x.putIfAbsent(@tmpKey, newVal)
      retVal2 = @x.get(@tmpKey)

      assert_equal(retVal, retVal2, "New value inserted into cache")
    end

    should "Cache size should correctly reflect number of insertions" do
      @x.clear
      10.times do |i|
        @x.put(i, i)
      end
      assert_same(@x.size, 10, "Incorrect cache size returned")
    end

    should "Correctly handle bulk insertions" do
      @x.clear
      mapIN = Hash.new
      100.times do |i|
        mapIN.store(i, i*10)
      end
      puts "Num elements being added #{mapIN.size}"
      @x.putAll(mapIN)
      assert_same(@x.size, 100, "Incorrect cache entry count")
    end
  end

  context "Cache Removal" do
    setup do
      @x = RemoteCache.new
      @tmpKey = java.lang.System.currentTimeMillis.to_s
      @tmpVal = java.lang.System.currentTimeMillis.to_s
      @x.put(@tmpKey, @tmpVal)
    end

    should "Handle removal of inserted objects" do
      tmpVal2 = CacheValueClass.new("aval", "bval")
      @x.put(@tmpKey, tmpVal2)
      assert(!@x.get(@tmpKey).nil?, "Failed to get inserted object")
      @x.remove(@tmpKey)
      assert_nil(@x.get(@tmpKey), "Object present when it should have been removed")
    end


    should "Handle versioned object retrieval" do
      retVal = @x.getVersioned(@tmpKey)
      puts retVal
      assert((@tmpVal.eql? retVal.value), "Retrieved value #{retVal} not the same as the inserted value #{@tmpVal}")
    end

    should "Handle replancement of inserted object" do
      @x.clear
      tmpVal2 = CacheValueClass.new("aval", "bval")
      @x.replace(@tmpKey, tmpVal2)
      retVal = @x.get(@tmpKey)
      assert_nil(retVal, "Replace should not insert a value if not already present")

      @x.put(@tmpKey, tmpVal2)
      retVal = @x.get(@tmpKey)
      assert_not_nil(retVal, "Put should have inserted a value")

      val2 = CacheValueClass.new("cval", "dval")
      @x.replace(@tmpKey, val2)
      retVal = @x.get(@tmpKey)
      assert_equal(retVal, val2, "Original value should have been replaced with new one")
    end

    should "Update version value whe being replaced" do
      retVal = @x.getVersioned(@tmpKey)
      puts retVal

      newVal = @tmpVal+"fff"
      @x.replaceWithVersion(@tmpKey, newVal, retVal.version)
      retVal2 = @x.getVersioned(@tmpKey)

      assert_not_equal(retVal.version, retVal2.version, "Version values should differ")
    end

    should "Support getVersioned removal" do
      retVal = @x.getVersioned(@tmpKey)
      puts retVal

      @x.removeWithVersion(@tmpKey, retVal.version)
      retVal2 = @x.getVersioned(@tmpKey)
      assert_nil(retVal2, "Value shouldn't exist in cache")
    end
  end

  context "Cache operations with return values requested" do
    setup do
      @x = RemoteCache.new
      @tmpKey = java.lang.System.currentTimeMillis.to_s
      @tmpVal = java.lang.System.currentTimeMillis.to_s
      @x.put(@tmpKey, @tmpVal)
    end

    should "Return previous value during put" do
      tmpObj = @x.put(@tmpKey, "nom,nom,nom!!", true)
      assert_equal(@tmpVal, tmpObj)
    end

    should "Return previous value during remove" do
      tmpObj = @x.remove(@tmpKey, true)
      assert_equal(@tmpVal, tmpObj)
    end

    should "Return previous value after replace" do
      tmpObj = @x.replace(@tmpKey, "nom,nom,nom!!", true)
      assert_equal(@tmpVal, tmpObj)
    end

    should "putIfAbsent should return previous value if present in the cache" do
      newVal = @tmpVal+"FFF"
      retVal2 = @x.putIfAbsent(@tmpKey, newVal,true)
      assert_equal(@tmpVal, retVal2, "Initial value not returned")
    end

    should "putIfAbsent should return nil value if not present in the cache" do
      newVal = @tmpVal+"FFF"
      retVal2 = @x.putIfAbsent(@tmpKey+"fff", newVal,true)
      assert_nil(retVal2, "Nil should have been returned")
    end

    should "Return previous Versioned value" do
      retVal = @x.getVersioned(@tmpKey)
      retVal2 = @x.removeWithVersion(@tmpKey, retVal.version,true)
      assert_equal(retVal, retVal2, "Returned versioned value should match previous retrieved value")
    end
  end
end