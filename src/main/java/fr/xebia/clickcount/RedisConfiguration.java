package fr.xebia.clickcount;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "redis")
public class RedisConfiguration {
  private String host;
  private int port;
  private int connectionTimeout;
}
