class InfinispanWrapper

  require 'java'

  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/modules/hotrod-client/infinispan-client-hotrod.jar'
  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/modules/hotrod-client/lib/commons-pool-1.5.4.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/modules/hotrod/infinispan-server-hotrod.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/modules/hotrod/lib/getopt-1.0.13.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/modules/hotrod/lib/infinispan-server-core-4.2.1.CR4.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/modules/hotrod/lib/netty-3.2.3.Final.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/modules/hotrod/lib/scala-library-2.8.1.jar'
  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/marshalling-api-1.2.3.GA.jar'
  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/river-1.2.3.GA.jar'
  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/jgroups-2.11.0.GA.jar'
  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/jboss-transaction-api-1.0.1.GA.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/jcip-annotations-1.0.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/log4j-1.2.16.jar'
  #$CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/rhq-pluginAnnotations-3.0.1.jar'
  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/lib/river-1.2.3.GA.jar'
  $CLASSPATH << '/home/noelo/dev/infinispan-4.2.1.CR4/infinispan-core.jar'

  java_import 'org.infinispan.client.hotrod.RemoteCacheManager'

  require "src/infinispanError"
  attr_reader :rCM


  def initialize
    #@rCM = nil
    @currCache = nil
    @rCM = RemoteCacheManager.new('localhost', 11222)
  end

  def started?
    @rCM ? @rCM.isStarted : false
  end

  def cache(cache_name="", forced_return=false)
    begin
      @currCache = @rCM.cache(cache_name)
      y = @currCache.stats
    rescue org.infinispan.client.hotrod.exceptions.HotRodClientException => e
      raise InfinispanError, "Error when retrieving cache #{cache_name} #{e}"
    end
  end

  def start
    @rCM.start
  end

  def stop
    @rCM.stop
  end

  def put(key, value, lifespan=-1, lifeSpanUnit=java::util::concurrent::TimeUnit::SECONDS, maxIdleTime=-1, maxIdleTimeUnit=java::util::concurrent::TimeUnit::SECONDS)
    @currCache.put(Marshal.dump(key), Marshal.dump(value), lifespan, lifeSpanUnit, maxIdleTime, maxIdleTimeUnit)
  end

  def get(key)
    tmpobj = @currCache.get(Marshal.dump(key))
    tmpobj.nil? ? nil : Marshal.load(tmpobj)
  end

  def containsValue?(value)
    @currCache.containsValue(Marshal.dump(value)).nil? ? false : true
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


end