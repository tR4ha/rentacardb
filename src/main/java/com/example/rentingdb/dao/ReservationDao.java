package com.example.rentingdb.dao;

import com.example.rentingdb.dto.ReservationRequest;

import lombok.RequiredArgsConstructor;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class ReservationDao {

    private final JdbcTemplate jdbc;

    public void createConfirmedReservation(ReservationRequest r) {
        jdbc.update("""
            INSERT INTO reservation
            (listing_id, renter_user_id, start_datetime, end_datetime, status, assigned_vehicle_id)
            VALUES (?, ?, ?, ?, 'CONFIRMED', ?)
        """, r.getListingId(), r.getRenterUserId(),
                r.getStart(), r.getEnd(), r.getVehicleId());
    }


}
