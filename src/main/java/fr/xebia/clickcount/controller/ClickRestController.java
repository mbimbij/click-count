package fr.xebia.clickcount.controller;

import fr.xebia.clickcount.pseudohexagon.ICheckDataStoreHealth;
import fr.xebia.clickcount.pseudohexagon.ICountClicks;
import fr.xebia.clickcount.pseudohexagon.IRegisterANewClick;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ClickRestController {

  @Autowired
  private ICheckDataStoreHealth iCheckDataStoreHealth;
  @Autowired
  private ICountClicks iCountClicks;
  @Autowired
  private IRegisterANewClick iRegisterANewClick;

  @GetMapping("click")
  public long getCount() {
    return iCountClicks.countClicks();
  }

  @PostMapping("click")
  public long incrementCount() {
    return iRegisterANewClick.registerANewClick();
  }

  @GetMapping("healthcheck")
  public String healthcheck() {
    String result = iCheckDataStoreHealth.checkDataStoreHealth();
    if ("PONG".equals(result)) {
      return "ok 2";
    }
    return "ko : " + result;
  }

}
