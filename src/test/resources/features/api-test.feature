Feature: API test

  Scenario: healthcheck is ok
    When we call the REST endpoint "/healthcheck"
    Then the REST response is as following:
      | httpStatus | 200 |
      | body       | ok  |

  Scenario: increment click
    Given initial click count
    When we send a POST request to the REST endpoint "/click"
    Then the REST response is equal to the initial count + 1