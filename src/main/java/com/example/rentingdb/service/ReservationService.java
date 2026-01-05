package com.example.rentingdb.service;

import com.example.rentingdb.dao.ReservationDao;
import com.example.rentingdb.dto.ReservationRequest;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ReservationService {

    private final ReservationDao dao;

    @Transactional
    public void reserve(ReservationRequest request) {
        dao.createConfirmedReservation(request);
    }


}
