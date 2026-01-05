package com.example.rentingdb.controller;

import com.example.rentingdb.dto.SellerCompanyDto;
import com.example.rentingdb.service.SellerCompanyService;

import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/companies")
@RequiredArgsConstructor
public class SellerCompanyController {

    private final SellerCompanyService service;

    @GetMapping
    public List<SellerCompanyDto> list() {
        return service.getAll();
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody SellerCompanyDto dto) {
        service.create(dto);
        return ResponseEntity.ok("Company created");
    }
}
