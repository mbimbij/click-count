package fr.xebia.clickcount.repository;

import fr.xebia.clickcount.RedisConfiguration;
import fr.xebia.clickcount.hexagon.ICheckDataStoreHealth;
import fr.xebia.clickcount.hexagon.ICountClicks;
import fr.xebia.clickcount.hexagon.IRegisterANewClick;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioSocketChannel;
import lombok.extern.slf4j.Slf4j;
import org.redisson.Config;
import org.redisson.Redisson;
import org.redisson.client.RedisClient;
import org.redisson.client.RedisConnection;
import org.redisson.client.RedisConnectionException;
import org.redisson.client.protocol.RedisCommands;

@Slf4j
public class RedisClickRepository implements ICountClicks, IRegisterANewClick, ICheckDataStoreHealth {

  private final Redisson redisson;

  private final RedisClient redisClient;

  public RedisClickRepository(RedisConfiguration configuration) {
    Config config = new Config();
    String redisHost = configuration.getHost();
    int redisPort = configuration.getPort();
    int redisConnectionTimeoutMs = configuration.getConnectionTimeout();

    config.useSingleServer().setAddress(String.format("%s:%d", redisHost, redisPort));
    redisson = Redisson.create(config);
    redisClient = new RedisClient(new NioEventLoopGroup(), NioSocketChannel.class, redisHost, redisPort, redisConnectionTimeoutMs);
  }

  @Override
  public String checkDataStoreHealth() {
    RedisConnection conn = null;
    try {
      conn = redisClient.connect();
      return conn.sync(RedisCommands.PING);

    } catch (RedisConnectionException e) {
      return e.getCause().getMessage();
    } finally {
      if (conn != null) {
        conn.closeAsync();
      }
    }
  }

  @Override
  public long countClicks() {
    log.info(">> getCount");
    return redisson.getAtomicLong("count").get();
  }

  @Override
  public long registerANewClick() {
    log.info(">> incrementAndGet");
    return redisson.getAtomicLong("count").incrementAndGet();
  }

}
