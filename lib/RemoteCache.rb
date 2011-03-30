class RemoteCache

  require 'java'

  # Find the Infinispan using java system properties i.e. -J-DInfinispanHome=/home/dev/infinispan-4.2.1.CR4/
  infinispan_path = java::lang::System.getProperty("InfinispanHome")

  $CLASSPATH << "#{infinispan_path}/modules/hotrod-client/infinispan-client-hotrod.jar"
  $CLASSPATH << "#{infinispan_path}/modules/hotrod-client/lib/commons-pool-1.5.4.jar"
  $CLASSPATH << "#{infinispan_path}/lib/marshalling-api-1.2.3.GA.jar"
  $CLASSPATH << "#{infinispan_path}/lib/river-1.2.3.GA.jar"
  $CLASSPATH << "#{infinispan_path}/lib/jgroups-2.11.0.GA.jar"
  $CLASSPATH << "#{infinispan_path}/lib/jboss-transaction-api-1.0.1.GA.jar"
  $CLASSPATH << "#{infinispan_path}/lib/river-1.2.3.GA.jar"
  $CLASSPATH << "#{infinispan_path}/infinispan-core.jar"


  java_import 'org.infinispan.client.hotrod.RemoteCacheManager'

  require "lib/infinispanError"
  require "lib/versioned_value"


#  defaultConfig ={
#      "infinispan.client.hotrod.request_balancing_strategy" => "org.infinispan.client.hotrod.impl.transport.tcp.RoundRobinBalancingStrategy",
#      "infinispan.client.hotrod.server_list" => "127.0.0.1:11311",
#      "infinispan.client.hotrod.force_return_values" => "false",
#      "infinispan.client.hotrod.tcp_no_delay" => "true",
#      "infinispan.client.hotrod.ping_on_startup" => "true",
#      "infinispan.client.hotrod.transport_factory" => "org.infinispan.client.hotrod.impl.transport.tcp.TcpTransportFactory",
#      "infinispan.client.hotrod.marshaller" => "org.infinispan.marshall.jboss.GenericJBossMarshaller",
#      "infinispan.client.hotrod.async_executor_factory" => "org.infinispan.client.hotrod.impl.async.DefaultAsyncExecutorFactory",
#      "infinispan.client.hotrod.default_executor_factory.pool_size" => 10,
#      "infinispan.client.hotrod.default_executor_factory.queue_size" => 100000,
#      "infinispan.client.hotrod.hash_function_impl.1" => "org.infinispan.client.hotrod.impl.consistenthash.ConsistentHashV1",
#      "infinispan.client.hotrod.key_size_estimate" => 64,
#      "infinispan.client.hotrod.value_size_estimate" => 512
#  }


  def initialize(cache_name="", default_config_override={})
    begin
      if default_config_override.empty?
        @rCM = RemoteCacheManager.new
      else
        tmpCFG = java.util.Properties.new
        default_config_override.each do |k, v|
          tmpCFG.setProperty(k, v)
        end
        @rCM = RemoteCacheManager.new(tmpCFG)
      end
      @currCache = @rCM.cache(cache_name)
      y = @currCache.stats
      return @currCache
    rescue org.infinispan.client.hotrod.exceptions.HotRodClientException => e
      raise InfinispanError, "Error when retrieving cache #{cache_name} #{e}"
    end
  end

  def started?
    @rCM ? @rCM.isStarted : false
  end

  def stop
    @rCM.stop
  end

  def put(key, value, return_previous=false, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    if (return_previous)
      tmpobj = @currCache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).put(Marshal.dump(key), Marshal.dump(value), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
    else
      tmpobj = @currCache.put(Marshal.dump(key), Marshal.dump(value), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
    end
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def putAll(values={}, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    values.each do |k, v|
      self.put(Marshal.dump(k), Marshal.dump(v), false, lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
    end
  end

  def putIfAbsent(k, v, return_previous=false, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    if (return_previous)
      tmpobj = @currCache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).putIfAbsent(Marshal.dump(k), Marshal.dump(v), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
    else
      tmpobj = @currCache.putIfAbsent(Marshal.dump(k), Marshal.dump(v), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
    end
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def size()
    @currCache.size
  end

  def name
    @currCache.getName()
  end

  def version()
    @currCache.version
  end

  def remove(key, return_previous=false)
    if (return_previous)
      tmpobj = @currCache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).remove(Marshal.dump(key))
    else
      tmpobj = @currCache.remove(Marshal.dump(key))
    end
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def clear
    @currCache.clear
  end

  def get(key)
    tmpobj = @currCache.get(Marshal.dump(key))
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def getVersioned(key)
    tmpobj = @currCache.getVersioned(Marshal.dump(key))
    return VersionedValue.new(tmpobj) unless tmpobj.nil?
  end

  def replace(key, value, return_previous=false, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    tmpobj = @currCache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).replace(Marshal.dump(key), Marshal.dump(value), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def replaceWithVersion(key, value, version, return_previous=false, lifespanSeconds=-1, maxIdleTimeSeconds=-1)
    #TODO - return previous will only work when https://issues.jboss.org/browse/ISPN-1008 is implemented
    @currCache.replaceWithVersion(Marshal.dump(key), Marshal.dump(value), version, lifespanSeconds, maxIdleTimeSeconds)
  end

  def removeWithVersion(key, version, return_previous=false)
    #TODO - return previous will only work when https://issues.jboss.org/browse/ISPN-1008 is implemented
    tmpobj = @currCache.removeWithVersion(Marshal.dump(key), version)
  end
end