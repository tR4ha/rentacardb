package com.example.rentingdb.controller;

import com.example.rentingdb.dto.ListingDto;
import com.example.rentingdb.service.ListingService;

import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/listings")
@RequiredArgsConstructor
public class ListingController {

    private final ListingService service;

    @GetMapping
    public List<ListingDto> list() {
        return service.getAllListings();
    }
}

