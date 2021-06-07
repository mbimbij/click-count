package fr.xebia.clickcount;

import org.assertj.core.api.SoftAssertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.redisson.Config;
import org.redisson.Redisson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.util.TestPropertyValues;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ContextConfiguration;
import org.testcontainers.containers.DockerComposeContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.File;

@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ContextConfiguration(
    classes = {SpringBootApplicationRunner.class, SpringBootApplicationIT.TestSpringConfiguration.class},
    initializers = SpringBootApplicationIT.Initializer.class)
class SpringBootApplicationIT {
  private static final int REDIS_PORT = 6379;
  @Container
  private static final DockerComposeContainer<?> dockerComposeContainer =
      new DockerComposeContainer<>(new File("src/test/resources/docker-compose.yml"))
          .withExposedService("redis_1", REDIS_PORT)
          .waitingFor("redis_1", Wait.forListeningPort());

  @Autowired
  private TestRestTemplate restTemplate;
  @Autowired
  private IFlushRedis iFlushRedis;

  @BeforeEach
  void setUp() {
    iFlushRedis.flushAll();
  }

  @Test
  void givenNoClick_whenCountClicks_ThenCountEquals0() {
    // WHEN
    ResponseEntity<String> responseEntity = restTemplate.getForEntity("/click", String.class);

    // THEN
    SoftAssertions.assertSoftly(softAssertions -> {
      softAssertions.assertThat(responseEntity.getStatusCodeValue()).isEqualTo(200);
      softAssertions.assertThat(responseEntity.getBody()).isEqualTo("0");
    });
  }

  @Test
  void givenOneClick_whenCountClicks_ThenCountEquals1() {
    // WHEN
    restTemplate.postForEntity("/click", null, String.class);
    ResponseEntity<String> responseEntity = restTemplate.getForEntity("/click", String.class);

    // THEN
    SoftAssertions.assertSoftly(softAssertions -> {
      softAssertions.assertThat(responseEntity.getStatusCodeValue()).isEqualTo(200);
      softAssertions.assertThat(responseEntity.getBody()).isEqualTo("1");
    });
  }

  static class Initializer
      implements ApplicationContextInitializer<ConfigurableApplicationContext> {
    public void initialize(ConfigurableApplicationContext configurableApplicationContext) {
      int redisPort = dockerComposeContainer.getServicePort("redis_1", REDIS_PORT);
      TestPropertyValues.of(
          String.format("redis.port=%d", redisPort)
      ).applyTo(configurableApplicationContext.getEnvironment());
    }
  }

  @Configuration
  public static class TestSpringConfiguration {
    @Bean
    public IFlushRedis iFlushRedis(RedisConfiguration configuration) {
      Config config = new Config();
      config.useSingleServer().setAddress(String.format("%s:%d", configuration.getHost(), configuration.getPort()));
      Redisson redisson = Redisson.create(config);
      return () -> redisson.getAtomicLong("count").set(0);
    }
  }
}