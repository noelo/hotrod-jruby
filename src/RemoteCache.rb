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

  require "src/infinispanError"
  require "src/versioned_value"


  defaultConfig ={
      "infinispan.client.hotrod.request_balancing_strategy" => "org.infinispan.client.hotrod.impl.transport.tcp.RoundRobinBalancingStrategy",
      "infinispan.client.hotrod.server_list" => "127.0.0.1:11311",
      "infinispan.client.hotrod.force_return_values" => "false",
      "infinispan.client.hotrod.tcp_no_delay" => "true",
      "infinispan.client.hotrod.ping_on_startup" => "true",
      "infinispan.client.hotrod.transport_factory" => "org.infinispan.client.hotrod.impl.transport.tcp.TcpTransportFactory",
      "infinispan.client.hotrod.marshaller" => "org.infinispan.marshall.jboss.GenericJBossMarshaller",
      "infinispan.client.hotrod.async_executor_factory" => "org.infinispan.client.hotrod.impl.async.DefaultAsyncExecutorFactory",
      "infinispan.client.hotrod.default_executor_factory.pool_size" => 10,
      "infinispan.client.hotrod.default_executor_factory.queue_size" => 100000,
      "infinispan.client.hotrod.hash_function_impl.1" => "org.infinispan.client.hotrod.impl.consistenthash.ConsistentHashV1",
      "infinispan.client.hotrod.key_size_estimate" => 64,
      "infinispan.client.hotrod.value_size_estimate" => 512
  }


  def initialize(cache_name="", default_config_override={})
    begin
      if default_config_override.empty?
        @rCM = RemoteCacheManager.new
      else
        tmpCFG = java.util.properties.new
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

  def put(key, value, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    @currCache.put(Marshal.dump(key), Marshal.dump(value), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
  end

  def putAll(values={}, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    values.each do |k, v|
      self.put(Marshal.dump(k), Marshal.dump(v), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
    end
  end

  def putIfAbsent(k, v, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    @currCache.putIfAbsent(Marshal.dump(k), Marshal.dump(v), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
  end

  def size()
    @currCache.size
  end

  def version()
    @currCache.version
  end

  def remove(key)
    @currCache.remove(Marshal.dump(key))
  end

  def clear
    @currCache.clear
  end

  def get(key)
    tmpobj = @currCache.get(Marshal.dump(key))
    tmpobj.nil? ? nil : Marshal.load(tmpobj)
  end

  def getVersioned(key)
    tmpobj = @currCache.getVersioned(Marshal.dump(key))
    return VersionedValue.new(tmpobj) unless tmpobj.nil?
  end

  def replace(key, value, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    @currCache.replace(Marshal.dump(key), Marshal.dump(value), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
  end

  def replaceWithVersion(key, value, version, lifespanSeconds=-1, maxIdleTimeSeconds=-1)
    @currCache.replaceWithVersion(Marshal.dump(key), Marshal.dump(value), version, lifespanSeconds, maxIdleTimeSeconds)
  end

  def removeWithVersion(key, version)
    @currCache.removeWithVersion(Marshal.dump(key), version)
  end


end