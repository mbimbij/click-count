package fr.xebia.clickcount;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@Slf4j
public class ApiTestCucumberStepDefinitions {

  private ResponseEntity<String> responseEntity;

  @When("we call the REST endpoint {string}")
  public void weCallTheRESTEndpoint(String endpoint) {
    String restEndpointUrl = buildEndpointBaseUrl() + endpoint;
    log.info("calling url: \"{}\"", restEndpointUrl);
    responseEntity = new RestTemplate().getForEntity(restEndpointUrl, String.class);
  }

  private String buildEndpointBaseUrl() {
    String restEndpointHostname = System.getenv("REST_ENDPOINT_HOSTNAME");
    String restEndpointProtocol = System.getenv("REST_ENDPOINT_PROTOCOL");
    String restEndpointPort = System.getenv("REST_ENDPOINT_PORT");
    return restEndpointProtocol + "://" + restEndpointHostname + ":" + restEndpointPort;
  }

  @Then("the REST response is as following:")
  public void theRESTResponseIsAsFollowing(Map<String, String> expectedValues) {
    int expectedHttpStatus = Integer.parseInt(expectedValues.get("httpStatus"));
    String expectedBody = expectedValues.get("body");
    assertThat(responseEntity.getStatusCodeValue()).isEqualTo(expectedHttpStatus);
    assertThat(responseEntity.getBody()).isEqualTo(expectedBody);
  }
}
