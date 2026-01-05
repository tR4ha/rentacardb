package com.example.rentingdb.service;

import com.example.rentingdb.dao.ListingDao;
import com.example.rentingdb.dto.ListingDto;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ListingService {

    private final ListingDao dao;

    public List<ListingDto> getAllListings() {
        return dao.findAll();
    }
}
