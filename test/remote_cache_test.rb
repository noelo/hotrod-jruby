require "test/unit"
require 'rubygems'
require 'shoulda'
require "java"
require "lib/remote_cache"
require "lib/infinispan_error"
require "lib/versioned_value"
require "test/cache_value_class"

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

      @tmp_key = java.lang.System.currentTimeMillis.to_s
      @tmp_val = java.lang.System.currentTimeMillis.to_s
      x.put(@tmp_key, @tmp_val)

      retVal = x.remove(@tmp_key)
      assert_equal(@tmp_val, retVal, "Return value should have been returned")
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
      @tmp_key = java.lang.System.currentTimeMillis.to_s
      @tmp_val = java.lang.System.currentTimeMillis.to_s
    end

    should "Store and retrieve basic values correctly" do
      @x.put(@tmp_key, @tmp_val)
      retVal = @x.get(@tmp_key)
      assert((@tmp_val.eql? retVal), "Retrieved value #{retVal} not the same as the inserted value #{@tmp_val}")
    end

    should "Honor time to live eviction " do
      @x.put(@tmp_key, @tmp_val, false, 5)
      sleep(6)
      assert_nil(@x.get(@tmp_key), "Value was found for key #{@tmp_key}, it should have expired and been evicted")
    end

    should "Handle serialization of complex objects " do
      tmpVal2 = CacheValueClass.new("aval", "bval")
      @x.put(@tmp_key, tmpVal2)
      retVal = @x.get(@tmp_key)
      assert_equal(tmpVal2, retVal, "Retrieved value #{retVal} not the same as the inserted value #{tmpVal2}")
      tmpVal3 = CacheValueClass.new("aval2", "bval2")
      @x.put(@tmp_key, tmpVal3)
      retVal = @x.get(@tmp_key)
      assert_not_equal(tmpVal2, retVal, "Retrieved value #{retVal} should not be the same as the initial inserted value #{tmpVal2}")
    end

    should "putIfAbsent should only insert values if not already present in the cache" do
      @x.put(@tmp_key, @tmp_val)
      retVal = @x.get(@tmp_key)

      newVal = @tmp_val+"FFF"
      @x.put_if_absent(@tmp_key, newVal)
      retVal2 = @x.get(@tmp_key)

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
      @x.put_all(mapIN)
      assert_same(@x.size, 100, "Incorrect cache entry count")
    end
  end

  context "Cache Removal" do
    setup do
      @x = RemoteCache.new
      @tmp_key = java.lang.System.currentTimeMillis.to_s
      @tmp_val = java.lang.System.currentTimeMillis.to_s
      @x.put(@tmp_key, @tmp_val)
    end

    should "Handle removal of inserted objects" do
      tmpVal2 = CacheValueClass.new("aval", "bval")
      @x.put(@tmp_key, tmpVal2)
      assert(!@x.get(@tmp_key).nil?, "Failed to get inserted object")
      @x.remove(@tmp_key)
      assert_nil(@x.get(@tmp_key), "Object present when it should have been removed")
    end


    should "Handle versioned object retrieval" do
      retVal = @x.get_versioned(@tmp_key)
      puts retVal
      assert((@tmp_val.eql? retVal.value), "Retrieved value #{retVal} not the same as the inserted value #{@tmp_val}")
    end

    should "Handle replancement of inserted object" do
      @x.clear
      tmpVal2 = CacheValueClass.new("aval", "bval")
      @x.replace(@tmp_key, tmpVal2)
      retVal = @x.get(@tmp_key)
      assert_nil(retVal, "Replace should not insert a value if not already present")

      @x.put(@tmp_key, tmpVal2)
      retVal = @x.get(@tmp_key)
      assert_not_nil(retVal, "Put should have inserted a value")

      val2 = CacheValueClass.new("cval", "dval")
      @x.replace(@tmp_key, val2)
      retVal = @x.get(@tmp_key)
      assert_equal(retVal, val2, "Original value should have been replaced with new one")
    end

    should "Update version value whe being replaced" do
      retVal = @x.get_versioned(@tmp_key)
      puts retVal

      newVal = @tmp_val+"fff"
      @x.replace_with_version(@tmp_key, newVal, retVal.version)
      retVal2 = @x.get_versioned(@tmp_key)

      assert_not_equal(retVal.version, retVal2.version, "Version values should differ")
    end

    should "Support getVersioned removal" do
      retVal = @x.get_versioned(@tmp_key)
      puts retVal

      @x.remove_with_version(@tmp_key, retVal.version)
      retVal2 = @x.get_versioned(@tmp_key)
      assert_nil(retVal2, "Value shouldn't exist in cache")
    end
  end

  context "Cache operations with return values requested" do
    setup do
      @x = RemoteCache.new
      @tmp_key = java.lang.System.currentTimeMillis.to_s
      @tmp_val = java.lang.System.currentTimeMillis.to_s
      @x.put(@tmp_key, @tmp_val)
    end

    should "Return previous value during put" do
      tmpObj = @x.put(@tmp_key, "nom,nom,nom!!", true)
      assert_equal(@tmp_val, tmpObj)
    end

    should "Return previous value during remove" do
      tmpObj = @x.remove(@tmp_key, true)
      assert_equal(@tmp_val, tmpObj)
    end

    should "Return previous value after replace" do
      tmpObj = @x.replace(@tmp_key, "nom,nom,nom!!", true)
      assert_equal(@tmp_val, tmpObj)
    end

    should "putIfAbsent should return previous value if present in the cache" do
      newVal = @tmp_val+"FFF"
      retVal2 = @x.put_if_absent(@tmp_key, newVal,true)
      assert_equal(@tmp_val, retVal2, "Initial value not returned")
    end

    should "putIfAbsent should return nil value if not present in the cache" do
      newVal = @tmp_val+"FFF"
      retVal2 = @x.put_if_absent(@tmp_key+"fff", newVal,true)
      assert_nil(retVal2, "Nil should have been returned")
    end

#    should "Return previous Versioned value" do
#      retVal = @x.get_versioned(@tmpKey)
#      retVal2 = @x.remove_with_version(@tmpKey, retVal.version,true)
#      assert_equal(retVal, retVal2, "Returned versioned value should match previous retrieved value")
#    end
  end
end