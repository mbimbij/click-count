package fr.xebia.clickcount;

import fr.xebia.clickcount.pseudohexagon.ICheckDataStoreHealth;
import fr.xebia.clickcount.pseudohexagon.ICountClicks;
import fr.xebia.clickcount.pseudohexagon.IRegisterANewClick;
import fr.xebia.clickcount.repository.RedisClickRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@Slf4j
public class SpringBootConfiguration {
  @Bean
  public RedisClickRepository redisClickRepository(RedisConfiguration redisConfiguration) {
    log.info("redis configuration: {}", redisConfiguration);
    return new RedisClickRepository(redisConfiguration);
  }

  @Bean
  public ICountClicks iCountClicks(RedisClickRepository redisClickRepository) {
    return redisClickRepository;
  }

  @Bean
  public IRegisterANewClick iRegisterANewClick(RedisClickRepository redisClickRepository) {
    return redisClickRepository;
  }

  @Bean
  public ICheckDataStoreHealth iCheckDataStoreHealth(RedisClickRepository redisClickRepository) {
    return redisClickRepository;
  }
}
