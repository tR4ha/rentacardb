package com.example.rentingdb.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ReservationRequest {
    private Long listingId;
    private Long renterUserId;
    private Long vehicleId;
    private LocalDateTime start;
    private LocalDateTime end;
}
