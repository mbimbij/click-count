package fr.xebia.clickcount;

import io.cucumber.junit.Cucumber;
import io.cucumber.junit.CucumberOptions;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;

import static org.springframework.boot.test.context.SpringBootTest.WebEnvironment.RANDOM_PORT;

@SpringBootTest(webEnvironment = RANDOM_PORT)
@RunWith(Cucumber.class)
@CucumberOptions(
    plugin = {
        "pretty",
        "junit:target/cucumber-reports/apitest/cucumber-apitest-results.xml",
        "usage:target/cucumber-reports/apitest/cucumber-apitest-usage.json"},
    glue = {"fr.xebia.clickcount"},
    features = "src/test/resources/features")
public class ApiTestCucumberRunner {
}
