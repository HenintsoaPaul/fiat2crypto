package com.tsoa.fiattocrypto.authmanager.controller;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;
import java.util.Map;

@RestController()
@RequestMapping("/api/auth")
public class AuthController {

    @GetMapping("my-data")
    public Map<String,String> myData() {
        return Collections.singletonMap("data", "hi, you are authenticated");
    }

    @GetMapping("our-thing")
    public Map<String,String> ourThing() {
        return Collections.singletonMap("data", "idk you");
    }
}
