package com.example.rentingdb.controller;

import com.example.rentingdb.dto.ReservationRequest;
import com.example.rentingdb.service.ReservationService;

import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reservations")
@RequiredArgsConstructor
public class ReservationController {

    private final ReservationService service;



    @PostMapping
    public ResponseEntity<?> reserve(@RequestBody ReservationRequest request) {
        service.reserve(request);
        return ResponseEntity.ok("Reservation created");
    }
}
