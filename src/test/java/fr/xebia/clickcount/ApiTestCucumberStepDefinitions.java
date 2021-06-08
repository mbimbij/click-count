package fr.xebia.clickcount;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.Objects;

import static org.assertj.core.api.Assertions.assertThat;

@Slf4j
public class ApiTestCucumberStepDefinitions {


  public static class HealthcheckTest {

    private ResponseEntity<String> responseEntity;

    @When("we call the REST endpoint {string}")
    public void weCallTheRESTEndpoint(String endpoint) {
      String restEndpointUrl = buildEndpointBaseUrl() + endpoint;
      log.info("calling url: \"{}\"", restEndpointUrl);
      responseEntity = new RestTemplate().getForEntity(restEndpointUrl, String.class);
    }

    @Then("the REST response is as following:")
    public void theRESTResponseIsAsFollowing(Map<String, String> expectedValues) {
      int expectedHttpStatus = Integer.parseInt(expectedValues.get("httpStatus"));
      String expectedBody = expectedValues.get("body");
      assertThat(responseEntity.getStatusCodeValue()).isEqualTo(expectedHttpStatus);
      assertThat(responseEntity.getBody()).isEqualTo(expectedBody);
    }

  }

  public static class IncrementClickTest {
    private int initialClickCount;
    private ResponseEntity<Integer> incrementClicksResponseEntity;

    @Given("initial click count")
    public void initialClickCount() {
      String restEndpointUrl = buildEndpointBaseUrl() + "/click";
      log.info("calling url: \"{}\"", restEndpointUrl);
      initialClickCount = Objects.requireNonNull(new RestTemplate().getForObject(restEndpointUrl, Integer.class));
    }

    @When("we send a POST request to the REST endpoint {string}")
    public void weSendAPOSTRequestToTheRESTEndpoint(String arg0) {
      String restEndpointUrl = buildEndpointBaseUrl() + "/click";
      log.info("calling url: \"{}\"", restEndpointUrl);
      incrementClicksResponseEntity = new RestTemplate().postForEntity(restEndpointUrl, null, Integer.class);
    }

    @Then("the REST response is equal to the initial count + 1")
    public void theRESTResponseIsEqualToTheInitialCount() {
      assertThat(incrementClicksResponseEntity.getStatusCodeValue()).isEqualTo(200);
      assertThat(incrementClicksResponseEntity.getBody()).isEqualTo(initialClickCount + 1);
    }

  }

  private static String buildEndpointBaseUrl() {
    String restEndpointHostname = System.getenv("REST_ENDPOINT_HOSTNAME");
    String restEndpointProtocol = System.getenv("REST_ENDPOINT_PROTOCOL");
    String restEndpointPort = System.getenv("REST_ENDPOINT_PORT");
    return restEndpointProtocol + "://" + restEndpointHostname + ":" + restEndpointPort;
  }
}
