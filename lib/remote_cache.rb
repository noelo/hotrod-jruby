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

  require "lib/infinispan_error.rb"
  require "lib/versioned_value.rb"


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
        @remote_cache_manager = RemoteCacheManager.new
      else
        tmp_cfg = java.util.Properties.new
        default_config_override.each do |k, v|
          tmp_cfg.setProperty(k, v)
        end
        @remote_cache_manager = RemoteCacheManager.new(tmp_cfg)
      end
      @current_cache = @remote_cache_manager.cache(cache_name)
      y = @current_cache.stats
      return @current_cache
    rescue org.infinispan.client.hotrod.exceptions.HotRodClientException => e
      raise InfinispanError, "Error when retrieving cache #{cache_name} #{e}"
    end
  end

  def started?
    @remote_cache_manager ? @remote_cache_manager.isStarted : false
  end

  def stop
    @remote_cache_manager.stop
  end

  def put(key, value, return_previous=false, lifespan=-1, lifespan_unit=java::util::concurrent::TimeUnit::SECONDS, max_idle_time=-1, max_idle_time_unit=java::util::concurrent::TimeUnit::SECONDS)
    if (return_previous)
      tmpobj = @current_cache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).put(Marshal.dump(key), Marshal.dump(value), lifespan, lifespan_unit, max_idle_time, max_idle_time_unit)
    else
      tmpobj = @current_cache.put(Marshal.dump(key), Marshal.dump(value), lifespan, lifespan_unit, max_idle_time, max_idle_time_unit)
    end
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def put_all(values={}, lifespan=-1, lifespan_unit=java::util::concurrent::TimeUnit::SECONDS, max_idle_time=-1, max_idle_time_unit=java::util::concurrent::TimeUnit::SECONDS)
    values.each do |k, v|
      self.put(Marshal.dump(k), Marshal.dump(v), false, lifespan, lifespan_unit, max_idle_time, max_idle_time_unit)
    end
  end

  def put_if_absent(k, v, return_previous=false, lifespan=-1, lifespan_unit=java::util::concurrent::TimeUnit::SECONDS, max_idle_time=-1, max_idle_time_unit=java::util::concurrent::TimeUnit::SECONDS)
    if (return_previous)
      tmpobj = @current_cache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).putIfAbsent(Marshal.dump(k), Marshal.dump(v), lifespan, lifespan_unit, max_idle_time, max_idle_time_unit)
    else
      tmpobj = @current_cache.putIfAbsent(Marshal.dump(k), Marshal.dump(v), lifespan, lifespan_unit, max_idle_time, max_idle_time_unit)
    end
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def size()
    @current_cache.size
  end

  def name
    @current_cache.getName()
  end

  def version()
    @current_cache.version
  end

  def remove(key, return_previous=false)
    if (return_previous)
      tmpobj = @current_cache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).remove(Marshal.dump(key))
    else
      tmpobj = @current_cache.remove(Marshal.dump(key))
    end
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def clear
    @current_cache.clear
  end

  def get(key)
    tmpobj = @current_cache.get(Marshal.dump(key))
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def get_versioned(key)
    tmpobj = @current_cache.getVersioned(Marshal.dump(key))
    return VersionedValue.new(tmpobj) unless tmpobj.nil?
  end

  def replace(key, value, return_previous=false, lifespan=-1, lifespan_unit=java::util::concurrent::TimeUnit::SECONDS, max_idle_time=-1, max_idle_time_unit=java::util::concurrent::TimeUnit::SECONDS)
    tmpobj = @current_cache.withFlags(org::infinispan::client::hotrod::Flag::FORCE_RETURN_VALUE).replace(Marshal.dump(key), Marshal.dump(value), lifespan, lifespan_unit, max_idle_time, max_idle_time_unit)
    return Marshal.load(tmpobj) unless tmpobj.nil?
  end

  def replace_with_version(key, value, version, return_previous=false, lifespan_seconds=-1, max_idle_time_seconds=-1)
    #TODO - return previous will only work when https://issues.jboss.org/browse/ISPN-1008 is implemented
    @current_cache.replaceWithVersion(Marshal.dump(key), Marshal.dump(value), version, lifespan_seconds, max_idle_time_seconds)
  end

  def remove_with_version(key, version, return_previous=false)
    #TODO - return previous will only work when https://issues.jboss.org/browse/ISPN-1008 is implemented
    tmpobj = @current_cache.removeWithVersion(Marshal.dump(key), version)
  end
end